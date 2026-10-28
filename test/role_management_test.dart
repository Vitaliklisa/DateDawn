// Changing an existing collaborator's role.
//
// The report: on a countdown's edit screen each collaborator row showed their
// role, but the row's three-dot menu offered only Block. There was no way to
// promote a viewer to editor, and the invite form's role selector only ever set
// the role of a *new* invitation.
//
// These pin the policy (one role system: `ParticipantRole`), the write, and the
// menu itself — including the cases that must stay refused: changing your own
// role, granting above your own, and touching the creator.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/core/theme.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/screens/event_editor_screen.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Participant _person(
  String id,
  ParticipantRole role, {
  InviteStatus status = InviteStatus.accepted,
  String? name,
}) =>
    Participant(
      userId: id,
      email: '$id@example.com',
      role: role,
      inviteStatus: status,
      displayName: name ?? id,
    );

CountdownEvent _event(List<Participant> participants) => CountdownEvent(
      id: 'e1',
      title: 'Trip',
      description: '',
      at: DateTime(2030, 1, 1),
      createdBy: 'owner',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      participants: participants,
    );

/// The participant rows a countdown always has: an owner, an admin who is not
/// the owner, an editor, a viewer, and someone still waiting to answer.
final _rows = [
  _person('owner', ParticipantRole.admin),
  _person('admin', ParticipantRole.admin),
  _person('editor', ParticipantRole.editor),
  _person('viewer', ParticipantRole.viewer),
  _person('invited', ParticipantRole.viewer, status: InviteStatus.pending),
];

void main() {
  group('checkRoleChange', () {
    final event = _event(_rows);
    Participant row(String id) => event.participants.firstWhere((p) => p.userId == id);

    test('an admin can change a viewer to editor or admin', () {
      for (final role in [ParticipantRole.editor, ParticipantRole.admin]) {
        expect(
          event
              .checkRoleChange(
                  actorId: 'admin', target: row('viewer'), role: role)
              .allowed,
          isTrue,
          reason: 'admin -> $role',
        );
      }
      // …and setting the role they already have is not a change.
      expect(
        event
            .checkRoleChange(
                actorId: 'admin', target: row('viewer'), role: ParticipantRole.viewer)
            .allowed,
        isFalse,
      );
    });

    test('an admin can change another admin (demote or promote)', () {
      expect(
        event
            .checkRoleChange(
                actorId: 'admin', target: row('owner'), role: ParticipantRole.editor)
            .allowed,
        isFalse,
        reason: 'the creator is protected before anyone else is considered',
      );
      final otherAdmin = _person('other-admin', ParticipantRole.admin);
      final withTwoAdmins = _event([..._rows, otherAdmin]);
      expect(
        withTwoAdmins
            .checkRoleChange(
                actorId: 'admin', target: otherAdmin, role: ParticipantRole.viewer)
            .allowed,
        isTrue,
        reason: 'admins outrank each other; the creator is the protected one',
      );
    });

    test('the creator may change any collaborator', () {
      expect(
        event
            .checkRoleChange(
                actorId: 'owner', target: row('admin'), role: ParticipantRole.viewer)
            .allowed,
        isTrue,
      );
    });

    test('the creator keeps ownership: their role cannot be changed', () {
      final check = event.checkRoleChange(
          actorId: 'admin', target: row('owner'), role: ParticipantRole.viewer);
      expect(check.allowed, isFalse);
      expect(check.message, contains('ownership'));
    });

    test('nobody may change their own role, not even the creator', () {
      expect(
        event
            .checkRoleChange(
                actorId: 'admin', target: row('admin'), role: ParticipantRole.viewer)
            .allowed,
        isFalse,
      );
      expect(
        event
            .checkRoleChange(
                actorId: 'owner', target: row('owner'), role: ParticipantRole.editor)
            .allowed,
        isFalse,
      );
      expect(
        event.assignableRolesFor(actorId: 'admin', target: row('admin')),
        isEmpty,
      );
    });

    test('an editor cannot manage people, and cannot grant admin', () {
      expect(
        event
            .checkRoleChange(
                actorId: 'editor', target: row('viewer'), role: ParticipantRole.viewer)
            .allowed,
        isFalse,
      );
      expect(
        event.assignableRolesFor(actorId: 'editor', target: row('viewer')),
        isEmpty,
      );
    });

    test('a viewer cannot change anyone', () {
      expect(
        event
            .checkRoleChange(
                actorId: 'viewer', target: row('editor'), role: ParticipantRole.viewer)
            .allowed,
        isFalse,
      );
    });

    test('setting the role someone already has is not a change', () {
      expect(
        event
            .checkRoleChange(
                actorId: 'admin', target: row('viewer'), role: ParticipantRole.viewer)
            .allowed,
        isFalse,
      );
    });

    test('a circle placeholder is not a person', () {
      const circle = Participant(
        userId: 'circle:c1',
        email: '',
        role: ParticipantRole.viewer,
        inviteStatus: InviteStatus.pending,
        kind: ParticipantKind.circle,
      );
      final withCircle = _event([..._rows, circle]);
      expect(
        withCircle
            .checkRoleChange(
                actorId: 'admin', target: circle, role: ParticipantRole.editor)
            .allowed,
        isFalse,
      );
    });

    test('assignableRolesFor offers exactly the roles the menu shows', () {
      expect(
        event
            .assignableRolesFor(actorId: 'admin', target: row('viewer'))
            .map((r) => r.label),
        ['Editor', 'Admin'],
        reason: 'the two they could be moved to; not the one they have',
      );
      expect(
        event
            .assignableRolesFor(actorId: 'admin', target: row('editor'))
            .map((r) => r.label),
        ['Viewer', 'Admin'],
        reason: 'a demotion to viewer is offered as well',
      );
      expect(
        event
            .assignableRolesFor(actorId: 'admin', target: row('editor'))
            .map((r) => r.label),
        ['Viewer', 'Admin'],
        reason: 'the role they already have is not offered as a change',
      );
      // The creator's row is never offered, and neither is your own.
      expect(event.assignableRolesFor(actorId: 'admin', target: row('owner')),
          isEmpty);
      expect(event.assignableRolesFor(actorId: 'owner', target: row('owner')),
          isEmpty);
    });
  });

  group('updateParticipantRole', () {
    late FakeFirebaseFirestore db;
    late EventRepository repo;

    setUp(() async {
      db = FakeFirebaseFirestore();
      repo = EventRepository(firestore: db);
      await db.collection('events').doc('e1').set({
        'title': 'Trip',
        'createdBy': 'owner',
        'at': Timestamp.fromDate(DateTime(2030)),
      });
      for (final row in _rows) {
        await db
            .collection('events')
            .doc('e1')
            .collection('participants')
            .doc(row.userId)
            .set({
          'userId': row.userId,
          'email': row.email,
          'displayName': row.displayName,
          'role': row.role.name,
          'inviteStatus': row.inviteStatus.name,
        });
      }
    });

    Future<String?> storedRole(String userId) async => (await db
            .collection('events')
            .doc('e1')
            .collection('participants')
            .doc(userId)
            .get())
        .data()?['role'] as String?;

    test('an admin promotes a viewer, and the change persists', () async {
      await repo.updateParticipantRole(
        eventId: 'e1',
        actorId: 'admin',
        participant: _rows[3],
        role: ParticipantRole.editor,
      );

      expect(await storedRole('viewer'), 'editor');

      // …and it is the role that grants access: the editor can now edit, but
      // still cannot manage people.
      final refreshed = (await db
              .collection('events')
              .doc('e1')
              .collection('participants')
              .get())
          .docs
          .map((d) => Participant.fromMap(d.id, d.data()))
          .toList();
      expect(refreshed.firstWhere((p) => p.userId == 'viewer').role.canEdit,
          isTrue);
      expect(refreshed.firstWhere((p) => p.userId == 'viewer').role.canManage,
          isFalse);
    });

    test('a role change keeps the rest of the row intact', () async {
      await repo.updateParticipantRole(
        eventId: 'e1',
        actorId: 'owner',
        participant: _rows[3],
        role: ParticipantRole.admin,
      );

      final data = (await db
              .collection('events')
              .doc('e1')
              .collection('participants')
              .doc('viewer')
              .get())
          .data()!;
      expect(data['email'], 'viewer@example.com');
      expect(data['displayName'], 'viewer');
      expect(data['inviteStatus'], 'accepted');
    });

    test('refuses to change your own role', () async {
      await expectLater(
        repo.updateParticipantRole(
          eventId: 'e1',
          actorId: 'admin',
          participant: _rows[1],
          role: ParticipantRole.viewer,
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(await storedRole('admin'), 'admin');
    });

    test('refuses to touch the creator', () async {
      await expectLater(
        repo.updateParticipantRole(
          eventId: 'e1',
          actorId: 'admin',
          participant: _rows[0],
          role: ParticipantRole.viewer,
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(await storedRole('owner'), 'admin');
    });

    test('refuses an editor\'s attempt to manage people', () async {
      await expectLater(
        repo.updateParticipantRole(
          eventId: 'e1',
          actorId: 'editor',
          participant: _rows[3],
          role: ParticipantRole.admin,
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(await storedRole('viewer'), 'viewer');
    });

    test('refuses a viewer\'s attempt to promote themselves', () async {
      await expectLater(
        repo.updateParticipantRole(
          eventId: 'e1',
          actorId: 'viewer',
          participant: _rows[3],
          role: ParticipantRole.admin,
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(await storedRole('viewer'), 'viewer');
    });

    test('a demoted admin cannot hand admin back to someone else', () async {
      // The owner demotes the admin…
      await repo.updateParticipantRole(
        eventId: 'e1',
        actorId: 'owner',
        participant: _rows[1],
        role: ParticipantRole.viewer,
      );
      expect(await storedRole('admin'), 'viewer');

      // …and the demoted admin can no longer grant anything.
      await expectLater(
        repo.updateParticipantRole(
          eventId: 'e1',
          actorId: 'admin',
          participant: _rows[3],
          role: ParticipantRole.admin,
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(await storedRole('viewer'), 'viewer');
    });

    test('reads the real role from the database, not the stale model', () async {
      // The screen still believes `viewer` is a viewer; the database says they
      // were just promoted to editor. An admin may still change an editor, but
      // the check must measure against 'editor', so demoting them to viewer is
      // a genuine change…
      await db
          .collection('events')
          .doc('e1')
          .collection('participants')
          .doc('viewer')
          .update({'role': 'editor'});

      await repo.updateParticipantRole(
        eventId: 'e1',
        actorId: 'admin',
        participant: _rows[3],
        role: ParticipantRole.viewer,
      );
      expect(await storedRole('viewer'), 'viewer');
    });
  });

  group('the collaborator row menu', () {
    Future<void> pumpEditor(
      WidgetTester tester,
      String actorId,
    ) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final event = _event(_rows);
      final router = GoRouter(
        initialLocation: '/event/e1/edit',
        routes: [
          GoRoute(
            path: '/event/e1/edit',
            builder: (context, state) => EventEditorScreen(event: event),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              AppUser(id: actorId, email: '$actorId@example.com'),
            ),
            participantsProvider('e1')
                .overrideWith((ref) => Stream.value(_rows)),
            recentContactsProvider.overrideWith((ref) => Stream.value(const [])),
            circlesProvider.overrideWith((ref) => Stream.value(const [])),
            // The preview strip ticks once a second in the app; a periodic
            // timer in a widget test is a leak. One fixed instant is all this
            // screen needs.
            clockProvider.overrideWith(
              (ref) => Stream.value(DateTime(2026, 1, 1)),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.build(brightness: Brightness.dark),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Unmount before the test ends, so nothing is still listening (and no
      // timer is still scheduled) when the framework checks for leaks.
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    /// Taps the ⋮ on the collaborator row whose name is [displayName].
    ///
    /// The rows are in the order of [_rows], and each has exactly one menu, so
    /// the menu's index is the row's index — which is far steadier than an
    /// ancestor walk through the dialog layout.
    /// Taps the ⋮ on the collaborator row whose name is [displayName].
    ///
    /// Every person row except the viewer's own gets a menu (the policy refuses
    /// a self role change and self-blocking, so there is nothing to offer on
    /// it), so the menu's index is the row's index minus any self row above it.
    Future<void> openMenuFor(
      WidgetTester tester,
      String actorId,
      String displayName,
    ) async {
      final rows = [
        for (final p in _rows)
          if (p.userId != actorId) p,
      ];
      final index =
          rows.indexWhere((p) => (p.displayName ?? p.email) == displayName);
      expect(index, isNonNegative, reason: 'no menu row named $displayName');
      final menus = find.byTooltip('More actions');
      expect(menus, findsNWidgets(rows.length));
      await tester.tap(menus.at(index));
      await tester.pumpAndSettle();
    }

    testWidgets('an admin sees Change role, Remove and Block on a collaborator',
        (tester) async {
      await pumpEditor(tester, 'admin');
      // `invited` is the row still awaiting an answer — the one an admin can
      // remove. (`viewer` is already accepted: the useful actions there are a
      // role change or a block, not removal.)
      await openMenuFor(tester, 'admin', 'invited');

      expect(find.text('Change role'), findsOneWidget);
      expect(find.text('Block'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('the Change role sheet offers Viewer, Editor and Admin',
        (tester) async {
      await pumpEditor(tester, 'admin');
      await openMenuFor(tester, 'admin', 'viewer');
      await tester.tap(find.text('Change role'));
      await tester.pumpAndSettle();

      expect(find.text('Change role for viewer'), findsOneWidget);
      // One line per role the admin may grant — all three, since a viewer can
      // be moved to either of the others.
      for (final label in ['Editor', 'Admin']) {
        expect(
          find.descendant(
              of: find.byType(BottomSheet), matching: find.text(label)),
          findsOneWidget,
          reason: '$label should be offered',
        );
      }
      // The role they already hold is shown as the current selection, not as a
      // change to make.
      expect(
        find.textContaining('currently have viewer access'),
        findsOneWidget,
      );
      // Tapping one writes the change and closes the sheet.
      await tester.tap(find.descendant(
          of: find.byType(BottomSheet), matching: find.text('Editor')));
      await tester.pumpAndSettle();
      expect(find.text('Change role for viewer'), findsNothing);
    });

    testWidgets('an editor has no management actions', (tester) async {
      await pumpEditor(tester, 'editor');
      await openMenuFor(tester, 'editor', 'viewer');

      expect(find.text('Change role'), findsNothing);
      expect(find.text('Block'), findsOneWidget,
          reason: 'blocking stays available to everyone');
      expect(find.text('Remove'), findsNothing);
    });

    testWidgets('the creator\'s row offers no Change role', (tester) async {
      await pumpEditor(tester, 'admin');
      await openMenuFor(tester, 'admin', 'owner');

      expect(find.text('Change role'), findsNothing);
      expect(find.text('Block'), findsOneWidget);
    });
  });
}
