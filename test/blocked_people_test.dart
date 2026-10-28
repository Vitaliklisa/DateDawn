// Settings → Blocked people, end to end at the data layer.
//
// The bug this pins: blocking a person wrote the row and showed "… is blocked"
// with an Undo, but the list screen sat on a spinner for ever. Three things had
// to be true for that to happen, and all three are tested here:
//
//  1. the block write actually lands where the read looks;
//  2. the read is authorised (the query is a plain field comparison, and the
//     rules no longer depend on the parent profile document);
//  3. the provider ends — data, or a visible error with a retry, never silence.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/core/theme.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/screens/blocked_people_screen.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A repository whose blocked-list stream is whatever the test hands it.
///
/// Everything else throws, so a test can never pass by accidentally reaching
/// a real Firestore. `watchBlockedUsers` returns a FRESH stream per call, like
/// the real repository: a single-subscription stream would break the moment the
/// provider re-read (which is exactly what Retry does).
///
/// `watchInvitations` is answered with an empty stream too: the inbox providers
/// read the blocked list to filter out invitations from blocked people, so a
/// container that ever builds one must be able to get past it.
class _StreamingRepository implements EventRepository {
  _StreamingRepository.factory(this._factory);

  final Stream<List<BlockedUser>> Function() _factory;

  @override
  Stream<List<BlockedUser>> watchBlockedUsers(String userId) => _factory();

  @override
  Stream<List<Invitation>> watchInvitations(String email) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// A repository that refuses the read the way a rules problem does.
class _RefusingRepository extends _StreamingRepository {
  _RefusingRepository()
      : super.factory(() => Stream.error(FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
              message: 'Missing or insufficient permissions.',
            )));
}

const _me = AppUser(id: 'me', email: 'me@example.com');

ProviderContainer _container(
  EventRepository repository, {
  Duration timeout = const Duration(minutes: 5),
}) {
  return ProviderContainer(
    overrides: [
      currentUserProvider.overrideWithValue(_me),
      eventRepositoryProvider.overrideWithValue(repository),
      blockedUsersLoadTimeoutProvider.overrideWithValue(timeout),
    ],
  );
}

/// Reads the provider the way the screen does: through a listener, so it really
/// builds and subscribes rather than being read once and torn down.
final _keepAlive = <ProviderSubscription>[];

ProviderSubscription _listen(ProviderContainer container) {
  final subscription = container.listen(blockedUsersProvider, (_, __) {});
  _keepAlive.add(subscription);
  return subscription;
}

void main() {
  tearDown(() {
    for (final subscription in _keepAlive) {
      subscription.close();
    }
    _keepAlive.clear();
  });

  group('the block write', () {
    late FakeFirebaseFirestore db;
    late EventRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = EventRepository(firestore: db);
    });

    test('is written where the list reads it, and carries the list query field',
        () async {
      await repo.blockUser(
        userId: 'me',
        targetUid: 'them',
        targetEmail: 'Them@Example.com',
        targetDisplayName: 'Them',
      );

      final row = await db
          .collection('users')
          .doc('me')
          .collection('blocked')
          .doc('them')
          .get();
      expect(row.exists, isTrue, reason: 'the block row must exist');

      final data = row.data()!;
      // The list is a filtered query (`active == true`) so the rules can
      // authorise it as a query. A row without this field is invisible.
      expect(data['active'], isTrue);
      expect(data['email'], 'them@example.com');
      expect(data['displayName'], 'Them');
      expect(data['blockedAt'], isNotNull,
          reason: 'a server timestamp resolves on the server');
    });

    test('creates the caller profile the subcollection lives under', () async {
      expect(
        (await db.collection('users').doc('me').get()).exists,
        isFalse,
        reason: 'precondition: a fresh account has no profile document',
      );

      await repo.blockUser(userId: 'me', targetUid: 'them');

      expect(
        (await db.collection('users').doc('me').get()).exists,
        isTrue,
        reason: 'a brand-new account must be able to block and then read it',
      );
    });

    test('takes the name from the target profile, not only from the caller',
        () async {
      await db.collection('users').doc('them').set({
        'email': 'them@example.com',
        'displayName': 'Sam Lee',
      });

      await repo.blockUser(
        userId: 'me',
        targetUid: 'them',
        targetEmail: 'them@example.com',
      );

      final row = await db
          .collection('users')
          .doc('me')
          .collection('blocked')
          .doc('them')
          .get();
      expect(row.data()!['displayName'], 'Sam Lee');
    });

    test('re-blocking heals a legacy row written without `active`', () async {
      // A row from an older build: it exists, it is a block, and yet the new
      // list query cannot see it.
      await db
          .collection('users')
          .doc('me')
          .collection('blocked')
          .doc('them')
          .set({'email': 'them@example.com'});

      await repo.blockUser(userId: 'me', targetUid: 'them');

      final row = await db
          .collection('users')
          .doc('me')
          .collection('blocked')
          .doc('them')
          .get();
      expect(row.data()!['active'], isTrue);
    });

    test('removes the blocked person from the caller\'s countdowns', () async {
      await db.collection('events').doc('e1').set({
        'title': 'Trip',
        'createdBy': 'me',
        'at': Timestamp.fromDate(DateTime(2030)),
      });
      await db
          .collection('events')
          .doc('e1')
          .collection('participants')
          .doc('them')
          .set({
        'userId': 'them',
        'email': 'them@example.com',
        'role': 'viewer',
        'inviteStatus': 'accepted',
      });

      await repo.blockUser(userId: 'me', targetUid: 'them');

      expect(
        (await db
                .collection('events')
                .doc('e1')
                .collection('participants')
                .doc('them')
                .get())
            .exists,
        isFalse,
        reason: 'the people list must no longer offer them',
      );
    });

    test('the list reads back what was blocked, then empties on unblock',
        () async {
      await repo.blockUser(
        userId: 'me',
        targetUid: 'them',
        targetEmail: 'them@example.com',
        targetDisplayName: 'Them',
      );

      final first = await repo.watchBlockedUsers('me').first;
      expect(first.map((p) => p.userId), ['them']);
      expect(first.single.label, 'Them');

      await repo.unblockUser(userId: 'me', targetUid: 'them');
      final second = await repo.watchBlockedUsers('me').first;
      expect(second, isEmpty, reason: 'unblock deletes the row');
    });

    test('the list stream stays live: a later block appears without a reload',
        () async {
      final emissions = <List<String>>[];
      final subscription = repo.watchBlockedUsers('me').listen(
            (people) => emissions.add(people.map((p) => p.userId).toList()),
          );
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await repo.blockUser(userId: 'me', targetUid: 'them');
      await pumpEventQueue();

      expect(emissions.last, ['them'],
          reason: 'Settings must show the person immediately after blocking');
    });

    test('a Firestore refusal arrives as an error, never as an empty list',
        () async {
      final container = _container(_RefusingRepository());
      _listen(container);

      // Wait for the provider to settle into an error, then assert on the state
      // it settled in. The exception type is preserved on `error`, rather than
      // turning into "no rows".
      final settled = Completer<void>();
      final subscription = container.listen(blockedUsersProvider, (_, __) {
        if (container.read(blockedUsersProvider).hasError &&
            !settled.isCompleted) {
          settled.complete();
        }
      });
      await settled.future.timeout(const Duration(seconds: 5));
      subscription.close();

      final error = container.read(blockedUsersProvider).error;
      expect(error, isA<FirebaseException>());
      expect((error as FirebaseException).code, 'permission-denied');
      expect(container.read(blockedUsersProvider).value, isNull,
          reason: 'an error must not be dressed up as "nobody is blocked"');
      container.dispose();
    });
  });

  group('blockedUsersProvider always leaves loading', () {
    test('a Failing stream is an error, not data', () async {
      final failing = Stream<List<BlockedUser>>.fromFuture(
        Future<List<BlockedUser>>.error(StateError('boom')),
      );
      final container = _container(_StreamingRepository.factory(() => failing));
      _listen(container);

      await expectLater(
        container.read(blockedUsersProvider.future),
        throwsA(anything),
      );
      expect(container.read(blockedUsersProvider).hasError, isTrue);
      container.dispose();
    });

    test('shows the list when the stream answers', () async {
      final container = _container(_StreamingRepository.factory(
        () => Stream.value(const [
          BlockedUser(userId: 'them', email: 'them@example.com'),
        ]),
      ));
      _listen(container);

      final people = await container.read(blockedUsersProvider.future);
      expect(people.single.userId, 'them');
      container.dispose();
    });

    test('an empty account resolves to an empty list, not a spinner', () async {
      final container = _container(
          _StreamingRepository.factory(() => Stream.value(const [])));
      _listen(container);

      expect(await container.read(blockedUsersProvider.future), isEmpty);
      container.dispose();
    });

    test('a stream that never emits becomes a retryable error', () async {
      final container = _container(
        // A fresh, silent stream per read, like the real repository's listener.
        _StreamingRepository.factory(() {
          final silent = StreamController<List<BlockedUser>>();
          addTearDown(silent.close);
          return silent.stream;
        }),
        timeout: const Duration(milliseconds: 20),
      );
      _listen(container);

      final settled = Completer<void>();
      final subscription = container.listen(blockedUsersProvider, (_, __) {
        if (container.read(blockedUsersProvider).hasError &&
            !settled.isCompleted) {
          settled.complete();
        }
      });
      await settled.future.timeout(const Duration(seconds: 5));
      subscription.close();

      final state = container.read(blockedUsersProvider);
      expect(state.error, isA<DataFailure>());
      expect(state.hasValue, isFalse,
          reason: 'silence must end in an error the UI can show, not data');
      container.dispose();
    });

    test('retry re-reads, and recovers once the read succeeds', () async {
      var reads = 0;
      final container = _container(
        _StreamingRepository.factory(() {
          reads++;
          // The first read is refused; every read after it succeeds. That is
          // the real shape of a transient failure — a rules fix, a reconnect.
          return reads == 1
              ? Stream.error(StateError('transient'))
              : Stream.value(const [
                  BlockedUser(userId: 'them', email: 'them@example.com'),
                ]);
        }),
      );
      _listen(container);

      await expectLater(
        container.read(blockedUsersProvider.future),
        throwsA(anything),
      );
      expect(container.read(blockedUsersProvider).hasError, isTrue);

      container.read(blockedUsersProvider.notifier).retry();

      final people = await container.read(blockedUsersProvider.future);
      expect(people.single.userId, 'them');
      expect(container.read(blockedUsersProvider).hasError, isFalse);
      expect(reads, greaterThanOrEqualTo(2), reason: 'Retry must re-read');
      container.dispose();
    });
  });

  group('the Blocked people screen', () {
    /// Disposes the screen (and the provider) while frames can still be pumped.
    ///
    /// Capturing the test binding first is deliberate: by the time this runs the
    /// framework has flagged the widget tree as torn down, and a bare
    /// `tester.pump` would then assert on its own bookkeeping.
    Future<void> disposeAfterPump(
        WidgetTester tester, ProviderContainer container) async {
      final binding = tester.binding;
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await binding.pump(const Duration(seconds: 1));
    }

    Future<void> pumpScreen(
        WidgetTester tester, ProviderContainer container) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/settings/blocked',
        routes: [
          GoRoute(
            path: '/settings/blocked',
            builder: (context, state) => const BlockedPeopleScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.build(brightness: Brightness.dark),
            routerConfig: router,
          ),
        ),
      );
      _listen(container);
      // A bounded pump, not `pumpAndSettle`: Riverpod schedules its own short
      // retry timers around provider rebuilds, and settling would wait on them
      // (or report them as leaked). A handful of frames is enough for the first
      // snapshot to arrive and the list to paint.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      // Let Riverpod's own timers drain before the test ends, so the framework
      // is not left asserting on a timer it did not see fire.
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('shows the blocked person, with an Unblock action',
        (tester) async {
      final container = _container(_StreamingRepository.factory(
        () => Stream.value(const [
          BlockedUser(
              userId: 'them', email: 'them@example.com', displayName: 'Them'),
        ]),
      ));

      await pumpScreen(tester, container);

      expect(find.text('Them'), findsOneWidget);
      expect(find.text('Unblock'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await disposeAfterPump(tester, container);
    });

    testWidgets('shows a useful empty state', (tester) async {
      final container = _container(
          _StreamingRepository.factory(() => Stream.value(const [])));

      await pumpScreen(tester, container);

      expect(find.text('Nobody is blocked'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await disposeAfterPump(tester, container);
    });

    testWidgets('a failed read shows an error and a Retry that works',
        (tester) async {
      final container = _container(_RefusingRepository());

      await pumpScreen(tester, container);

      expect(find.text('Could not load your blocked list'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Nobody is blocked'), findsNothing,
          reason: 'a refusal is not an empty list');

      // Retry is not decoration: it leaves the error state (back to loading) and
      // the failed read resolves again rather than the page staying frozen.
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Could not load your blocked list'), findsOneWidget,
          reason: 'the read is refused again, and says so again');
      await disposeAfterPump(tester, container);
    });
  });
}
