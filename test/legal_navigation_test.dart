// Settings/support → legal pages, driven through the real router.
//
// This is the bug these tests exist for: tapping "Privacy policy" did **nothing
// at all** — no navigation, no screen change, no error. Both entry points used
// `context.push(Routes.privacy)`, and a `push` of a sibling route inside this
// app's `ShellRoute` is silently swallowed: the page is added as a secondary,
// never becomes current, and the URL never moves.
//
// A unit test on `Routes.privacy` cannot see that, so these pump the real app
// and tap the real rows.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/router.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _FakeFirestore extends Fake implements FirebaseFirestore {}

class _TestAuthService extends AuthService {
  _TestAuthService(this._authState) : super(auth: _FakeFirebaseAuth());
  final Stream<AppUser?> _authState;

  @override
  Stream<AppUser?> authStateChanges() => _authState;
}

/// A repository that never touches Firestore: a real one opens a connection
/// that never settles in a widget test, which leaves the router's redirect
/// stuck on "auth still loading".
class _TestRepository extends EventRepository {
  _TestRepository() : super(firestore: _FakeFirestore());

  @override
  Stream<List<CountdownEvent>> watchEvents(String userId) =>
      Stream.value(const <CountdownEvent>[]);

  @override
  Future<void> syncUserProfile(AppUser user) async {}
}

const _signedIn = AppUser(
  id: 'u1',
  email: 'ann@example.com',
  displayName: 'Ann',
);

void main() {
  /// A stack trace is worth more than the default "Unexpected failure", which
  /// is all a framework assertion inside a test body reports.
  Future<GoRouter> pumpApp(WidgetTester tester, String location) async {
    // A desktop window, so the sidebar and content pane are laid out the way
    // they are in the app, and tall enough that the legal rows and the policy
    // are both on screen — no tap is ever aimed at something scrolled away.
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late GoRouter router;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider
              .overrideWithValue(_TestAuthService(Stream.value(_signedIn))),
          eventRepositoryProvider.overrideWithValue(_TestRepository()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(routerProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.go(location);
    await tester.pumpAndSettle();
    return router;
  }

  String path(GoRouter router) =>
      router.routeInformationProvider.value.uri.path;

  /// The policy page is open *on top* of the page that opened it, so its title
  /// appears once — twice would mean the underlying page is still mounted at
  /// full size with no layer covering it.
  void expectPolicyOpen(String title) {
    expect(find.text(title), findsOneWidget);
    expect(find.textContaining('Last updated'), findsOneWidget);
  }

  testWidgets('settings opens the privacy policy, and back returns to settings',
      (tester) async {
    final router = await pumpApp(tester, Routes.settings);

    await tester.tap(find.text('Privacy policy').first);
    await tester.pumpAndSettle();
    expect(path(router), Routes.privacy, reason: 'the URL must follow the tap');
    expectPolicyOpen('Privacy Policy');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(path(router), Routes.settings);
    expect(find.textContaining('Last updated'), findsNothing);
    expect(find.text('Privacy policy'), findsOneWidget);
  });

  testWidgets('settings opens the terms of service', (tester) async {
    final router = await pumpApp(tester, Routes.settings);

    await tester.tap(find.text('Terms of service').first);
    await tester.pumpAndSettle();
    expect(path(router), Routes.terms);
    expectPolicyOpen('Terms of Service');
  });

  testWidgets('support opens the privacy policy, and back returns to support',
      (tester) async {
    final router = await pumpApp(tester, Routes.support);
    await tester.tap(find.text('Privacy policy').first);
    await tester.pumpAndSettle();
    expect(path(router), Routes.privacy);
    expectPolicyOpen('Privacy Policy');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(path(router), Routes.support);
    expect(find.text('Help & support'), findsOneWidget);
  });

  testWidgets('support opens the terms of service', (tester) async {
    final router = await pumpApp(tester, Routes.support);

    await tester.tap(find.text('Terms of service').first);
    await tester.pumpAndSettle();
    expect(path(router), Routes.terms);
    expectPolicyOpen('Terms of Service');
  });

  testWidgets('a cold load of /privacy shows the policy with a working back',
      (tester) async {
    final router = await pumpApp(tester, Routes.privacy);
    expectPolicyOpen('Privacy Policy');

    // Nothing opened it, so Back has to land somewhere real rather than
    // stranding the visitor on a page with no way out.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(path(router), Routes.support);
  });
}
