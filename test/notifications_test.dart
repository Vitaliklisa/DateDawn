import 'dart:async';

import 'package:datedawn/core/notifications.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppNotification', () {
    test('parses a Firestore document and preserves its read state', () {
      // The inbox lives at users/{uid}/notifications/{id}, so the recipient is
      // the path rather than a field — it is passed in by the reader.
      final notification = AppNotification.fromDoc('n1', 'u1', {
        'title': 'A countdown changed',
        'body': 'Your trip is now shared.',
        'type': 'circle',
        'read': true,
        'createdAt': '2026-10-05T12:00:00.000Z',
      });

      expect(notification.id, 'n1');
      expect(notification.userId, 'u1');
      expect(notification.kind, NotificationKind.circle);
      expect(notification.isRead, isTrue);
      expect(notification.createdAt, DateTime.utc(2026, 10, 5, 12).toLocal());
    });

    test('falls back safely for unknown or sparse wire values', () {
      final notification = AppNotification.fromDoc('n1', 'u1', {
        'type': 'future-kind',
        'title': 42,
        'read': 'true',
      });

      expect(notification.kind, NotificationKind.system);
      expect(notification.title, '');
      // A non-bool `read` must not be treated as true.
      expect(notification.isRead, isFalse);
    });

    test('round-trips through the document body', () {
      final original = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'Title',
        body: 'Body',
        kind: NotificationKind.invitation,
        isRead: true,
        createdAt: DateTime.utc(2026, 10, 5),
      );

      final doc = original.toDoc();
      expect(doc['title'], 'Title');
      expect(doc['type'], 'invitation');
      expect(doc['read'], isTrue);
      // The id is the document name, so it must not be duplicated in the body.
      expect(doc.containsKey('id'), isFalse);
      expect(doc.containsKey('user_id'), isFalse);
    });
  });

  group('theme mode persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('restores the local mode and syncs it to a new account', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final service = _FakeNotificationService();
      final container = ProviderContainer(overrides: [
        currentUserProvider.overrideWithValue(
          const AppUser(id: 'u1', email: 'user@example.com'),
        ),
        notificationServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      await pumpEventQueue();

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(service.savedWireMode, 'light');
    });

    test('a saved remote preference replaces the local fallback', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final service = _FakeNotificationService()..storedWireMode = 'system';
      final container = ProviderContainer(overrides: [
        currentUserProvider.overrideWithValue(
          const AppUser(id: 'u1', email: 'user@example.com'),
        ),
        notificationServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      container.read(themeModeProvider);
      await pumpEventQueue();

      expect(container.read(themeModeProvider), ThemeMode.system);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('theme_mode'), 'system');
    });
  });

  test('streams inbox items for the active user', () async {
    final notification = AppNotification(
      id: 'n1',
      userId: 'u1',
      title: 'Countdown updated',
      body: '',
      kind: NotificationKind.system,
      isRead: false,
      createdAt: DateTime.utc(2026, 10, 5),
    );
    final service = _FakeNotificationService()
      ..notificationStream = Stream.value([notification]);
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(
        const AppUser(id: 'u1', email: 'user@example.com'),
      ),
      notificationServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);

    final emittedItems = Completer<List<AppNotification>>();
    final subscription = container.listen(
      appNotificationsProvider,
      (previous, next) {
        next.whenData((items) {
          if (!emittedItems.isCompleted) emittedItems.complete(items);
        });
      },
    );
    addTearDown(subscription.close);
    final items = await emittedItems.future;

    expect(items, [notification]);
    expect(service.watchedUserId, 'u1');
  });
}

class _FakeNotificationService implements NotificationService {
  String? storedWireMode;
  String? savedWireMode;
  String? watchedUserId;
  Stream<List<AppNotification>>? notificationStream;

  @override
  Future<String?> fetchThemeMode(String userId) async => storedWireMode;

  @override
  Future<void> saveThemeMode(String userId, String wireMode) async {
    savedWireMode = wireMode;
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    watchedUserId = userId;
    return notificationStream ?? Stream.value(const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
