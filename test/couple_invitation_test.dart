import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/circles.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:datedawn/widgets/invitations_inbox.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'couple acceptance adds membership and shared countdown; repeat is idempotent',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = EventRepository(firestore: firestore);
      final invite = CircleInvitation(
        id: 'couple-invite',
        circleId: 'couple-circle',
        invitedBy: 'owner',
        invitedByName: 'Owner',
        inviteeEmail: 'partner@example.com',
        circleName: 'Us',
        isCouple: true,
        createdAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2030, 1, 1),
      );

      await firestore.collection('circles').doc(invite.circleId).set({
        'name': 'Us',
        'ownerId': 'owner',
        'isCouple': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'memberIds': ['owner'],
      });
      await firestore
          .collection('circles')
          .doc(invite.circleId)
          .collection('members')
          .doc('owner')
          .set({
        'email': 'owner@example.com',
        'isOwner': true,
      });
      await firestore.collection('circle_invitations').doc(invite.id).set({
        'circleId': invite.circleId,
        'invitedBy': invite.invitedBy,
        'inviteeEmail': invite.inviteeEmail,
        'circleName': invite.circleName,
        'isCouple': true,
        'status': InviteStatus.pending.name,
        'createdAt': Timestamp.fromDate(invite.createdAt),
        'expiresAt': Timestamp.fromDate(invite.expiresAt),
      });
      await firestore.collection('events').doc('event-1').set({
        'title': 'Summer trip',
        'description': '',
        'createdBy': 'owner',
        'at': Timestamp.fromDate(DateTime(2030, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'sharedWithCircleIds': [invite.circleId],
        // Invitation-time seeding makes pre-existing shared countdowns
        // discoverable as soon as the invitee joins the circle.
        'sharedWithMemberIds': ['owner', 'partner'],
      });

      await repository.acceptCircleInvitation(
        invitation: invite,
        userId: 'partner',
        email: 'partner@example.com',
        displayName: 'Partner',
      );

      final member = await firestore
          .collection('circles')
          .doc(invite.circleId)
          .collection('members')
          .doc('partner')
          .get();
      expect(member.exists, isTrue);
      final circle =
          (await firestore.collection('circles').doc(invite.circleId).get())
              .data()!;
      expect(circle['memberIds'], contains('partner'));

      final visibleEvents = await repository
          .watchEvents('partner')
          .firstWhere((events) => events.any((event) => event.id == 'event-1'));
      expect(
          visibleEvents.map((event) => event.title), contains('Summer trip'));

      await repository.acceptCircleInvitation(
        invitation: invite,
        userId: 'partner',
        email: 'partner@example.com',
        displayName: 'Partner',
      );
    },
  );

  testWidgets('a failed automatic couple join shows its actual reason',
      (tester) async {
    const message =
        'This couple invitation could not be accepted because membership '
        'was refused.';
    final invite = CircleInvitation(
      id: 'couple-invite',
      circleId: 'couple-circle',
      invitedBy: 'owner',
      inviteeEmail: 'partner@example.com',
      circleName: 'Us',
      isCouple: true,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2030, 1, 1),
    );
    final repository = _FailingCircleRepository(invite);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AppUser(id: 'partner', email: 'partner@example.com'),
          ),
          authResolvedProvider.overrideWithValue(true),
          blockedUsersProvider.overrideWith(_NoBlockedUsers.new),
          eventRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: InvitationsInbox(showWhenEmpty: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
    expect(find.text('Retry adding you'), findsOneWidget);
  });
}

class _NoBlockedUsers extends BlockedUsers {
  @override
  Future<List<BlockedUser>> build() async => const [];
}

class _FailingCircleRepository extends EventRepository {
  _FailingCircleRepository(this.invitation)
      : super(firestore: FakeFirebaseFirestore());

  final CircleInvitation invitation;

  @override
  Stream<List<CircleInvitation>> watchCircleInvitations(String email) =>
      Stream.value([invitation]);

  @override
  Future<bool> acceptCircleInvitation({
    required CircleInvitation invitation,
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    throw const DataFailure(
      'This couple invitation could not be accepted because membership '
      'was refused.',
    );
  }
}
