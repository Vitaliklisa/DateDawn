import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/circles.dart';
import 'package:datedawn/core/theme.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/screens/event_editor_screen.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test(
    'creating in a couple circle adds the partner and exposes the countdown',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = EventRepository(firestore: firestore);
      const creatorId = 'creator';
      const partnerId = 'partner';
      const circleId = 'couple-circle';

      await firestore.collection('users').doc(partnerId).set({
        'email': 'partner@example.com',
        'displayName': 'Partner',
      });
      for (final (userId, email) in [
        (creatorId, 'creator@example.com'),
        (partnerId, 'partner@example.com'),
      ]) {
        await firestore
            .collection('circles')
            .doc(circleId)
            .collection('members')
            .doc(userId)
            .set({'email': email});
      }
      await firestore.collection('circles').doc(circleId).set({
        'name': 'Us',
        'ownerId': creatorId,
        'isCouple': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'memberIds': [creatorId, partnerId],
      });
      final circle = Circle.fromDoc(circleId, {
        'name': 'Us',
        'ownerId': creatorId,
        'isCouple': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'memberIds': [creatorId, partnerId],
      });
      final invitees = await repository.circleInvitees(
        circleIds: const [circleId],
        excludingUserId: creatorId,
      );

      final created = await repository.createEvent(
        userId: creatorId,
        email: 'creator@example.com',
        title: 'Anniversary',
        description: '',
        at: DateTime.now().add(const Duration(days: 30)),
        autoShareCircleIds: const [circleId],
        circles: [circle],
        invitationRecipients: invitees,
      );

      final partnerRow = await firestore
          .collection('events')
          .doc(created.event.id)
          .collection('participants')
          .doc(partnerId)
          .get();
      expect(partnerRow.exists, isTrue);
      expect(partnerRow.data()?['inviteStatus'], 'accepted');

      final storedEvent =
          (await firestore.collection('events').doc(created.event.id).get())
              .data()!;
      expect(storedEvent['sharedWithMemberIds'], contains(partnerId));

      final partnerFeed = await repository.watchEvents(partnerId).firstWhere(
          (events) => events.any((event) => event.id == created.event.id));
      expect(partnerFeed.map((event) => event.id), contains(created.event.id));
      expect(created.autoShared, contains(partnerId));
      expect(created.autoShareError, isNull);
    },
  );

  testWidgets('create editor confirms the couple partner was added',
      (tester) async {
    final firestore = FakeFirebaseFirestore();
    const circleId = 'couple-circle';
    await firestore.collection('users').doc('partner').set({
      'email': 'partner@example.com',
      'displayName': 'Partner',
    });
    await firestore.collection('circles').doc(circleId).set({
      'name': 'Us',
      'ownerId': 'creator',
      'isCouple': true,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'memberIds': ['creator', 'partner'],
    });
    for (final (userId, email) in [
      ('creator', 'creator@example.com'),
      ('partner', 'partner@example.com'),
    ]) {
      await firestore
          .collection('circles')
          .doc(circleId)
          .collection('members')
          .doc(userId)
          .set({'email': email});
    }

    await _createCountdownInEditor(
      tester,
      circle: _coupleCircle(circleId, ['creator', 'partner']),
      repository: EventRepository(
        firestore: firestore,
        coupleMemberWriter: ({
          required eventId,
          required inviterId,
          required members,
          required now,
        }) async =>
            ['partner'],
      ),
    );

    expect(
      find.text('Countdown created. Partner was added.'),
      findsOneWidget,
    );
  });

  testWidgets('create editor reports when couple auto-share fails',
      (tester) async {
    final circle = _coupleCircle('couple-circle', ['creator', 'partner']);
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('partner').set({
      'email': 'partner@example.com',
      'displayName': 'Partner',
    });
    final repository = EventRepository(
      firestore: firestore,
      coupleMemberWriter: ({
        required eventId,
        required inviterId,
        required members,
        required now,
      }) async {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      },
    );

    await _createCountdownInEditor(
      tester,
      circle: circle,
      repository: repository,
    );

    expect(
      find.text(
        'Countdown created, but Partner was not added. '
        'Invite them manually from the countdown.',
      ),
      findsOneWidget,
    );
    expect(find.text('Countdown created. Partner was added.'), findsNothing);
  });

  testWidgets('create editor explains a selected couple with no partner',
      (tester) async {
    final circle = _coupleCircle('couple-circle', const []);

    await _createCountdownInEditor(
      tester,
      circle: circle,
      repository: EventRepository(firestore: FakeFirebaseFirestore()),
    );

    expect(
      find.text(
        'Countdown created, but no partner was added. Invite them manually.',
      ),
      findsOneWidget,
    );
  });
}

Circle _coupleCircle(String id, List<String> memberIds) => Circle(
      id: id,
      name: 'Us',
      ownerId: 'creator',
      createdAt: DateTime(2026, 1, 1),
      isCouple: true,
      memberIds: memberIds,
    );

Future<void> _createCountdownInEditor(
  WidgetTester tester, {
  required Circle circle,
  required EventRepository repository,
}) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/event/new',
    routes: [
      GoRoute(
        path: '/event/new',
        builder: (context, state) => const EventEditorScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Home'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(
          const AppUser(id: 'creator', email: 'creator@example.com'),
        ),
        eventRepositoryProvider.overrideWithValue(repository),
        circlesProvider.overrideWith((ref) => Stream.value([circle])),
        recentContactsProvider.overrideWith((ref) => Stream.value(const [])),
        clockProvider.overrideWith((ref) => Stream.value(DateTime(2026, 1, 1))),
      ],
      child: MaterialApp.router(
        theme: AppTheme.build(brightness: Brightness.dark),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'Anniversary');
  await tester.scrollUntilVisible(
    find.text('Create countdown'),
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.text('Create countdown'));
  await tester.pumpAndSettle();
}
