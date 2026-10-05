import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/services/event_repository.dart';

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
}
