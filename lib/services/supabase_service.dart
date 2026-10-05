import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/notifications.dart';
import 'event_repository.dart';

/// Everything Date Dawn reads and writes in Supabase.
///
/// **Why this exists alongside Firebase.** The app's identity and its
/// countdown data live in Firebase. Supabase owns three things Firebase does
/// not do as well for this app: appearance that follows a user across
/// devices, a realtime notification inbox, and file storage for avatars.
/// Keeping the two apart means the working Firestore code is untouched.
///
/// **The identity bridge.** Firebase issues the uid; Supabase has its own
/// `auth.uid()`. Because the app never signs into Supabase, `auth.uid()` is
/// NULL on every request, so Postgres cannot tell who is calling. Every
/// request therefore carries the Firebase uid in an `x-user-id` header, and
/// the dev policies in `supabase/schema.sql` scope rows by it.
///
/// That is a development convenience, not a security boundary — see the
/// header comment in the schema for what to do before production. Nothing
/// sensitive should be stored here until then.
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

  SupabaseClient get client => _client;

  /// Sets the uid every subsequent Supabase request is tagged with.
  ///
  /// Called on sign-in and cleared on sign-out. This is what the dev RLS
  /// policies read; without it, every request is anonymous and denied.
  void setCurrentUserId(String? userId) {
    if (userId == null || userId.isEmpty) {
      _client.headers.remove('x-user-id');
    } else {
      _client.headers['x-user-id'] = userId;
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
  Future<void> sendNotification({
    required String userId,
    required String title,
    String body = '',
    NotificationKind type = NotificationKind.system,
  }) async {
    if (userId.isEmpty) return;
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
    });
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
