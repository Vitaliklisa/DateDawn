import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/notifications.dart';
import 'event_repository.dart';

/// Everything Date Dawn keeps outside the countdown data itself: the in-app
/// notification inbox, the syncable theme preference, and avatar uploads.
///
/// **Why this is separate from `EventRepository`.** The repository owns the
/// shared object graph — countdowns, circles, invitations — where the rules are
/// about membership. This class owns per-user data that only its owner ever
/// sees, which is a much simpler shape: every read and write is scoped to
/// `users/{uid}` or `avatars/{uid}`, and the security rules say exactly that.
///
/// **The inbox is a subcollection, not a collection.** Storing notifications at
/// `users/{uid}/notifications/{id}` means the path itself carries the owner, so
/// a security rule needs no field to compare against and a query cannot
/// accidentally span users. It also keeps one user's inbox out of the way of
/// every other collection scan.
class NotificationService {
  NotificationService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _inbox(String userId) =>
      _db.collection('users').doc(userId).collection('notifications');

  // ---------------------------------------------------------------------------
  // notifications — the realtime inbox
  // ---------------------------------------------------------------------------

  /// A live stream of a user's inbox, newest first.
  ///
  /// A plain `snapshots()` listener, so a notification written by someone else
  /// appears without a refresh — which is the whole point of an inbox that both
  /// partners look at.
  Stream<List<AppNotification>> watchNotifications(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _inbox(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotification.fromDoc(doc.id, userId, doc.data()))
            .toList());
  }

  /// Writes one notification into someone's inbox.
  ///
  /// Best-effort by design: the caller has already committed the action this
  /// describes, so a failure here must not turn a completed share into an error.
  Future<void> sendNotification({
    required String userId,
    required String title,
    String body = '',
    NotificationKind type = NotificationKind.system,
  }) async {
    if (userId.isEmpty || title.isEmpty) return;
    try {
      await _inbox(userId).add({
        'title': title,
        'body': body,
        'type': type.name,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('[datedawn] Could not write a notification: $error');
    }
  }

  /// Marks one notification read. Idempotent.
  Future<void> markNotificationRead(String userId, String id) async {
    if (userId.isEmpty || id.isEmpty) return;
    await _inbox(userId).doc(id).update({'read': true});
  }

  /// Marks every unread notification for a user read.
  ///
  /// Batched, because a user with a long inbox would otherwise issue one write
  /// per row — and Firestore bills each of them.
  Future<void> markAllNotificationsRead(String userId) async {
    if (userId.isEmpty) return;
    final unread = await _inbox(userId).where('read', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String userId, String id) async {
    if (userId.isEmpty || id.isEmpty) return;
    await _inbox(userId).doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // user_settings — appearance
  // ---------------------------------------------------------------------------

  /// Reads the stored theme for a user, or `null` if they never set one.
  ///
  /// Returning `null` rather than a default matters: it is what lets the caller
  /// tell "no preference on record" apart from "chose system", so a device-local
  /// choice is not silently overwritten on first launch.
  Future<String?> fetchThemeMode(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final value = doc.data()?['themeMode'];
      return value is String ? value : null;
    } catch (error) {
      // Offline, or the doc does not exist yet. Appearance is a convenience;
      // never let it block the app from starting.
      debugPrint('[datedawn] Could not read the theme preference: $error');
      return null;
    }
  }

  /// Saves the theme for a user, creating the doc on first write.
  Future<void> saveThemeMode(String userId, String wireMode) async {
    if (userId.isEmpty) return;
    await _db.collection('users').doc(userId).set(
      {'themeMode': wireMode},
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // profiles + storage — avatars
  // ---------------------------------------------------------------------------

  /// Uploads an avatar and returns its public download URL.
  ///
  /// The object path is `avatars/{uid}/{timestamp}-{filename}`. The leading uid
  /// is what the storage rules match on, so a user can only ever write inside
  /// their own folder; the timestamp keeps a replacement from being served from
  /// cache under the same URL.
  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileExtension,
  }) async {
    if (userId.isEmpty) {
      throw const DataFailure('Sign in before changing your picture.');
    }

    final extension = fileExtension.replaceAll('.', '').toLowerCase();
    final path =
        'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final ref = _storage.ref(path);
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: _contentTypeFor(extension)),
    );
    final url = await ref.getDownloadURL();

    // Keep the profile in step so other people see the new picture.
    await _db
        .collection('users')
        .doc(userId)
        .set({'photoUrl': url}, SetOptions(merge: true));

    return url;
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
}
