import 'package:flutter/material.dart';

/// The kind of a notification, used to pick an icon and (later) a destination.
///
/// Stored as the enum name so a row written by one client version is readable
/// by another even if the enum grows.
enum NotificationKind {
  invitation,
  circle,
  system,
  reminder;

  static NotificationKind fromWire(Object? value) {
    switch (value) {
      case 'invitation':
        return NotificationKind.invitation;
      case 'circle':
        return NotificationKind.circle;
      case 'reminder':
        return NotificationKind.reminder;
      default:
        return NotificationKind.system;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationKind.invitation:
        return Icons.mail_outline_rounded;
      case NotificationKind.circle:
        return Icons.groups_outlined;
      case NotificationKind.reminder:
        return Icons.alarm_rounded;
      case NotificationKind.system:
        return Icons.notifications_none_rounded;
    }
  }
}

/// One row of the Supabase `notifications` table.
///
/// Deliberately separate from the Firestore-backed `InvitationResponse` in
/// `core/models.dart`: that one is the Firebase notification log, this one is
/// the Supabase inbox. Keeping the types apart is what stops the two backends
/// from becoming entangled.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.kind,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationKind kind;
  final bool isRead;
  final DateTime createdAt;

  /// Builds from a Supabase row.
  ///
  /// Every field is defensive: a row written by a future client, or by hand in
  /// the dashboard, should render as a blank line rather than crash the inbox.
  factory AppNotification.fromRow(Map<String, dynamic> row) => AppNotification(
        id: (row['id'] ?? '').toString(),
        userId: (row['user_id'] ?? '').toString(),
        title: row['title'] is String ? row['title'] as String : '',
        body: row['body'] is String ? row['body'] as String : '',
        kind: NotificationKind.fromWire(row['type']),
        isRead: row['is_read'] == true,
        createdAt: _parseTimestamp(row['created_at']),
      );

  /// Builds from a `users/{uid}/notifications/{id}` Firestore document.
  ///
  /// The recipient is not stored on the document — it is the path — so
  /// `userId` is passed in by the reader, which already knows whose inbox it
  /// subscribed to.
  factory AppNotification.fromDoc(
    String id,
    String userId,
    Map<String, dynamic> doc,
  ) =>
      AppNotification(
        id: id,
        userId: userId,
        title: doc['title'] is String ? doc['title'] as String : '',
        body: doc['body'] is String ? doc['body'] as String : '',
        kind: NotificationKind.fromWire(doc['type']),
        isRead: doc['read'] == true,
        createdAt: _parseTimestamp(doc['createdAt']),
      );

  /// The Firestore document body, minus the id (which is the document name).
  Map<String, dynamic> toDoc() => {
        'title': title,
        'body': body,
        'type': kind.name,
        'read': isRead,
      };

  Map<String, dynamic> toRow() => {
        'user_id': userId,
        'title': title,
        'body': body,
        'type': kind.name,
        'is_read': isRead,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        userId: userId,
        title: title,
        body: body,
        kind: kind,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

/// Parses a Postgres `timestamptz`, which PostgREST returns as an ISO-8601
/// string. A `DateTime` is accepted too so a locally-constructed row works in
/// tests without going through JSON.
DateTime _parseTimestamp(Object? value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value.toLocal();
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }
  return DateTime.now();
}

/// The wire form of a Flutter [ThemeMode], matching the check constraint on
/// `user_settings.theme_mode` in `supabase/schema.sql`.
String themeModeToWire(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

/// Parses a stored theme mode. Anything unrecognised falls back to `system`,
/// which is the same default the column carries.
ThemeMode? themeModeFromWire(Object? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return null;
  }
}
