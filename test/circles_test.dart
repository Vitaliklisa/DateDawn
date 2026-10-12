import 'package:flutter_test/flutter_test.dart';
import 'package:datedawn/core/circles.dart';
import 'package:datedawn/core/models.dart';

/// A fixed instant, so no assertion depends on the date the suite runs.
/// `DateTime` has no const constructor, so this is a plain `final`.
final _epoch = DateTime(2026, 1, 1);

void main() {
  group('Circle membership', () {
    final circle = Circle(
      id: 'c1',
      name: 'Family',
      ownerId: 'alex',
      createdAt: _epoch,
      memberIds: const ['alex', 'sam'],
    );

    test('contains the owner and every listed member', () {
      expect(circle.contains('alex'), isTrue);
      expect(circle.contains('sam'), isTrue);
    });

    test('does not contain a stranger or a null user', () {
      expect(circle.contains('stranger'), isFalse);
      expect(circle.contains(null), isFalse);
    });

    test('only the owner counts as owner', () {
      expect(circle.isOwner('alex'), isTrue);
      expect(circle.isOwner('sam'), isFalse);
    });
  });

  group('Circle.fromDoc', () {
    test('reads memberIds and the couple flag', () {
      final circle = Circle.fromDoc('c1', {
        'name': 'Us',
        'ownerId': 'alex',
        'isCouple': true,
        'emoji': '💞',
        'memberIds': ['alex', 'sam'],
        'createdAt': DateTime(2026, 1, 1),
      });

      expect(circle.name, 'Us');
      expect(circle.isCouple, isTrue);
      expect(circle.emoji, '💞');
      expect(circle.memberIds, ['alex', 'sam']);
    });

    test('defaults safely on a sparse document', () {
      final circle = Circle.fromDoc('c1', {});
      expect(circle.name, 'Circle');
      expect(circle.isCouple, isFalse);
      expect(circle.memberIds, isEmpty);
      expect(circle.contains('alex'), isFalse);
    });

    test('ignores non-string entries in memberIds', () {
      final circle = Circle.fromDoc('c1', {
        'memberIds': ['alex', 42, null],
      });
      expect(circle.memberIds, ['alex']);
    });
  });

  group('CircleMember', () {
    test('prefers the display name and derives initials from it', () {
      const member = CircleMember(
        userId: 'u1',
        email: 'sam.taylor@example.com',
        displayName: 'Sam Taylor',
      );
      expect(member.label, 'Sam Taylor');
      expect(member.initials, 'ST');
    });

    test('falls back to the email and stays non-empty', () {
      const member = CircleMember(userId: 'u1', email: 'sam@example.com');
      expect(member.label, 'sam@example.com');
      expect(member.initials, 'SA');

      const blank = CircleMember(userId: 'u2', email: '');
      expect(blank.initials, 'U');
    });
  });

  group('CircleInvitation', () {
    test('normalises the invitee email to lowercase', () {
      final invite = CircleInvitation.fromDoc('i1', {
        'circleId': 'c1',
        'invitedBy': 'alex',
        'inviteeEmail': 'Sam@Example.COM',
        'circleName': 'Family',
        'expiresAt': DateTime(2099, 1, 1),
      });

      expect(invite.inviteeEmail, 'sam@example.com');
      expect(invite.status, InviteStatus.pending);
      expect(invite.isExpired, isFalse);
    });

    test('reports expiry for a past date', () {
      final invite = CircleInvitation.fromDoc('i1', {
        'expiresAt': DateTime(2020, 1, 1),
      });
      expect(invite.isExpired, isTrue);
    });
  });

  group('InvitationResponse', () {
    final accepted = InvitationResponse(
      id: 'r1',
      recipientId: 'alex',
      eventId: 'e1',
      eventTitle: 'Trip home',
      responderEmail: 'sam@example.com',
      responderName: 'Sam Taylor',
      accepted: true,
      respondedAt: _epoch,
    );

    test('announces an acceptance naming the responder and the countdown', () {
      expect(accepted.message, 'Sam Taylor joined “Trip home”.');
    });

    test('announces a decline', () {
      final declined = InvitationResponse(
        id: 'r2',
        recipientId: 'alex',
        eventId: 'e1',
        eventTitle: 'Trip home',
        responderEmail: 'sam@example.com',
        accepted: false,
        respondedAt: _epoch,
      );
      expect(declined.message, 'sam@example.com declined “Trip home”.');
    });

    test('starts unread so it surfaces as a badge', () {
      expect(accepted.read, isFalse);
    });
  });

  group('CountdownEvent circle sharing', () {
    test('reports as shared only when there is someone or a circle on it', () {
      final base = CountdownEvent(
        id: 'e1',
        title: 'Launch',
        description: '',
        at: DateTime(2030, 1, 1),
        createdBy: 'alex',
        createdAt: _epoch,
        updatedAt: _epoch,
      );
      expect(base.isShared, isFalse);

      final shared = base.copyWith(sharedWithCircleIds: ['c1']);
      expect(shared.isShared, isTrue);
    });

    test('a legacy event with only circleId still reports its circles', () {
      // Events written before `sharedWithCircleIds` existed carry `circleId`
      // only; reading them must not silently lose the circle.
      final event = CountdownEvent.fromDoc('e1', {
        'title': 'Legacy',
        'circleId': 'c1',
        'createdBy': 'alex',
      });
      expect(event.sharedWithCircleIds, ['c1']);
    });

    test('merges circleId and sharedWithCircleIds without duplicating', () {
      final event = CountdownEvent.fromDoc('e1', {
        'title': 'Both',
        'circleId': 'c1',
        'sharedWithCircleIds': ['c1', 'c2'],
        'createdBy': 'alex',
      });
      expect(event.sharedWithCircleIds.toSet(), {'c1', 'c2'});
    });

    test('reads the denormalised circle member uids', () {
      // `sharedWithMemberIds` is what the security rule checks and what the
      // client queries to discover a circle-shared countdown. If it is not
      // parsed off the document the client would treat a shared countdown as
      // unshared, which is the shape of the "couple does not share" bug.
      final event = CountdownEvent.fromDoc('e1', {
        'title': 'Us',
        'sharedWithCircleIds': ['c1'],
        'sharedWithMemberIds': ['alex', 'sam'],
        'createdBy': 'alex',
      });
      expect(event.sharedWithMemberIds, ['alex', 'sam']);
    });

    test('defaults sharedWithMemberIds to empty on an older document', () {
      // A countdown written before the field existed must still parse, and must
      // not claim to be shared with anyone.
      final event = CountdownEvent.fromDoc('e1', {
        'title': 'Legacy',
        'sharedWithCircleIds': ['c1'],
        'createdBy': 'alex',
      });
      expect(event.sharedWithMemberIds, isEmpty);
    });

    test('ignores non-string entries in sharedWithMemberIds', () {
      final event = CountdownEvent.fromDoc('e1', {
        'sharedWithMemberIds': ['alex', 42, null],
      });
      expect(event.sharedWithMemberIds, ['alex']);
    });

    test('round-trips sharedWithMemberIds through toMap', () {
      final event = CountdownEvent.fromDoc('e1', {
        'title': 'Us',
        'sharedWithCircleIds': ['c1'],
        'sharedWithMemberIds': ['alex', 'sam'],
        'createdBy': 'alex',
      });
      final reparsed = CountdownEvent.fromDoc('e1', event.toMap());
      expect(reparsed.sharedWithMemberIds, ['alex', 'sam']);
      expect(reparsed.sharedWithCircleIds, ['c1']);
    });

    test('counts a member-shared countdown as shared', () {
      final base = CountdownEvent(
        id: 'e1',
        title: 'Us',
        description: '',
        at: DateTime(2030, 1, 1),
        createdBy: 'alex',
        createdAt: _epoch,
        updatedAt: _epoch,
      );
      expect(base.isShared, isFalse);
      expect(base.copyWith(sharedWithMemberIds: ['sam']).isShared, isTrue);
    });
  });
}
