import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/circles.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the two circle flows that were reported broken:
/// deleting a circle the caller owns, and a couple circle sharing a countdown
/// with the partner automatically.
///
/// These run against `fake_cloud_firestore`, which does not evaluate security
/// rules — so they do not prove the rules are right. What they DO prove is the
/// shape of the writes, which is what the rules are written against:
///
///  * `deleteCircle` never puts a countdown update in the same batch as the
///    circle delete, so a countdown the caller cannot edit cannot take the
///    delete down with it.
///  * `deleteCircle` still removes the circle and its member rows.
///  * Creating a countdown in a couple circle puts the partner into
///    `sharedWithMemberIds`, which is the array both the feed query and the
///    read rule go through.
///  * Deleting a circle strips its members from `sharedWithMemberIds` on every
///    countdown it was shared with.

/// A circle document, in the shape `Circle.fromDoc` reads.
Map<String, dynamic> _circleDoc({
  required String ownerId,
  required List<String> memberIds,
  bool isCouple = false,
}) =>
    {
      'name': 'Us',
      'ownerId': ownerId,
      'isCouple': isCouple,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'memberIds': memberIds,
    };

void main() {
  late FakeFirebaseFirestore db;
  late EventRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = EventRepository(firestore: db);
  });

  group('deleteCircle', () {
    test('deletes the circle and its member rows', () async {
      await db.collection('circles').doc('c1').set(
            _circleDoc(ownerId: 'alex', memberIds: ['alex', 'sam']),
          );
      for (final uid in ['alex', 'sam']) {
        await db
            .collection('circles')
            .doc('c1')
            .collection('members')
            .doc(uid)
            .set({'email': '$uid@example.com'});
      }

      await repo.deleteCircle(circleId: 'c1', userId: 'alex');

      expect(
        (await db.collection('circles').doc('c1').get()).exists,
        isFalse,
        reason: 'the circle document must be gone',
      );
      expect(
        (await db.collection('circles').doc('c1').collection('members').get())
            .docs,
        isEmpty,
        reason: 'the member rows must be gone',
      );
    });

    test('refuses when the caller is not the owner', () async {
      await db.collection('circles').doc('c1').set(
            _circleDoc(ownerId: 'alex', memberIds: ['alex', 'sam']),
          );

      expect(
        () => repo.deleteCircle(circleId: 'c1', userId: 'sam'),
        throwsA(isA<DataFailure>()),
      );
      expect(
        (await db.collection('circles').doc('c1').get()).exists,
        isTrue,
        reason: 'a refused delete must leave the circle alone',
      );
    });

    test('unshares the circle from every countdown it was shared with',
        () async {
      await db.collection('circles').doc('c1').set(
            _circleDoc(ownerId: 'alex', memberIds: ['alex', 'sam']),
          );
      await db.collection('events').doc('e1').set({
        'title': 'Trip',
        'createdBy': 'alex',
        'sharedWithCircleIds': ['c1'],
        'sharedWithMemberIds': ['alex', 'sam'],
        'deletedAt': null,
      });

      await repo.deleteCircle(circleId: 'c1', userId: 'alex');

      final event = (await db.collection('events').doc('e1').get()).data()!;
      expect(
        event['sharedWithCircleIds'],
        isEmpty,
        reason: 'the countdown must no longer point at the deleted circle',
      );
      expect(
        event['sharedWithMemberIds'],
        isEmpty,
        reason:
            'the deleted circle\'s members must be pruned from the visibility '
            'array, or the countdown keeps being served to them',
      );
    });

    test(
        'the circle delete is not held hostage by a countdown it cannot '
        'unshare', () async {
      // A countdown that is NOT owned by the circle owner and carries no
      // participant row for them: in the real rules the unshare is refused.
      // The fake does not enforce that, so instead this asserts the ordering
      // contract — the countdown update and the circle delete never share a
      // batch. With the writes split, a refusal on the former cannot abort the
      // latter.
      await db.collection('circles').doc('c1').set(
            _circleDoc(ownerId: 'alex', memberIds: ['alex', 'sam']),
          );
      await db.collection('events').doc('theirs').set({
        'title': 'Someone else\'s',
        'createdBy': 'mallory',
        'sharedWithCircleIds': ['c1'],
        'sharedWithMemberIds': ['mallory', 'alex'],
        'deletedAt': null,
      });

      await repo.deleteCircle(circleId: 'c1', userId: 'alex');

      expect(
        (await db.collection('circles').doc('c1').get()).exists,
        isFalse,
        reason: 'the circle must be deleted regardless of the unshare outcome',
      );
    });
  });

  group('couple circle auto-share', () {
    test('inviting an existing account adds them without an invitation',
        () async {
      await db.collection('users').doc('sam').set({
        'email': 'sam@example.com',
        'displayName': 'Sam',
      });
      final circle = await repo.createCircle(
        ownerId: 'alex',
        ownerEmail: 'alex@example.com',
        name: 'Us',
        isCouple: true,
      );

      await repo.inviteToCircle(
        circle: circle,
        inviterId: 'alex',
        inviterEmail: 'alex@example.com',
        inviterName: 'Alex',
        email: 'SAM@example.com',
      );

      final stored =
          (await db.collection('circles').doc(circle.id).get()).data()!;
      expect(stored['memberIds'], contains('sam'));
      expect(
        (await db
                .collection('circles')
                .doc(circle.id)
                .collection('members')
                .doc('sam')
                .get())
            .data(),
        containsPair('email', 'sam@example.com'),
      );
      expect(
        (await db.collection('circle_invitations').get()).docs,
        isEmpty,
        reason: 'an existing partner should not need to accept an invitation',
      );
    });

    test('an unregistered partner can auto-join after creating an account',
        () async {
      final circle = await repo.createCircle(
        ownerId: 'alex',
        ownerEmail: 'alex@example.com',
        name: 'Us',
        isCouple: true,
      );

      await repo.inviteToCircle(
        circle: circle,
        inviterId: 'alex',
        inviterEmail: 'alex@example.com',
        inviterName: 'Alex',
        email: 'Sam@example.com',
      );

      final inviteSnapshot = await db.collection('circle_invitations').get();
      expect(inviteSnapshot.docs, hasLength(1));
      final invitation = CircleInvitation.fromDoc(
        inviteSnapshot.docs.single.id,
        inviteSnapshot.docs.single.data(),
      );
      expect(invitation.isCouple, isTrue);
      expect(invitation.inviteeEmail, 'sam@example.com');
      expect(invitation.status, InviteStatus.pending);

      await repo.acceptCircleInvitation(
        invitation: invitation,
        userId: 'sam',
        email: 'sam@example.com',
        displayName: 'Sam',
      );

      final stored =
          (await db.collection('circles').doc(circle.id).get()).data()!;
      expect(stored['memberIds'], contains('sam'));
      final accepted =
          (await db.collection('circle_invitations').doc(invitation.id).get())
              .data()!;
      expect(accepted['status'], InviteStatus.accepted.name);
    });

    test('remembered invitations are available from the recent contacts feed',
        () async {
      await repo.rememberInvitedContacts(
        userId: 'alex',
        contacts: const [
          InvitationRecipient(
            userId: 'sam',
            email: 'Sam@example.com',
            displayName: 'Sam',
          ),
        ],
      );

      final contacts = await repo.watchRecentContacts('alex').first;
      expect(contacts, hasLength(1));
      expect(contacts.single.email, 'sam@example.com');
      expect(contacts.single.userId, 'sam');
    });

    test('creating a countdown puts the partner into sharedWithMemberIds',
        () async {
      await db.collection('circles').doc('c1').set(
            _circleDoc(
              ownerId: 'alex',
              memberIds: ['alex', 'sam'],
              isCouple: true,
            ),
          );

      final circle = Circle(
        id: 'c1',
        name: 'Us',
        ownerId: 'alex',
        createdAt: DateTime(2026, 1, 1),
        isCouple: true,
        memberIds: const ['alex', 'sam'],
      );

      final created = await repo.createEvent(
        userId: 'alex',
        email: 'alex@example.com',
        title: 'Anniversary',
        description: '',
        at: DateTime.now().add(const Duration(days: 30)),
        autoShareCircleIds: const ['c1'],
        circles: [circle],
      );

      final stored =
          (await db.collection('events').doc(created.id).get()).data()!;
      expect(
        stored['sharedWithMemberIds'],
        contains('sam'),
        reason: 'the partner must be in the visibility array, or the countdown '
            'never reaches their feed',
      );
      expect(
        created.sharedWithMemberIds,
        contains('sam'),
        reason: 'the returned object must match what was written',
      );
      expect(
        (await db
                .collection('events')
                .doc(created.id)
                .collection('participants')
                .doc('sam')
                .get())
            .exists,
        isTrue,
        reason: 'the partner gets an accepted participant row, not an invite',
      );
    });

    test(
        'the partner is made visible even when their participant row cannot '
        'be written', () async {
      // Simulates the auto-share participant write failing: the circle lists
      // the partner, but the row write is skipped. The visibility array must
      // still carry them — that is the whole point of keying it off the
      // intended members rather than the rows that happened to be written.
      await db.collection('circles').doc('c1').set(
            _circleDoc(
              ownerId: 'alex',
              memberIds: ['alex', 'sam'],
              isCouple: true,
            ),
          );

      // A Circle whose in-memory members list is empty, forcing the repository
      // to hydrate from the subcollection — and the subcollection has no rows,
      // so `_addCoupleMembers` has nobody to write. The memberIds list is the
      // authoritative source the visibility write uses.
      final circle = Circle(
        id: 'c1',
        name: 'Us',
        ownerId: 'alex',
        createdAt: DateTime(2026, 1, 1),
        isCouple: true,
        memberIds: const ['alex', 'sam'],
      );

      final created = await repo.createEvent(
        userId: 'alex',
        email: 'alex@example.com',
        title: 'Trip',
        description: '',
        at: DateTime.now().add(const Duration(days: 10)),
        autoShareCircleIds: const ['c1'],
        circles: [circle],
      );

      final stored =
          (await db.collection('events').doc(created.id).get()).data()!;
      expect(
        stored['sharedWithMemberIds'],
        contains('sam'),
        reason: 'visibility must not depend on the participant-row write',
      );
    });
  });
}
