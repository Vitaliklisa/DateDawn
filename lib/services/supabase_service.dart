import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/notifications.dart';
import 'event_repository.dart';

/// Everything Date Dawn reads and writes in Supabase.
///
/// **Firebase identity, Supabase data.** Firebase Authentication is the only
/// identity provider: it signs the user in and issues a JWT. Supabase verifies
/// that JWT (registered under Authentication -> Third-Party Auth) and exposes
/// the Firebase uid as `auth.uid()`, so the RLS policies in `supabase/schema.sql`
/// can scope every row to its owner without a mapping table.
///
/// **The bridge is the token, not a header.** The client is given an
/// `accessToken` callback that returns the current Firebase ID token; Supabase
/// attaches it to every request. An earlier version shipped the uid in an
/// `x-user-id` header instead, which was a dev convenience rather than a
/// security boundary — any caller could claim any uid. The token is verified
/// cryptography, so the uid in `auth.uid()` cannot be forged.
///
/// **The `role` claim matters.** Firebase JWTs carry no `role` claim by
/// default, and without it Supabase assigns the `anon` Postgres role — which no
/// policy grants to. A blocking Firebase Auth function stamps
/// `role: 'authenticated'` on every token (see `firebase/functions`), and the
/// sign-in flow force-refreshes the token so the claim is present before the
/// first Supabase request.
class SupabaseService {
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// True once `Supabase.initialize` has completed. Guarding on this keeps the
  /// app usable (Firebase-only) if Supabase is unreachable or misconfigured,
  /// rather than crashing on first use.
  static bool get isAvailable {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Marks the client ready. Called by `main()` once `Supabase.initialize`
  /// resolves, so an early call (before init finishes) is skipped rather than
  /// throwing on a half-built client.
  static bool _ready = false;
  static void markReady() => _ready = true;

  /// True only when the client is both present and fully initialised.
  ///
  /// Prefer this over [isAvailable] on the write paths: with the background
  /// initialisation in `main()`, the instance can exist a moment before it is
  /// usable, and a write attempted in that window would throw.
  static bool get isReady => _ready && isAvailable;

  SupabaseClient get client => _client;

  /// Clears any auth state held by the client.
  ///
  /// The client no longer carries a uid of its own: identity travels in the
  /// Firebase ID token handed to Supabase on every request via the
  /// `accessToken` callback in `main()`. This is kept as an explicit hook so a
  /// sign-out can immediately drop any cached token rather than waiting for
  /// the client to re-read Firebase Auth.
  void clearAuth() {
    try {
      _client.auth.signOut();
    } catch (error) {
      debugPrint('[datedawn] Could not clear Supabase auth state: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // user_settings — appearance
  // ---------------------------------------------------------------------------

  /// Reads the stored theme for a user, or `null` if they have never set.
  ///
  /// Returning `null` rather than a default matters: it lets the caller
  /// distinguish "this user has no preference on record" from "this user
  /// chose system", so a device-local choice is not silently overwritten by a
  /// server default on first launch.
  Future<ThemeMode?> fetchThemeMode(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final row = await _client
          .from('user_settings')
          .select('theme_mode')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return themeModeFromWire(row['theme_mode']);
    } catch (error) {
      // Offline, or the table does not exist yet. Appearance is a convenience;
      // never let it block the app from starting.
      debugPrint(
        '[datedawn] Could not read the Supabase theme preference: '
        '${_describe(error)}',
      );
      return null;
    }
  }

  /// Saves the theme for a user, creating the row on first write.
  ///
  /// Upsert rather than update: the row may not exist yet on a brand-new
  /// account, and "set my preference" should not depend on whether a bootstrap
  /// trigger happened to run.
  Future<void> saveThemeMode(String userId, ThemeMode mode) async {
    if (userId.isEmpty) return;
    await _client.from('user_settings').upsert(
      {
        'user_id': userId,
        'theme_mode': themeModeToWire(mode),
      },
      onConflict: 'user_id',
    );
  }

  // ---------------------------------------------------------------------------
  // notifications — the realtime inbox
  // ---------------------------------------------------------------------------

  /// The most recent notifications for a user, newest first.
  Future<List<AppNotification>> fetchNotifications(
    String userId, {
    int limit = 50,
  }) async {
    if (userId.isEmpty) return const [];
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(AppNotification.fromRow).toList();
    } catch (e) {
      throw DataFailure(_describe(e));
    }
  }

  /// A live stream of a user's notifications.
  ///
  /// Two sources are merged, because Supabase Realtime has a gap that would
  /// otherwise show as "notifications never load until you get a new one":
  ///
  ///  1. The initial `select`, which gives the backlog.
  ///  2. The realtime subscription, which gives everything after that.
  ///
  /// The stream is a broadcast controller rather than a plain `.map`, so the
  /// subscription is created once and shared by every listener, and so the
  /// caller can cancel cleanly.
  Stream<List<AppNotification>> watchNotifications(String userId) {
    if (userId.isEmpty) return Stream.value(const []);

    final controller = StreamController<List<AppNotification>>.broadcast();
    final byId = <String, AppNotification>{};

    void emit() {
      final items = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) controller.add(items);
    }

    // Backlog first, so the list is populated immediately.
    fetchNotifications(userId).then((items) {
      for (final item in items) {
        byId[item.id] = item;
      }
      emit();
    }).catchError((Object e) {
      if (!controller.isClosed) controller.addError(e);
    });

    // Then live inserts. The filter is applied client-side as well as in the
    // query: with the dev policies active Postgres does not filter the
    // broadcast, so another user's insert would otherwise reach this client.
    final channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final record = payload.newRecord;
            if (record['user_id'] != userId) return;
            final item = AppNotification.fromRow(record);
            byId[item.id] = item;
            emit();
          },
        )
        // Updates matter too: "marked read on another device" should show up.
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final record = payload.newRecord;
            if (record['user_id'] != userId) return;
            final item = AppNotification.fromRow(record);
            byId[item.id] = item;
            emit();
          },
        )
        // Deletes arrive with only the primary key unless replica identity is
        // full; the id is all that is needed to drop it from the list.
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final id = payload.oldRecord['id'];
            if (id == null || payload.oldRecord['user_id'] != userId) return;
            byId.remove(id.toString());
            emit();
          },
        )
        .subscribe();

    controller.onCancel = () async {
      // Unsubscribing is what stops the socket listener leaking when the
      // screen is disposed. Without it, the channel stays open for the life
      // of the process and every rebuild adds another.
      await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  /// Marks one notification read. Idempotent.
  Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  /// Marks every unread notification for a user read, in one statement.
  Future<void> markAllNotificationsRead(String userId) async {
    if (userId.isEmpty) return;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  /// Writes a notification for someone.
  ///
  /// This is how one user tells another something happened — "your friend
  /// joined your circle". The recipient's client receives it over Realtime.
  ///
  /// A failure is swallowed: notifications ride on top of a Firestore write
  /// that has already succeeded, so a missing table or an offline device must
  /// never turn a completed action into an error.
  Future<void> sendNotification({
    required String userId,
    required String title,
    String body = '',
    NotificationKind type = NotificationKind.system,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.name,
      });
    } catch (error) {
      debugPrint(
        '[datedawn] Could not write a Supabase notification: '
        '${_describe(error)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // profiles + storage — avatars
  // ---------------------------------------------------------------------------

  /// Creates or updates the caller's profile row.
  ///
  /// Called on sign-in so a Supabase-only feature can resolve a uid to a name
  /// and avatar without reading Firestore.
  Future<void> upsertProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    if (userId.isEmpty) return;
    await _client.from('profiles').upsert(
      {
        'id': userId,
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
      onConflict: 'id',
    );
  }

  /// Uploads an avatar and returns its public URL.
  ///
  /// The object path is `{userId}/{timestamp}-{filename}`. The leading uid is
  /// what the storage policies match on, so a user can only ever write inside
  /// their own folder — the timestamp keeps a replacement from being cached
  /// under the same URL.
  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileExtension,
  }) async {
    if (userId.isEmpty) {
      throw const DataFailure('Sign in before changing your picture.');
    }

    final extension = fileExtension.replaceAll('.', '').toLowerCase();
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFor(extension),
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

    // Keep the profile row in step, so other people see the new picture.
    await upsertProfile(userId: userId, avatarUrl: publicUrl);

    return publicUrl;
  }

  static String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  /// Turns a Supabase/PostgREST error into a sentence worth showing a user.
  static String _describe(Object error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '42P01':
          return 'The Supabase tables are missing. Run supabase/schema.sql.';
        case '42501':
          return 'Supabase refused that request. Check the RLS policies.';
        case '23505':
          return 'That already exists.';
        default:
          return error.message;
      }
    }
    if (error is StorageException) return error.message;
    return 'Could not reach Supabase. Check your connection.';
  }
}
