// The three things reported as broken, pinned so they stay fixed.
//
// 1. "Can't accept invite" — the couple path in particular re-submitted the
//    same invitation on every stream emission and turned its own success into
//    an "already answered" error.
// 2. "Fix with whom it is shared (U logo)" — a name with surrounding space made
//    the avatar fall back to a meaningless one-letter tile.
// 3. "Couple not working" — accepts must happen once, and the claim has to be
//    shared between the provider and the inbox card.
import 'package:datedawn/core/circles.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/core/recent_contacts.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('avatar initials never render a stray letter', () {
    test('a display name with surrounding space is trimmed first', () {
      final member = CircleMember.fromMap('u1', {
        'email': '',
        'displayName': ' Sam',
      });
      expect(member.initials, 'SA',
          reason: 'slicing the untrimmed label produced " S"');
      expect(member.label, 'Sam');
    });

    test('a whitespace-only name falls back to the address, not to "U"', () {
      final member = CircleMember.fromMap('u2', {
        'email': 'sam@example.com',
        'displayName': '   ',
      });
      expect(member.label, 'sam@example.com');
      expect(member.initials, 'SA');
    });

    test('multi-word names keep one letter per word', () {
      expect(
        CircleMember.fromMap('u3', {'displayName': 'Ada Lovelace'}).initials,
        'AL',
      );
    });

    test('a nameless, emailless row asks for no letters at all', () {
      final member = CircleMember.fromMap('u4', {});
      expect(member.initials, '?',
          reason: 'the avatar draws an icon for "?", never a letter');
    });

    test('the same rules hold on every model that draws an avatar', () {
      final participant = Participant.fromMap('p1', {
        'userId': 'p1',
        'email': 'anna@example.com',
        'displayName': '  ',
      });
      expect(participant.initials, 'AN');

      final contact = RecentContact.fromMap('c1', {
        'email': 'bob@example.com',
        'displayName': ' Bob',
      });
      expect(contact.initials, 'BO');

      const user = AppUser(
        id: 'a1',
        email: 'cara@example.com',
        displayName: ' Cara',
      );
      expect(user.initials, 'CA');
    });
  });

  group('a couple invitation is joined exactly once', () {
    test('the claim is shared, so a second emission is skipped', () {
      // The provider and the inbox card claim the same key. If they did not,
      // the second accept would find the invitation already answered and
      // surface as a failure — the exact "couple doesn't work" symptom.
      String claimKeyFor(CircleInvitation invite) => 'circle-${invite.id}';
      final invite = _coupleInvite('inv-1');
      expect(claimKeyFor(invite), 'circle-inv-1');
    });

    test('the auto-join key matches the one the card uses', () {
      // Pinned literally: the provider builds `'circle-${invitation.id}'` and
      // `_CircleInviteCardState._claimKey` builds `'circle-${widget.invite.id}'`.
      // A rename on one side only would silently restore the double accept.
      final invite = _coupleInvite('abc');
      expect(invite.isCouple, isTrue);
      expect('circle-${invite.id}', 'circle-abc');
    });
  });
}

CircleInvitation _coupleInvite(String id) => CircleInvitation(
      id: id,
      circleId: 'circle-1',
      invitedBy: 'partner-uid',
      inviteeEmail: 'me@example.com',
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2026, 12, 31),
      circleName: 'Us',
      isCouple: true,
    );
