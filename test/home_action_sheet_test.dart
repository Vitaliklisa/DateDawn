import 'package:datedawn/core/models.dart';
import 'package:datedawn/core/notifications.dart';
import 'package:datedawn/core/theme.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/screens/home_screen.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _viewport = Size(1920, 1080);

CountdownEvent _event({
  required String id,
  required String title,
  required String createdBy,
}) =>
    CountdownEvent(
      id: id,
      title: title,
      description: '',
      at: DateTime(2030, 1, 1),
      createdBy: createdBy,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Future<void> _pumpHome(WidgetTester tester, {required String userId}) async {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final events = [
    _event(id: 'featured', title: 'Featured countdown', createdBy: 'creator'),
    _event(id: 'other', title: 'Other countdown', createdBy: 'creator'),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(
          AppUser(id: userId, email: '$userId@example.com'),
        ),
        authResolvedProvider.overrideWithValue(true),
        eventsProvider.overrideWith((ref) => Stream.value(events)),
        clockProvider.overrideWith((ref) => Stream.value(DateTime(2035))),
        invitationsProvider.overrideWith((ref) => Stream.value(const [])),
        circleInvitationsProvider.overrideWith((ref) => Stream.value(const [])),
        responsesProvider.overrideWith((ref) => Stream.value(const [])),
        appNotificationsProvider
            .overrideWith((ref) => Stream.value(const <AppNotification>[])),
      ],
      child: MaterialApp(
        theme: AppTheme.build(brightness: Brightness.dark),
        home: const HomeScreen(focusedEventId: 'featured'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(tester.takeException(), isNull);

  final options = find.byTooltip('Options').last;
  await tester.tap(options);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('Home action sheet shows Delete for the event creator',
      (tester) async {
    await _pumpHome(tester, userId: 'creator');

    expect(find.text('Delete countdown').hitTestable(), findsOneWidget);

    final sheetColumn = find
        .ancestor(
          of: find.text('Delete countdown'),
          matching: find.byType(Column),
        )
        .last;
    final sheetSafeArea = find
        .ancestor(
          of: find.text('Delete countdown'),
          matching: find.byType(SafeArea),
        )
        .first;
    final screenHeight =
        MediaQuery.sizeOf(tester.element(sheetSafeArea)).height;
    expect(
      tester.getSize(sheetColumn).height,
      lessThan(screenHeight * 0.85),
      reason: 'the sheet column should wrap to content below 85% of screen',
    );
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('Home action sheet hides Delete from a non-creator',
      (tester) async {
    await _pumpHome(tester, userId: 'viewer');

    expect(find.text('Delete countdown'), findsNothing);
  });
}
