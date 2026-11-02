import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/core/circles.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:datedawn/widgets/invitations_inbox.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'accept adds the countdown to the feed and a repeated accept is successful',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final firestore = FakeFirebaseFirestore();
      final messengerKey = GlobalKey<ScaffoldMessengerState>();
      final event = CountdownEvent(
        id: 'event-1',
        title: 'Trip',
        description: '',
        at: DateTime(2030),
        createdBy: 'owner',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final invite = Invitation(
        id: 'invite-1',
        eventId: 'event-1',
        invitedBy: 'owner',
        inviteeEmail: 'invitee@example.com',
        role: ParticipantRole.editor,
        status: InviteStatus.pending,
        createdAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2030, 1, 1),
        eventTitle: 'Trip',
      );
      await firestore.collection('events').doc('event-1').set({
        'title': 'Trip',
        'description': '',
        'createdBy': 'owner',
        'at': Timestamp.fromDate(DateTime(2030)),
        'createdAt': Timestamp.fromDate(DateTime(2026)),
        'updatedAt': Timestamp.fromDate(DateTime(2026)),
        'sharedWithMemberIds': <String>[],
      });
      await firestore
          .collection('events')
          .doc('event-1')
          .collection('participants')
          .doc('owner')
          .set({
        'userId': 'owner',
        'email': 'owner@example.com',
        'role': 'admin',
        'inviteStatus': 'accepted',
      });
      await firestore.collection('invitations').doc(invite.id).set({
        'eventId': invite.eventId,
        'invitedBy': invite.invitedBy,
        'inviteeEmail': invite.inviteeEmail,
        'role': invite.role.name,
        'status': invite.status.name,
        'createdAt': Timestamp.fromDate(invite.createdAt),
        'expiresAt': Timestamp.fromDate(invite.expiresAt),
        'eventTitle': invite.eventTitle,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppUser(
                id: 'invitee',
                email: 'invitee@example.com',
                displayName: 'Invitee',
              ),
            ),
            authResolvedProvider.overrideWithValue(true),
            eventRepositoryProvider.overrideWithValue(
              _TestEventRepository(firestore: firestore, event: event),
            ),
            invitationsProvider.overrideWith(
              (ref) => Stream.value([invite]),
            ),
            circleInvitationsProvider.overrideWith(
              (ref) => Stream.value(const <CircleInvitation>[]),
            ),
          ],
          child: MaterialApp(
            scaffoldMessengerKey: messengerKey,
            home: Scaffold(
              body: ListView(
                children: [
                  const InvitationsInbox(showWhenEmpty: true),
                  const _CountdownFeed(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Join “Trip”?'), findsOneWidget);
      await tester.tap(find.text('Join'));
      await _pumpUntil(tester, find.text('Feed: Trip'));

      expect(find.text('Feed: Trip'), findsOneWidget);
      expect(
        (await firestore.collection('invitations').doc(invite.id).get())
            .data()?['status'],
        InviteStatus.accepted.name,
      );

      messengerKey.currentState!.hideCurrentSnackBar();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Accept'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (find.text('Join').evaluate().isNotEmpty) {
        await tester.tap(find.text('Join'));
      }
      await _pumpUntil(
        tester,
        find.text('You are already a member of “Trip”.'),
      );

      expect(find.text('You are already a member of “Trip”.'), findsOneWidget);
      expect(find.text('You do not have permission to do that.'), findsNothing);
      expect(find.text('Something went wrong.'), findsNothing);
    },
  );
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $finder');
}

class _CountdownFeed extends ConsumerWidget {
  const _CountdownFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).value ?? const <CountdownEvent>[];
    return Text('Feed: ${events.map((event) => event.title).join(', ')}');
  }
}

class _TestEventRepository extends EventRepository {
  _TestEventRepository({
    required FakeFirebaseFirestore firestore,
    required this.event,
  })  : _firestore = firestore,
        super(firestore: firestore);

  final FakeFirebaseFirestore _firestore;
  final CountdownEvent event;

  @override
  Stream<List<CountdownEvent>> watchEvents(String userId) {
    return _firestore
        .collection('events')
        .doc(event.id)
        .collection('participants')
        .doc(userId)
        .snapshots()
        .map((participant) {
      if (participant.data()?['inviteStatus'] == InviteStatus.accepted.name) {
        return [event];
      }
      return const <CountdownEvent>[];
    });
  }
}
