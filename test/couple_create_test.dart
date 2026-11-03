import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/circles.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

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
          .doc(created.id)
          .collection('participants')
          .doc(partnerId)
          .get();
      expect(partnerRow.exists, isTrue);
      expect(partnerRow.data()?['inviteStatus'], 'accepted');

      final storedEvent =
          (await firestore.collection('events').doc(created.id).get()).data()!;
      expect(storedEvent['sharedWithMemberIds'], contains(partnerId));

      final partnerFeed = await repository.watchEvents(partnerId).firstWhere(
          (events) => events.any((event) => event.id == created.id));
      expect(partnerFeed.map((event) => event.id), contains(created.id));
    },
  );
}
