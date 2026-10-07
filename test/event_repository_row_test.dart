import 'package:flutter_test/flutter_test.dart';
import 'package:datedawn/core/circles.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/services/event_repository.dart';

/// Row-parsing tests for the Supabase (Postgres) data layer.
///
/// The repository's queries and its authorisation both live in Postgres: the
/// row-level-security policies in `supabase/schema.sql` decide which rows each
/// person may read or write, and the client cannot influence that by
/// construction. So the parts worth testing offline are the translation from a
/// Postgres row (snake_case, text timestamps, `null`s) into the app's models,
/// and the guard rails that produce a readable message before a pointless round
/// trip. Those are covered here; the queries themselves are exercised by the
/// app against the real database.
void main() {
  group('CountdownEvent.fromRow', () {
    test('reads a full events row', () {
      final event = CountdownEvent.fromRow({
        'id': 'e1',
        'title': 'Wedding',
        'description': 'The day',
        'at': '2030-06-01T16:00:00Z',
        'created_by': 'alex',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
        'deleted_at': null,
      });

      expect(event.id, 'e1');
      expect(event.title, 'Wedding');
      expect(event.createdBy, 'alex');
      expect(event.deletedAt, isNull);
      expect(event.at.toUtc(), DateTime.utc(2030, 6, 1, 16));
    });

    test('tolerates a sparse row without crashing', () {
      final event = CountdownEvent.fromRow({'id': 'e1'});

      expect(event.id, 'e1');
      expect(event.title, 'Untitled');
      expect(event.description, '');
      expect(event.createdBy, '');
    });

    test('reads a soft delete', () {
      final event = CountdownEvent.fromRow({
        'id': 'e1',
        'deleted_at': '2026-03-01T10:00:00Z',
      });

      expect(event.deletedAt, isNotNull);
    });
  });

  group('Participant.fromRow', () {
    test('maps role and invite status from their wire names', () {
      final participant = Participant.fromRow({
        'user_id': 'sam',
        'email': 'Sam@Example.COM',
        'role': 'editor',
        'invite_status': 'accepted',
        'display_name': 'Sam Taylor',
      });

      expect(participant.userId, 'sam');
      expect(participant.email, 'sam@example.com');
      expect(participant.role, ParticipantRole.editor);
      expect(participant.inviteStatus, InviteStatus.accepted);
      expect(participant.initials, 'ST');
    });

    test('defaults unknown values to the safe end of the range', () {
      final participant = Participant.fromRow({
        'user_id': 'sam',
        'role': 'something-new',
        'invite_status': 'something-new',
      });

      expect(participant.role, ParticipantRole.viewer);
      expect(participant.inviteStatus, InviteStatus.pending);
    });
  });

  group('Invitation.fromRow', () {
    test('reads an invitations row', () {
      final invite = Invitation.fromRow({
        'id': 'i1',
        'event_id': 'e1',
        'invited_by': 'alex',
        'invitee_email': 'Sam@Example.COM',
        'role': 'viewer',
        'status': 'pending',
        'event_title': 'Trip',
        'expires_at': '2099-01-01T00:00:00Z',
      });

      expect(invite.eventId, 'e1');
      expect(invite.inviteeEmail, 'sam@example.com');
      expect(invite.status, InviteStatus.pending);
      expect(invite.isExpired, isFalse);
    });
  });

  group('Circle.fromRow', () {
    test('seeds the owner as a member, since Postgres stores membership apart',
        () {
      final circle = Circle.fromRow({
        'id': 'c1',
        'name': 'Us',
        'owner_id': 'alex',
        'is_couple': true,
        'emoji': '💞',
      });

      expect(circle.name, 'Us');
      expect(circle.isCouple, isTrue);
      expect(circle.ownerId, 'alex');
      expect(circle.isOwner('alex'), isTrue);
      // The owner must count as a member or the circle would be invisible.
      expect(circle.contains('alex'), isTrue);
    });
  });

  group('CircleMember.fromRow', () {
    test('derives ownership from the role column', () {
      final owner = CircleMember.fromRow({
        'user_id': 'alex',
        'email': 'alex@example.com',
        'role': 'owner',
      });
      final member = CircleMember.fromRow({
        'user_id': 'sam',
        'email': 'sam@example.com',
        'role': 'member',
      });

      expect(owner.isOwner, isTrue);
      expect(member.isOwner, isFalse);
    });
  });

  group('InvitationResponse.fromRow', () {
    test('builds the sentence the notifications list shows', () {
      final response = InvitationResponse.fromRow({
        'id': 'r1',
        'recipient_id': 'alex',
        'event_id': 'e1',
        'event_title': 'Trip home',
        'responder_email': 'sam@example.com',
        'responder_name': 'Sam Taylor',
        'accepted': true,
        'is_read': false,
        'responded_at': '2026-01-01T00:00:00Z',
      });

      expect(response.message, 'Sam Taylor joined “Trip home”.');
      expect(response.read, isFalse);
    });
  });

  group('self-invite guard', () {
    test('the message is professional and shared by both flows', () {
      // Asserted by value so a future edit cannot quietly reintroduce an
      // unprofessional string.
      expect(cannotInviteSelfMessage, isNot(contains('lol')));
      expect(cannotInviteSelfMessage, contains('cannot invite yourself'));
    });
  });
}
