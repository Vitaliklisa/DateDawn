import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datedawn/core/circles.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/services/event_repository.dart';

/// Awaits the first non-empty emission from a stream, so a test does not race
/// the initial empty snapshot a live feed always emits first.
Future<List<T>> firstNonEmpty<T>(Stream<List<T>> stream) => stream
    .firstWhere((items) => items.isNotEmpty)
    .timeout(const Duration(seconds: 5));

void main() {
  test('a newly created countdown appears in the owner event stream', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = EventRepository(firestore: firestore);
    final firstEvent = Completer<List<CountdownEvent>>();
    final subscription = repository.watchEvents('owner-1').listen((events) {
      if (events.isNotEmpty && !firstEvent.isCompleted) {
        firstEvent.complete(events);
      }
    }, onError: firstEvent.completeError);

    try {
      final created = await repository.createEvent(
        userId: 'owner-1',
        email: 'owner@example.com',
        title: 'Test countdown',
        description: '',
        at: DateTime.now().add(const Duration(days: 10)),
      );
      final saved = await firestore.collection('events').doc(created.id).get();
      final events = await firstEvent.future.timeout(
        const Duration(seconds: 5),
      );

      expect(saved.data(), containsPair('deletedAt', isNull));
      expect(events.single.id, created.id);
      expect(events.single.title, 'Test countdown');
    } finally {
      await subscription.cancel();
    }
  });

  test('inviting your own email is refused with a readable message', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = EventRepository(firestore: firestore);
    final event = await repository.createEvent(
      userId: 'alex',
      email: 'alex@example.com',
      title: 'Trip',
      description: '',
      at: DateTime.now().add(const Duration(days: 5)),
    );

    // The same address in different casing must still be caught.
    await expectLater(
      repository.inviteByEmail(
        event: event,
        inviterId: 'alex',
        inviterEmail: 'ALEX@example.com',
        email: 'alex@example.com',
        role: ParticipantRole.viewer,
      ),
      throwsA(
        isA<DataFailure>().having(
          (e) => e.message,
          'message',
          cannotInviteSelfMessage,
        ),
      ),
    );
  });

  test('inviting your own address into your own circle is refused', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = EventRepository(firestore: firestore);
    final circle = await repository.createCircle(
      ownerId: 'alex',
      ownerEmail: 'alex@example.com',
      name: 'Us',
      isCouple: true,
    );

    await expectLater(
      repository.inviteToCircle(
        circle: circle,
        inviterId: 'alex',
        inviterEmail: 'alex@example.com',
        email: 'alex@example.com',
      ),
      throwsA(
        isA<DataFailure>().having(
          (e) => e.message,
          'message',
          cannotInviteSelfMessage,
        ),
      ),
    );
  });

  test('a couple circle auto-shares a new countdown with the partner',
      () async {
    final firestore = FakeFirebaseFirestore();
    final repository = EventRepository(firestore: firestore);

    final circle = await repository.createCircle(
      ownerId: 'alex',
      ownerEmail: 'alex@example.com',
      name: 'Us',
      isCouple: true,
    );
    await repository.inviteToCircle(
      circle: circle,
      inviterId: 'alex',
      inviterEmail: 'alex@example.com',
      email: 'sam@example.com',
    );
    final invites =
        await repository.watchCircleInvitations('sam@example.com').first;
    await repository.acceptCircleInvitation(
      invitation: invites.single,
      userId: 'sam',
      email: 'sam@example.com',
    );

    // The composer is handed a circle document WITHOUT its members, exactly as
    // `circlesProvider` streams it — the auto-share must still find the partner.
    final bare = Circle(
      id: circle.id,
      name: circle.name,
      ownerId: circle.ownerId,
      createdAt: circle.createdAt,
      isCouple: true,
      memberIds: const ['alex', 'sam'],
    );

    final created = await repository.createEvent(
      userId: 'alex',
      email: 'alex@example.com',
      title: 'Anniversary',
      description: '',
      at: DateTime.now().add(const Duration(days: 40)),
      autoShareCircleIds: [circle.id],
      circles: [bare],
    );

    expect(created.participants.map((p) => p.userId), contains('sam'));
    expect(created.sharedWithCircleIds, contains(circle.id));

    final samSees = await firstNonEmpty(repository.watchEvents('sam'));
    expect(samSees.map((e) => e.id), contains(created.id));
  });

  test('joining a circle writes an inbox notification for the inviter',
      () async {
    final firestore = FakeFirebaseFirestore();
    final sent = <({String userId, String title})>[];
    final repository = EventRepository(
      firestore: firestore,
      notificationSink: ({
        required userId,
        required title,
        required body,
        required kind,
      }) async {
        sent.add((userId: userId, title: title));
      },
    );

    final circle = await repository.createCircle(
      ownerId: 'alex',
      ownerEmail: 'alex@example.com',
      name: 'Family',
    );
    await repository.inviteToCircle(
      circle: circle,
      inviterId: 'alex',
      inviterEmail: 'alex@example.com',
      email: 'sam@example.com',
      inviterName: 'Alex',
    );

    final invites =
        await repository.watchCircleInvitations('sam@example.com').first;
    await repository.acceptCircleInvitation(
      invitation: invites.single,
      userId: 'sam',
      email: 'sam@example.com',
      displayName: 'Sam Taylor',
    );

    // The whole point of the fix: the Supabase inbox is actually written to.
    expect(sent, isNotEmpty);
    expect(sent.last.userId, 'alex');
    expect(sent.last.title, contains('Sam Taylor'));
    expect(sent.last.title, contains('Family'));
  });
}
