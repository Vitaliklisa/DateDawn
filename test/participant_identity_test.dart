// Participant identity: a collaborator must never render as a bare "?" when
// their account has an address.
//
// The report was a person shown as "?" instead of alexfriedman999@gmail.com.
// The cause was not the initials logic — `initials` already fell back to the
// email — it was that the participant ROW had `email: ''`. The couple auto-share
// builds member rows from the circle's `memberIds` (uids only), and wrote those
// straight into the participant document with no identity at all.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Participant identity', () {
    Participant person({String? name, String email = ''}) => Participant(
          userId: 'u1',
          email: email,
          role: ParticipantRole.viewer,
          inviteStatus: InviteStatus.accepted,
          displayName: name,
        );

    test('initials come from the name when there is one', () {
      expect(person(name: 'Alex Friedman').initials, 'AF');
      expect(person(name: '  Alex Friedman ').initials, 'AF');
    });

    test('initials fall back to the email local part', () {
      expect(
        person(email: 'alexfriedman999@gmail.com').initials,
        'AL',
        reason: 'the address must supply the letters, never a bare "?"',
      );
      // A dotted or underscored local part splits into two initials.
      expect(person(email: 'alex.friedman@example.com').initials, 'AF');
    });

    test('"?" only when there is genuinely no name and no email', () {
      expect(person().initials, '?');
    });

    test('the label prefers the name, then the address, never "?"', () {
      expect(person(name: 'Alex').label, 'Alex');
      expect(person(email: 'alexfriedman999@gmail.com').label,
          'alexfriedman999@gmail.com');
      expect(person().label, 'Collaborator');
    });

    test('a circle placeholder is named by its circle, not "?"', () {
      const circle = Participant(
        userId: 'circle:c1',
        email: '',
        role: ParticipantRole.viewer,
        inviteStatus: InviteStatus.accepted,
        kind: ParticipantKind.circle,
        circleName: 'Friends',
      );
      expect(circle.label, 'Friends');
    });
  });

  group('participant rows missing an email', () {
    late FakeFirebaseFirestore db;
    late EventRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = EventRepository(firestore: db);
    });

    Future<void> seedEvent() async {
      await db.collection('events').doc('e1').set({
        'title': 'Trip',
        'createdBy': 'owner',
        'at': Timestamp.fromDate(DateTime(2030)),
      });
    }

    Future<void> seedBlankRow(String uid) async {
      await db
          .collection('events')
          .doc('e1')
          .collection('participants')
          .doc(uid)
          .set({
        'userId': uid,
        'email': '',
        'role': 'editor',
        'inviteStatus': 'accepted',
      });
    }

    Future<void> seedProfile(String uid, String email, {String? name}) async {
      await db.collection('users').doc(uid).set({
        'email': email,
        if (name != null) 'displayName': name,
      });
    }

    test('a blank row is hydrated from users/{uid} in the stream', () async {
      await seedEvent();
      await seedBlankRow('alex');
      await seedProfile('alex', 'alexfriedman999@gmail.com', name: 'Alex');

      final people = await repo.watchParticipants('e1').first;
      final alex = people.firstWhere((p) => p.userId == 'alex');

      expect(alex.email, 'alexfriedman999@gmail.com');
      expect(alex.displayName, 'Alex');
      expect(alex.initials, 'AL');
      expect(alex.label, 'Alex');
    });

    test('the repair is persisted for the next reader', () async {
      await seedEvent();
      await seedBlankRow('alex');
      await seedProfile('alex', 'alexfriedman999@gmail.com');

      await repo.watchParticipants('e1').first;
      // The stream kicks off a best-effort write; let it land.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final row = await db
          .collection('events')
          .doc('e1')
          .collection('participants')
          .doc('alex')
          .get();
      expect(row.data()!['email'], 'alexfriedman999@gmail.com');
    });

    test('repairMissingParticipantEmails reports what it fixed', () async {
      await seedEvent();
      await seedBlankRow('alex');
      await seedBlankRow('sam');
      await seedProfile('alex', 'alexfriedman999@gmail.com');
      // `sam` has no profile: nothing to repair with, so it is left alone.

      final repaired = await repo.repairMissingParticipantEmails('e1', [
        Participant.fromMap('alex', {'userId': 'alex', 'email': ''}),
        Participant.fromMap('sam', {'userId': 'sam', 'email': ''}),
      ]);

      expect(repaired, 1);
      expect(
        (await db
                .collection('events')
                .doc('e1')
                .collection('participants')
                .doc('alex')
                .get())
            .data()!['email'],
        'alexfriedman999@gmail.com',
      );
    });

    test('rows that already have an email are left untouched', () async {
      await seedEvent();
      await db
          .collection('events')
          .doc('e1')
          .collection('participants')
          .doc('alex')
          .set({
        'userId': 'alex',
        'email': 'original@example.com',
        'role': 'editor',
        'inviteStatus': 'accepted',
      });
      await seedProfile('alex', 'different@example.com');

      final people = await repo.watchParticipants('e1').first;
      expect(people.single.email, 'original@example.com');
    });

    test('a circle placeholder is never hydrated as a person', () async {
      await seedEvent();
      await db
          .collection('events')
          .doc('e1')
          .collection('participants')
          .doc('circle:c1')
          .set({
        'kind': 'circle',
        'circleId': 'c1',
        'circleName': 'Friends',
        'email': '',
        'role': 'viewer',
        'inviteStatus': 'accepted',
      });

      final people = await repo.watchParticipants('e1').first;
      expect(people.single.isCircle, isTrue);
      expect(people.single.label, 'Friends');
      expect(people.single.email, isEmpty);
    });
  });
}
