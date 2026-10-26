import 'package:flutter_test/flutter_test.dart';
import 'package:datedawn/core/models.dart';

void main() {
  group('ParticipantRole', () {
    test('maps wire values, defaulting to viewer', () {
      expect(ParticipantRole.fromWire('admin'), ParticipantRole.admin);
      expect(ParticipantRole.fromWire('editor'), ParticipantRole.editor);
      expect(ParticipantRole.fromWire('viewer'), ParticipantRole.viewer);
      expect(ParticipantRole.fromWire('nonsense'), ParticipantRole.viewer);
      expect(ParticipantRole.fromWire(null), ParticipantRole.viewer);
    });

    test('separates editing from managing', () {
      expect(ParticipantRole.admin.canEdit, isTrue);
      expect(ParticipantRole.admin.canManage, isTrue);
      expect(ParticipantRole.editor.canEdit, isTrue);
      expect(ParticipantRole.editor.canManage, isFalse);
      expect(ParticipantRole.viewer.canEdit, isFalse);
      expect(ParticipantRole.viewer.canManage, isFalse);
    });
  });

  group('CountdownEvent permissions', () {
    final event = CountdownEvent(
      id: 'e1',
      title: 'Wedding',
      description: '',
      at: DateTime(2030, 1, 1),
      createdBy: 'owner',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      participants: const [
        Participant(
          userId: 'owner',
          email: 'owner@example.com',
          role: ParticipantRole.admin,
          inviteStatus: InviteStatus.accepted,
        ),
        Participant(
          userId: 'editor',
          email: 'editor@example.com',
          role: ParticipantRole.editor,
          inviteStatus: InviteStatus.accepted,
        ),
        Participant(
          userId: 'viewer',
          email: 'viewer@example.com',
          role: ParticipantRole.viewer,
          inviteStatus: InviteStatus.accepted,
        ),
      ],
    );

    test('the creator is always an admin, even without a participant row', () {
      final bare = CountdownEvent(
        id: 'e2',
        title: 'Launch',
        description: '',
        at: DateTime(2030, 1, 1),
        createdBy: 'owner',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(bare.roleFor('owner'), ParticipantRole.admin);
      expect(bare.canManage('owner'), isTrue);
    });

    test('editors can edit but not manage', () {
      expect(event.canEdit('editor'), isTrue);
      expect(event.canManage('editor'), isFalse);
    });

    test('viewers can do neither', () {
      expect(event.canEdit('viewer'), isFalse);
      expect(event.canManage('viewer'), isFalse);
    });

    test('a stranger is treated as a viewer, never an editor', () {
      expect(event.roleFor('stranger'), ParticipantRole.viewer);
      expect(event.canEdit('stranger'), isFalse);
      expect(event.canEdit(null), isFalse);
    });

    test('others() excludes the signed-in user', () {
      expect(event.others('owner').map((p) => p.userId), ['editor', 'viewer']);
      expect(event.others(null).length, 3);
    });
  });

  group('CountdownEvent.fromDoc', () {
    test('reads participants and notes out of the document map', () {
      final event = CountdownEvent.fromDoc('e1', {
        'title': 'Trip home',
        'description': 'Long overdue',
        'at': DateTime(2030, 5, 1),
        'createdBy': 'owner',
        'createdAt': DateTime(2026, 1, 1),
        'updatedAt': DateTime(2026, 1, 2),
        'participants': {
          'owner': {
            'email': 'owner@example.com',
            'role': 'admin',
            'inviteStatus': 'accepted',
          },
        },
        'notes': [
          {
            'id': 'n1',
            'userId': 'owner',
            'text': 'Book the flights',
            'createdAt': DateTime(2026, 1, 3),
            'updatedAt': DateTime(2026, 1, 3),
          },
        ],
      });

      expect(event.title, 'Trip home');
      expect(event.participants.length, 1);
      expect(event.participants.first.role, ParticipantRole.admin);
      expect(event.notes.length, 1);
      expect(event.notes.first.text, 'Book the flights');
    });

    test('survives a sparse document without throwing', () {
      final event = CountdownEvent.fromDoc('e1', {});
      expect(event.title, 'Untitled');
      expect(event.description, '');
      expect(event.participants, isEmpty);
      expect(event.notes, isEmpty);
    });

    test('parses ISO string dates as well as Timestamps', () {
      final event = CountdownEvent.fromDoc('e1', {
        'title': 'Seeded',
        'at': '2030-05-01T10:00:00.000Z',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'createdBy': 'owner',
      });
      expect(event.at.year, 2030);
    });
  });

  group('Participant row shape', () {
    // The bug these pin: `watchEvents` discovers every countdown shared with
    // you through a collection-group query on the participant row's `userId`
    // FIELD — `collectionGroup('participants').where('userId', isEqualTo: uid)`.
    // A document id is not queryable that way. Rows were written with the uid
    // only as the document id, so the field was absent, the query never matched
    // and the countdown never reached the person it was shared with. That is
    // why accepting an invitation "succeeded" (the snackbar fired) while the
    // countdown stayed missing, and why a couple circle appeared not to share.
    const participant = Participant(
      userId: 'u1',
      email: 'sam@example.com',
      role: ParticipantRole.editor,
      inviteStatus: InviteStatus.accepted,
    );

    test('toMap carries userId, which the visibility query filters on', () {
      expect(participant.toMap()['userId'], 'u1');
    });

    test('fromMap reads the body userId when the document id is empty', () {
      final parsed = Participant.fromMap('', {
        'userId': 'u1',
        'email': 'sam@example.com',
        'role': 'editor',
        'inviteStatus': 'accepted',
      });
      expect(parsed.userId, 'u1');
    });

    test('the document id wins when both are present', () {
      // The id is the authority — a stale body field must not shadow it.
      final parsed = Participant.fromMap('doc-id', {
        'userId': 'stale',
        'email': 'sam@example.com',
        'role': 'editor',
        'inviteStatus': 'accepted',
      });
      expect(parsed.userId, 'doc-id');
    });

    test('round-trips through toMap and fromMap', () {
      final parsed = Participant.fromMap('u1', participant.toMap());
      expect(parsed.userId, participant.userId);
      expect(parsed.role, participant.role);
      expect(parsed.inviteStatus, participant.inviteStatus);
    });
  });

  group('Participant.initials', () {
    test('uses two initials from a display name', () {
      const p = Participant(
        userId: 'u',
        email: 'alex.rivera@example.com',
        role: ParticipantRole.viewer,
        inviteStatus: InviteStatus.accepted,
        displayName: 'Alex Rivera',
      );
      expect(p.initials, 'AR');
    });

    test('falls back to the email when there is no name', () {
      const p = Participant(
        userId: 'u',
        email: 'sam@example.com',
        role: ParticipantRole.viewer,
        inviteStatus: InviteStatus.accepted,
      );
      expect(p.initials, 'SA');
    });

    test('never returns an empty string', () {
      // "?" is the explicit "nobody to name" marker: `UserAvatar` turns it into
      // a person icon. A literal "U" read as a real initial.
      const p = Participant(
        userId: 'u',
        email: '',
        role: ParticipantRole.viewer,
        inviteStatus: InviteStatus.accepted,
      );
      expect(p.initials, '?');
      expect(p.initials, isNot(''));
    });
  });

  group('Invitation', () {
    test('normalises the invitee email to lowercase', () {
      final invite = Invitation.fromDoc('i1', {
        'eventId': 'e1',
        'invitedBy': 'owner',
        'inviteeEmail': 'Friend@Example.COM',
        'role': 'editor',
        'status': 'pending',
        'createdAt': DateTime(2026, 1, 1),
        'expiresAt': DateTime(2099, 1, 1),
      });

      expect(invite.inviteeEmail, 'friend@example.com');
      expect(invite.role, ParticipantRole.editor);
      expect(invite.isExpired, isFalse);
    });

    test('reports expiry for a date in the past', () {
      final invite = Invitation.fromDoc('i1', {
        'inviteeEmail': 'a@b.com',
        'expiresAt': DateTime(2020, 1, 1),
      });
      expect(invite.isExpired, isTrue);
    });
  });
}
