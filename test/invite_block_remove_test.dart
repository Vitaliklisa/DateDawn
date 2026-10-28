// The three flows reported broken after the previous round: accepting an
// invitation, blocking without a profile, and removing a collaborator.
//
// These run against `fake_cloud_firestore`, which does not evaluate security
// rules. What they pin is the WRITE SHAPE — the keys each operation sends and
// which document it touches — because that is exactly what the rules judge.
// Each test says which rule branch it corresponds to.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// The exact key set the invitee branch of the participant update rule allows.
/// Written out literally on purpose: if the repository starts sending anything
/// else, accept stops working against real Firestore and this fails first.
const _inviteeRowKeys = {
  'userId',
  'email',
  'role',
  'inviteStatus',
  'joinedAt',
  'invitationId',
  'invitationEmail',
};

Invitation _invite({
  String id = 'inv-1',
  String eventId = 'e1',
  String invitedBy = 'owner',
  String email = 'invitee@example.com',
  ParticipantRole role = ParticipantRole.editor,
  InviteStatus status = InviteStatus.pending,
}) =>
    Invitation(
      id: id,
      eventId: eventId,
      invitedBy: invitedBy,
      inviteeEmail: email,
      role: role,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2030, 1, 1),
      eventTitle: 'Trip',
    );

void main() {
  late FakeFirebaseFirestore db;
  late EventRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = EventRepository(firestore: db);
  });

  Future<void> seedEvent({String createdBy = 'owner'}) async {
    await db.collection('events').doc('e1').set({
      'title': 'Trip',
      'description': '',
      'createdBy': createdBy,
      'at': Timestamp.fromDate(DateTime(2030)),
      'createdAt': Timestamp.fromDate(DateTime(2026)),
      'updatedAt': Timestamp.fromDate(DateTime(2026)),
      'sharedWithMemberIds': <String>[],
    });
    await db
        .collection('events')
        .doc('e1')
        .collection('participants')
        .doc(createdBy)
        .set({
      'userId': createdBy,
      'email': '$createdBy@example.com',
      'role': 'admin',
      'inviteStatus': 'accepted',
    });
  }

  Future<void> seedParticipant(
    String uid, {
    String role = 'viewer',
    String status = 'accepted',
    String? invitationId,
  }) async {
    await db
        .collection('events')
        .doc('e1')
        .collection('participants')
        .doc(uid)
        .set({
      'userId': uid,
      'email': '$uid@example.com',
      'role': role,
      'inviteStatus': status,
      if (invitationId != null) 'invitationId': invitationId,
      if (invitationId != null) 'invitationEmail': '$uid@example.com',
    });
  }

  Future<void> seedInvite(Invitation invite) async {
    await db.collection('invitations').doc(invite.id).set({
      'eventId': invite.eventId,
      'invitedBy': invite.invitedBy,
      'inviteeEmail': invite.inviteeEmail,
      'role': invite.role.name,
      'status': invite.status.name,
      'createdAt': Timestamp.fromDate(invite.createdAt),
      'expiresAt': Timestamp.fromDate(invite.expiresAt),
      'eventTitle': invite.eventTitle,
    });
  }

  Future<Map<String, dynamic>?> row(String uid) async => (await db
          .collection('events')
          .doc('e1')
          .collection('participants')
          .doc(uid)
          .get())
      .data();

  // ---------------------------------------------------------------------------
  // Bug 3 — accepting an invitation
  // ---------------------------------------------------------------------------
  group('acceptInvitation', () {
    test('writes ONLY the keys the invitee rule allows', () async {
      await seedEvent();
      // The inviter's pending row for a known account — the case that used to
      // fail, because accept rewrote it with displayName/photoUrl too.
      await seedParticipant('invitee', status: 'pending');
      final invite = _invite();
      await seedInvite(invite);

      await repo.acceptInvitation(
        invitation: invite,
        userId: 'invitee',
        email: 'invitee@example.com',
        displayName: 'Invitee Person',
        photoUrl: 'https://example.com/p.png',
      );

      final data = (await row('invitee'))!;
      expect(
        data.keys.toSet().difference({'displayName', 'photoUrl'}),
        _inviteeRowKeys,
        reason: 'a key outside the rule\'s allow-list refuses the whole batch',
      );
      expect(data['inviteStatus'], 'accepted');
      // The role is the one the invitation granted, not one the client chose.
      expect(data['role'], 'editor');
      expect(data['invitationId'], 'inv-1');
    });

    test('the invitation is settled and the event lists the member', () async {
      await seedEvent();
      final invite = _invite();
      await seedInvite(invite);

      await repo.acceptInvitation(
        invitation: invite,
        userId: 'invitee',
        email: 'invitee@example.com',
      );

      final inviteDoc = await db.collection('invitations').doc('inv-1').get();
      expect(inviteDoc.data()!['status'], 'accepted');

      final event = await db.collection('events').doc('e1').get();
      expect(event.data()!['sharedWithMemberIds'], contains('invitee'));
    });

    test('a first-time accept creates the row with the invited role', () async {
      await seedEvent();
      final invite = _invite(role: ParticipantRole.viewer);
      await seedInvite(invite);

      await repo.acceptInvitation(
        invitation: invite,
        userId: 'invitee',
        email: 'invitee@example.com',
      );

      final data = (await row('invitee'))!;
      expect(data['role'], 'viewer');
      expect(data['userId'], 'invitee');
    });

    test('accepting when already a member says so, and does not rewrite',
        () async {
      await seedEvent();
      await seedParticipant('invitee', role: 'admin');
      final invite = _invite(role: ParticipantRole.viewer);
      await seedInvite(invite);

      await expectLater(
        repo.acceptInvitation(
          invitation: invite,
          userId: 'invitee',
          email: 'invitee@example.com',
        ),
        throwsA(
          isA<DataFailure>().having(
            (e) => e.message,
            'message',
            contains('already on this countdown'),
          ),
        ),
      );

      // Critically: the member's admin role was NOT downgraded to the
      // invitation's viewer role.
      expect((await row('invitee'))!['role'], 'admin');
    });

    test('an expired invitation is refused before any write', () async {
      await seedEvent();
      final expired = Invitation(
        id: 'inv-old',
        eventId: 'e1',
        invitedBy: 'owner',
        inviteeEmail: 'invitee@example.com',
        role: ParticipantRole.viewer,
        status: InviteStatus.pending,
        createdAt: DateTime(2020),
        expiresAt: DateTime(2021),
      );
      await seedInvite(expired);

      await expectLater(
        repo.acceptInvitation(
          invitation: expired,
          userId: 'invitee',
          email: 'invitee@example.com',
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('invitee'), isNull);
    });

    test('an already-answered invitation is refused, not re-accepted',
        () async {
      await seedEvent();
      final invite = _invite(status: InviteStatus.accepted);
      await seedInvite(invite);

      await expectLater(
        repo.acceptInvitation(
          invitation: invite,
          userId: 'invitee',
          email: 'invitee@example.com',
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('invitee'), isNull);
    });

    test('a missing invitation document is refused', () async {
      await seedEvent();
      await expectLater(
        repo.acceptInvitation(
          invitation: _invite(id: 'never-written'),
          userId: 'invitee',
          email: 'invitee@example.com',
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('invitee'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Bug 1 — blocking
  // ---------------------------------------------------------------------------
  group('blockUser', () {
    test('succeeds with no parent profile document, and creates one', () async {
      expect((await db.collection('users').doc('me').get()).exists, isFalse);

      await repo.blockUser(userId: 'me', targetUid: 'them');

      final block = await db
          .collection('users')
          .doc('me')
          .collection('blocked')
          .doc('them')
          .get();
      expect(block.exists, isTrue);
      expect(block.data()!['active'], isTrue);
      expect((await db.collection('users').doc('me').get()).exists, isTrue);
    });

    test('still blocks when the participant cleanup is refused', () async {
      // The blocker is on a countdown they can see but do not administer, so
      // the rule refuses deleting someone else's participant row. The block is
      // per-user and private, so it must still land — the cleanup is a
      // best-effort courtesy, not a precondition.
      await seedEvent();
      await seedParticipant('them', status: 'accepted');
      final guarded = _RefusingCleanupRepository(db);

      await guarded.blockUser(userId: 'me', targetUid: 'them');

      final block = await db
          .collection('users')
          .doc('me')
          .collection('blocked')
          .doc('them')
          .get();
      expect(block.exists, isTrue,
          reason: 'a refused cleanup must not abort the block itself');
      // The row is still there — the denial was logged and swallowed.
      expect(await row('them'), isNotNull);
    });

    test('blocking twice is harmless and keeps one row', () async {
      await repo.blockUser(userId: 'me', targetUid: 'them');
      await repo.blockUser(userId: 'me', targetUid: 'them');

      final all =
          await db.collection('users').doc('me').collection('blocked').get();
      expect(all.docs, hasLength(1));
    });

    test('unblocking removes the row and the list goes empty', () async {
      await repo.blockUser(userId: 'me', targetUid: 'them');
      expect(await repo.watchBlockedUsers('me').first, hasLength(1));

      await repo.unblockUser(userId: 'me', targetUid: 'them');
      expect(await repo.watchBlockedUsers('me').first, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Bug 2 — removing a collaborator
  // ---------------------------------------------------------------------------
  group('removeParticipant', () {
    test('the creator can remove a collaborator', () async {
      await seedEvent();
      await seedParticipant('viewer');

      await repo.removeParticipant(
          eventId: 'e1', actorId: 'owner', userId: 'viewer');

      expect(await row('viewer'), isNull);
    });

    test('a non-creator admin can remove a viewer', () async {
      await seedEvent();
      await seedParticipant('admin', role: 'admin');
      await seedParticipant('viewer');

      await repo.removeParticipant(
          eventId: 'e1', actorId: 'admin', userId: 'viewer');

      expect(await row('viewer'), isNull);
    });

    test('a non-creator admin cannot remove another admin', () async {
      await seedEvent();
      await seedParticipant('admin', role: 'admin');
      await seedParticipant('admin2', role: 'admin');

      await expectLater(
        repo.removeParticipant(
            eventId: 'e1', actorId: 'admin', userId: 'admin2'),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('admin2'), isNotNull);
    });

    test('an editor cannot remove anyone', () async {
      await seedEvent();
      await seedParticipant('editor', role: 'editor');
      await seedParticipant('viewer');

      await expectLater(
        repo.removeParticipant(
            eventId: 'e1', actorId: 'editor', userId: 'viewer'),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('viewer'), isNotNull);
    });

    test('a viewer cannot remove anyone', () async {
      await seedEvent();
      await seedParticipant('viewer');
      await seedParticipant('viewer2');

      await expectLater(
        repo.removeParticipant(
            eventId: 'e1', actorId: 'viewer', userId: 'viewer2'),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('viewer2'), isNotNull);
    });

    test('the creator can never be removed, not even by another admin',
        () async {
      await seedEvent();
      await seedParticipant('admin', role: 'admin');

      await expectLater(
        repo.removeParticipant(
            eventId: 'e1', actorId: 'admin', userId: 'owner'),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('owner'), isNotNull,
          reason: 'ownership must survive every removal path');
    });

    test('removing yourself through this path is refused', () async {
      await seedEvent();
      await seedParticipant('admin', role: 'admin');

      await expectLater(
        repo.removeParticipant(
            eventId: 'e1', actorId: 'admin', userId: 'admin'),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('admin'), isNotNull);
    });

    test('a role change on the target is respected before removal', () async {
      // The screen believes `viewer` is a viewer; Firestore says they were just
      // promoted to admin. A non-creator admin must then be refused.
      await seedEvent();
      await seedParticipant('admin', role: 'admin');
      await seedParticipant('viewer');
      await db
          .collection('events')
          .doc('e1')
          .collection('participants')
          .doc('viewer')
          .update({'role': 'admin'});

      await expectLater(
        repo.removeParticipant(
            eventId: 'e1', actorId: 'admin', userId: 'viewer'),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('viewer'), isNotNull);
    });

    test('removing someone who is already gone is not an error', () async {
      await seedEvent();
      await repo.removeParticipant(
          eventId: 'e1', actorId: 'owner', userId: 'ghost');
    });
  });

  // ---------------------------------------------------------------------------
  // Regressions from the "I cannot invite or accept anything" report
  // ---------------------------------------------------------------------------
  group('isBlocked never reports a false positive', () {
    test('a blank target uid does not match every row', () async {
      await db
          .collection('users')
          .doc('me')
          .collection('blocked')
          .doc('someone')
          .set({'email': 'someone@example.com', 'active': true});

      // The invite path passes '' when an address has no account yet.
      expect(
        await repo.isBlocked(userId: 'me', targetUid: ''),
        isFalse,
        reason: 'an unresolved account is not a blocked account',
      );
    });

    test('a blank target uid still matches by email', () async {
      await db
          .collection('users')
          .doc('me')
          .collection('blocked')
          .doc('someone')
          .set({'email': 'someone@example.com', 'active': true});

      expect(
        await repo.isBlocked(
            userId: 'me', targetUid: '', targetEmail: 'someone@example.com'),
        isTrue,
      );
      expect(
        await repo.isBlocked(
            userId: 'me', targetUid: '', targetEmail: 'other@example.com'),
        isFalse,
      );
    });

    test('an empty blocked list never blocks anything', () async {
      expect(await repo.isBlocked(userId: 'me', targetUid: 'them'), isFalse);
      expect(
        await repo.isBlocked(
            userId: 'me', targetUid: '', targetEmail: 'x@example.com'),
        isFalse,
      );
    });

    test('an inactive row is not a live block', () async {
      await db
          .collection('users')
          .doc('me')
          .collection('blocked')
          .doc('them')
          .set({'email': 'them@example.com', 'active': false});

      expect(await repo.isBlocked(userId: 'me', targetUid: 'them'), isFalse);
    });
  });

  group('updateParticipantRole trusts Firestore, not the screen snapshot', () {
    CountdownEvent staleEvent(List<Participant> participants) => CountdownEvent(
          id: 'e1',
          title: 'Trip',
          description: '',
          at: DateTime(2030),
          createdBy: 'owner',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          participants: participants,
        );

    test('an admin whose row is missing from the passed event can still act',
        () async {
      await seedEvent();
      await seedParticipant('admin', role: 'admin');
      await seedParticipant('viewer');

      // The stale screen copy: the admin's own row was never hydrated, so it
      // is absent and `roleFor` would read them as a viewer.
      final stale = staleEvent(const [
        Participant(
          userId: 'viewer',
          email: 'viewer@example.com',
          role: ParticipantRole.viewer,
          inviteStatus: InviteStatus.accepted,
        ),
      ]);

      await repo.updateParticipantRole(
        eventId: 'e1',
        actorId: 'admin',
        participant: stale.participants.single,
        role: ParticipantRole.editor,
        event: stale,
      );

      expect((await row('viewer'))!['role'], 'editor');
    });

    test('a stale snapshot cannot grant authority either', () async {
      await seedEvent();
      // Firestore says editor; the stale copy claims admin.
      await seedParticipant('editor', role: 'editor');
      await seedParticipant('viewer');

      final stale = staleEvent(const [
        Participant(
          userId: 'editor',
          email: 'editor@example.com',
          role: ParticipantRole.admin,
          inviteStatus: InviteStatus.accepted,
        ),
        Participant(
          userId: 'viewer',
          email: 'viewer@example.com',
          role: ParticipantRole.viewer,
          inviteStatus: InviteStatus.accepted,
        ),
      ]);

      await expectLater(
        repo.updateParticipantRole(
          eventId: 'e1',
          actorId: 'editor',
          participant: stale.participants.last,
          role: ParticipantRole.editor,
          event: stale,
        ),
        throwsA(isA<DataFailure>()),
      );
      expect((await row('viewer'))!['role'], 'viewer');
    });
  });

  group('accepting is not blocked by a preference read', () {
    test('an empty blocked list lets a normal invitation through', () async {
      await seedEvent();
      final invite = _invite();
      await seedInvite(invite);

      await repo.acceptInvitation(
        invitation: invite,
        userId: 'invitee',
        email: 'invitee@example.com',
      );

      expect((await row('invitee'))!['inviteStatus'], 'accepted');
    });

    test('a real block still refuses the invitation', () async {
      await seedEvent();
      await repo.blockUser(userId: 'invitee', targetUid: 'owner');
      final invite = _invite();
      await seedInvite(invite);

      await expectLater(
        repo.acceptInvitation(
          invitation: invite,
          userId: 'invitee',
          email: 'invitee@example.com',
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(await row('invitee'), isNull);
    });
  });
}

/// The real block, with the participant cleanup guaranteed to be refused.
///
/// That is the shape of the live failure: the block row write is allowed, and
/// the tidy-up that pulls the blocked person out of a countdown the blocker
/// does not administer comes back `permission-denied`. If that denial ever
/// escapes `blockUser`, this test fails with the same "You do not have
/// permission" the user saw.
class _RefusingCleanupRepository extends EventRepository {
  _RefusingCleanupRepository(FirebaseFirestore firestore)
      : super(firestore: firestore);

  @override
  Future<void> removeBlockedParticipant(
    DocumentReference<Map<String, dynamic>> eventRef,
    String targetUid,
  ) async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Missing or insufficient permissions.',
    );
  }
}
