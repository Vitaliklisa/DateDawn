import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/notifications.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removing a collaborator writes a notification to their inbox',
      () async {
    final firestore = FakeFirebaseFirestore();
    final repository = EventRepository(
      firestore: firestore,
      notificationSink: ({
        required String userId,
        required String title,
        required String body,
        required NotificationKind kind,
      }) async {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
          'title': title,
          'body': body,
          'type': kind.name,
          'read': false,
          'createdAt': Timestamp.now(),
        });
      },
    );

    await firestore.collection('events').doc('event-1').set({
      'title': 'Summer trip',
      'createdBy': 'owner',
    });
    await firestore.collection('users').doc('admin').set({
      'email': 'admin@example.com',
      'displayName': 'Alex',
    });
    await firestore
        .collection('events')
        .doc('event-1')
        .collection('participants')
        .doc('admin')
        .set({
      'userId': 'admin',
      'email': 'admin@example.com',
      'displayName': 'Alex',
      'role': 'admin',
      'inviteStatus': 'accepted',
    });
    await firestore
        .collection('events')
        .doc('event-1')
        .collection('participants')
        .doc('editor')
        .set({
      'userId': 'editor',
      'email': 'editor@example.com',
      'role': 'editor',
      'inviteStatus': 'accepted',
    });

    await repository.removeParticipant(
      eventId: 'event-1',
      actorId: 'admin',
      userId: 'editor',
    );

    expect(
      (await firestore
              .collection('events')
              .doc('event-1')
              .collection('participants')
              .doc('editor')
              .get())
          .exists,
      isFalse,
    );
    final notifications = await firestore
        .collection('users')
        .doc('editor')
        .collection('notifications')
        .get();
    expect(notifications.docs, hasLength(1));
    expect(notifications.docs.single.data()['title'],
        'You were removed from "Summer trip"');
    expect(notifications.docs.single.data()['body'],
        'Alex removed you from this countdown.');
    expect(notifications.docs.single.data()['type'], 'system');
  });

  test('a refused notification does not undo a successful removal', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = EventRepository(
      firestore: firestore,
      notificationSink: ({
        required String userId,
        required String title,
        required String body,
        required NotificationKind kind,
      }) async {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
      },
    );
    await firestore.collection('events').doc('event-1').set({
      'title': 'Summer trip',
      'createdBy': 'owner',
    });
    await firestore
        .collection('events')
        .doc('event-1')
        .collection('participants')
        .doc('admin')
        .set({'role': 'admin'});
    await firestore
        .collection('events')
        .doc('event-1')
        .collection('participants')
        .doc('editor')
        .set({'role': 'editor'});

    await repository.removeParticipant(
      eventId: 'event-1',
      actorId: 'admin',
      userId: 'editor',
    );

    expect(
      (await firestore
              .collection('events')
              .doc('event-1')
              .collection('participants')
              .doc('editor')
              .get())
          .exists,
      isFalse,
    );
  });
}
