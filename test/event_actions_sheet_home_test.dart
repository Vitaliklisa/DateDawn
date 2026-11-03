import 'package:datedawn/core/models.dart';
import 'package:datedawn/core/notifications.dart';
import 'package:datedawn/core/theme.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/screens/home_screen.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CountdownEvent _event({
  required String id,
  required String title,
  required String createdBy,
  List<Participant> participants = const [],
}) =>
    CountdownEvent(
      id: id,
      title: title,
      description: '',
      at: DateTime(2030, 1, 1),
      createdBy: createdBy,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      participants: participants,
    );

void main() {
  testWidgets(
    'home feed creator can see Delete and sheet wraps its content',
    (tester) async {
      const viewport = Size(960, 540);
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final events = [
        _event(
          id: 'featured',
          title: 'Featured countdown',
          createdBy: 'creator',
        ),
        // No participant rows: creator management must come from ownership,
        // not an asynchronously hydrated participant list.
        _event(
          id: 'other',
          title: 'Other countdown',
          createdBy: 'creator',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppUser(id: 'creator', email: 'creator@example.com'),
            ),
            authResolvedProvider.overrideWithValue(true),
            eventsProvider.overrideWith((ref) => Stream.value(events)),
            clockProvider.overrideWith((ref) => Stream.value(DateTime(2035))),
            invitationsProvider.overrideWith((ref) => Stream.value(const [])),
            circleInvitationsProvider
                .overrideWith((ref) => Stream.value(const [])),
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

      final options = find.byTooltip('Options').last;
      await tester.ensureVisible(options);
      await tester.pump();
      await tester.tap(options);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final deleteAction = find.text('Delete countdown');
      expect(
        deleteAction.hitTestable(),
        findsOneWidget,
        reason: 'the countdown creator must see Delete from the home feed',
      );
      final titleInSheet = find.text('Other countdown').last;
      final sheetMaterial = find
          .ancestor(of: titleInSheet, matching: find.byType(Material))
          .first;
      expect(
        tester.getSize(sheetMaterial).height,
        lessThan(viewport.height * 0.85),
        reason: 'the sheet should wrap its actions, not fill the 85% cap',
      );

      await tester.tap(deleteAction);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Delete this countdown?'), findsOneWidget);
      await tester.tap(find.text('Keep'));
      await tester.pump();
    },
  );
}
