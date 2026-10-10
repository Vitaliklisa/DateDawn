import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/notifications.dart';

/// Everything Date Dawn keeps outside the countdown data itself: the in-app
/// notification inbox and the syncable theme preference.
///
/// **Why this is separate from `EventRepository`.** The repository owns the
/// shared object graph — countdowns, circles, invitations — where the rules are
/// about membership. This class owns per-user data that only its owner ever
/// sees, which is a much simpler shape: every read and write is scoped to
/// `users/{uid}`, and the security rules say exactly that.
///
/// **The inbox is a subcollection, not a collection.** Storing notifications at
/// `users/{uid}/notifications/{id}` means the path itself carries the owner, so
/// a security rule needs no field to compare against and a query cannot
/// accidentally span users. It also keeps one user's inbox out of the way of
/// every other collection scan.
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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

  /// Reads the stored clock format (`'12h'`/`'24h'`), or `null` if unset.
  ///
  /// `null` rather than a default, for the same reason [fetchThemeMode]
  /// returns one: it lets the caller distinguish "never chose" from "chose
  /// 12-hour", which is what decides whether the device default should win.
  Future<String?> fetchTimeFormat(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final value = doc.data()?['timeFormat'];
      return value is String ? value : null;
    } catch (error) {
      // Formatting is a preference; a read failure must never block startup.
      debugPrint('[datedawn] Could not read the time format: $error');
      return null;
    }
  }

  /// Saves the clock format for a user, creating the doc on first write.
  Future<void> saveTimeFormat(String userId, String wireFormat) async {
    if (userId.isEmpty) return;
    await _db.collection('users').doc(userId).set(
      {'timeFormat': wireFormat},
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // profiles
  // ---------------------------------------------------------------------------
  //
  // There is deliberately nothing here for profile pictures. Cloud Storage now
  // requires the Blaze plan, so Date Dawn ships without uploaded avatars and
  // every identity surface renders initials instead (see `UserAvatar`). Nothing
  // writes a `photoUrl`; the model fields that still read one exist only to
  // carry a Google account picture straight from Firebase Auth, which costs
  // nothing and needs no bucket.
}
