import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('watchEvents emits a countdown shared with the partner', () async {
    final firestore = FakeFirebaseFirestore();
    final event = firestore.collection('events').doc('e1');
    await event.set({
      'title': 'Anniversary',
      'description': '',
      'at': Timestamp.fromDate(DateTime(2030, 1, 1)),
      'createdBy': 'creator',
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'deletedAt': null,
      'sharedWithMemberIds': ['creator', 'partner'],
    });
    for (final userId in ['creator', 'partner']) {
      await event.collection('participants').doc(userId).set({
        'userId': userId,
        'role': userId == 'creator' ? 'admin' : 'editor',
        'inviteStatus': 'accepted',
      });
    }

    final events = await EventRepository(firestore: firestore)
        .watchEvents('partner')
        .firstWhere((events) => events.any(
              (event) => event.id == 'e1' && event.participants.length == 2,
            ))
        .timeout(const Duration(seconds: 2));

    expect(events, hasLength(1));
    expect(events.single.id, 'e1');
    expect(events.single.title, 'Anniversary');
    expect(events.single.participants.map((row) => row.userId),
        containsAll(['creator', 'partner']));
  });
}
