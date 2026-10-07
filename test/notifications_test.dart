import 'dart:async';

import 'package:datedawn/core/notifications.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppNotification', () {
    test('parses notification rows and preserves their read state', () {
      final notification = AppNotification.fromRow({
        'id': 'n1',
        'user_id': 'u1',
        'title': 'A countdown changed',
        'body': 'Your trip is now shared.',
        'type': 'circle',
        'is_read': true,
        'created_at': '2026-10-05T12:00:00.000Z',
      });

      expect(notification.id, 'n1');
      expect(notification.userId, 'u1');
      expect(notification.kind, NotificationKind.circle);
      expect(notification.isRead, isTrue);
      expect(notification.createdAt, DateTime.utc(2026, 10, 5, 12).toLocal());
    });

    test('falls back safely for unknown or sparse wire values', () {
      final notification = AppNotification.fromRow({
        'type': 'future-kind',
        'title': 42,
        'is_read': 'true',
      });

      expect(notification.kind, NotificationKind.system);
      expect(notification.title, '');
      expect(notification.isRead, isFalse);
    });
  });

  group('theme mode persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('restores the local mode and syncs it to a new account', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final service = _FakeSupabaseService();
      final container = ProviderContainer(overrides: [
        currentUserProvider.overrideWithValue(
          const AppUser(id: 'u1', email: 'user@example.com'),
        ),
        supabaseServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      await pumpEventQueue();

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(service.savedMode, ThemeMode.light);
    });

    test('a saved Supabase preference replaces the local fallback', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final service = _FakeSupabaseService()..storedMode = ThemeMode.system;
      final container = ProviderContainer(overrides: [
        currentUserProvider.overrideWithValue(
          const AppUser(id: 'u1', email: 'user@example.com'),
        ),
        supabaseServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      container.read(themeModeProvider);
      await pumpEventQueue();

      expect(container.read(themeModeProvider), ThemeMode.system);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('theme_mode'), 'system');
    });
  });

  test('streams Supabase inbox items for the active Firebase user', () async {
    final notification = AppNotification(
      id: 'n1',
      userId: 'u1',
      title: 'Countdown updated',
      body: '',
      kind: NotificationKind.system,
      isRead: false,
      createdAt: DateTime.utc(2026, 10, 5),
    );
    final service = _FakeSupabaseService()
      ..notificationStream = Stream.value([notification]);
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(
        const AppUser(id: 'u1', email: 'user@example.com'),
      ),
      supabaseServiceProvider.overrideWithValue(service),
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

class _FakeSupabaseService implements SupabaseService {
  ThemeMode? storedMode;
  ThemeMode? savedMode;
  String? watchedUserId;
  bool cleared = false;
  Stream<List<AppNotification>>? notificationStream;

  @override
  void clearAuth() => cleared = true;

  @override
  Future<ThemeMode?> fetchThemeMode(String userId) async => storedMode;

  @override
  Future<void> saveThemeMode(String userId, ThemeMode mode) async {
    savedMode = mode;
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    watchedUserId = userId;
    return notificationStream ?? Stream.value(const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
