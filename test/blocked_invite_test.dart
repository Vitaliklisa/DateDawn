import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not send a countdown invite to someone who blocked the inviter',
      () async {
    final firestore = FakeFirebaseFirestore();
    final repository = EventRepository(firestore: firestore);
    final event = CountdownEvent.fromDoc('event-1', {
      'title': 'Weekend trip',
      'createdBy': 'inviter',
      'at': Timestamp.fromDate(DateTime(2030, 1, 1)),
    });
    await firestore.collection('events').doc(event.id).set({
      'title': event.title,
      'createdBy': event.createdBy,
      'sharedWithMemberIds': <String>[],
    });
    await firestore
        .collection('users')
        .doc('invitee')
        .collection('blocked')
        .doc('inviter')
        .set({'email': 'inviter@example.com', 'active': true});

    await expectLater(
      repository.inviteByEmail(
        event: event,
        inviterId: 'inviter',
        inviterEmail: 'inviter@example.com',
        email: 'invitee@example.com',
        knownUserId: 'invitee',
        role: ParticipantRole.viewer,
      ),
      throwsA(isA<DataFailure>()),
    );

    expect(
      (await firestore.collection('invitations').get()).docs,
      isEmpty,
    );
    expect(
      (await firestore
              .collection('events')
              .doc(event.id)
              .collection('participants')
              .get())
          .docs,
      isEmpty,
    );
  });
}
