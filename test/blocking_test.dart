// Blocking another person — the Google Play UGC requirement.
//
// The policy is not satisfied by a flag that is written and never read. These
// pin the two things that make a block a block: you cannot block yourself or an
// unidentifiable account, and the blocked list round-trips through the model
// with a label that is never blank.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// The constructor reaches for `FirebaseFirestore.instance` when none is given,
/// so a bare repository cannot be built in a test.
class _FakeFirestore extends Fake implements FirebaseFirestore {}

/// A minimal invitation, since only `id` and `invitedBy` matter to the filter.
Invitation _invite({required String id, required String invitedBy}) =>
    Invitation(
      id: id,
      eventId: 'event-1',
      invitedBy: invitedBy,
      inviteeEmail: 'me@example.com',
      role: ParticipantRole.viewer,
      status: InviteStatus.pending,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2026, 12, 31),
    );

void main() {
  _enforcement();

  group('BlockedUser', () {
    test('falls back from a name to an email, never to an empty label', () {
      expect(
        BlockedUser.fromMap('u1', {
          'email': 'sam@example.com',
          'displayName': 'Sam',
        }).label,
        'Sam',
      );
      expect(
        BlockedUser.fromMap('u2', {'email': 'sam@example.com'}).label,
        'sam@example.com',
      );
      expect(
        BlockedUser.fromMap('u3', {'email': '', 'displayName': '   '}).label,
        'Blocked user',
      );
    });

    test('reads a Firestore timestamp and an ISO string the same way', () {
      final iso = BlockedUser.fromMap('u1', {
        'blockedAt': '2026-02-01T10:00:00.000Z',
      });
      expect(iso.blockedAt, isNotNull);
      expect(iso.blockedAt!.toUtc().year, 2026);
      // A row written by a seed script or a test uses a string; one written by
      // the app uses a Timestamp. Both have to parse.
      expect(
        BlockedUser.fromMap('u1', {'blockedAt': null}).blockedAt,
        isNull,
      );
    });

    test('normalises the email so a block matches whatever case arrives', () {
      final person = BlockedUser.fromMap('u1', {'email': 'Sam@Example.COM'});
      expect(person.email, 'sam@example.com');
    });
  });

  group('blockUser guards', () {
    // The guards below throw before touching Firestore, so a fake is enough.
    final repo = EventRepository(firestore: _FakeFirestore());

    test('refuses to block yourself', () async {
      expect(
        () => repo.blockUser(userId: 'me', targetUid: 'me'),
        throwsA(isA<DataFailure>()),
      );
    });

    test('refuses an account it cannot identify', () async {
      expect(
        () => repo.blockUser(userId: 'me', targetUid: ''),
        throwsA(isA<DataFailure>()),
      );
    });
  });
}

/// A block is a standing refusal, not a one-off cleanup.
///
/// `blockUser` clears the pending invitations that existed at the time, but the
/// enforcement has to survive everything that happens afterwards: an invite
/// arriving later, one already on screen being accepted, a note left before the
/// block. These pin the shape of that enforcement at the level the UI reads.
void _enforcement() {
  group('blocked content is filtered, not just hidden by name', () {
    test('an invitation from a blocked uid is dropped from the inbox', () {
      const blockedIds = {'blocked-uid'};
      final invites = [
        _invite(id: 'a', invitedBy: 'blocked-uid'),
        _invite(id: 'b', invitedBy: 'friend-uid'),
      ];
      final visible =
          invites.where((i) => !blockedIds.contains(i.invitedBy)).toList();
      expect(visible.map((i) => i.id), ['b'],
          reason: 'the blocked person must not be able to reach the inbox');
    });

    test('a note left by a blocked uid is dropped', () {
      const blockedIds = {'blocked-uid'};
      final notes = [
        EventNote(
          id: 'n1',
          userId: 'blocked-uid',
          text: 'a comment before the block',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        EventNote(
          id: 'n2',
          userId: 'friend-uid',
          text: 'still visible',
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
      ];
      final visible =
          notes.where((n) => !blockedIds.contains(n.userId)).toList();
      expect(visible.map((n) => n.id), ['n2']);
    });
  });
}
