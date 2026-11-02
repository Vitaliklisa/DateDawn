import 'package:datedawn/core/models.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:datedawn/widgets/block_user.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('blocking and tapping Undo clears the blocked list immediately',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final firestore = FakeFirebaseFirestore();
    const user = AppUser(id: 'me', email: 'me@example.com');
    const target = Participant(
      userId: 'target',
      email: 'target@example.com',
      displayName: 'Target',
      role: ParticipantRole.viewer,
      inviteStatus: InviteStatus.accepted,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          eventRepositoryProvider.overrideWithValue(
            EventRepository(firestore: firestore),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final blocked = ref.watch(blockedUsersProvider);
                return Column(
                  children: [
                    TextButton(
                      onPressed: () => showBlockUserSheet(
                        context,
                        participant: target,
                        eventId: 'event-1',
                      ),
                      child: const Text('Block target'),
                    ),
                    blocked.when(
                      data: (people) => Text(
                        people.isEmpty
                            ? 'Nobody is blocked'
                            : people.map((person) => person.label).join(', '),
                      ),
                      error: (error, _) => Text('Blocked list error: $error'),
                      loading: () => const Text('Loading blocked list'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Block target'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    expect(find.text('Target'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Nobody is blocked'), findsOneWidget);
  });
}
