import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datedawn/core/models.dart';
import 'package:datedawn/screens/home_screen.dart';
import 'package:datedawn/screens/verify_email_screen.dart';
import 'package:datedawn/services/event_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/router.dart';
import 'package:datedawn/services/auth_service.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _FakeFirestore extends Fake implements FirebaseFirestore {}

class _TestRepository extends EventRepository {
  _TestRepository() : super(firestore: _FakeFirestore());

  @override
  Stream<List<CountdownEvent>> watchEvents(String userId) =>
      Stream.value(const <CountdownEvent>[]);

  @override
  Future<void> syncUserProfile(AppUser user) async {}
}

class _TestAuthService extends AuthService {
  _TestAuthService(Stream<AppUser?> authState, {this.onReload})
      : _authState = authState,
        super(auth: _FakeFirebaseAuth());

  final Stream<AppUser?> _authState;
  final VoidCallback? onReload;
  String? verifiedResetCode;
  String? appliedVerificationCode;
  AppUser? reloadedUser;
  int verificationEmailsSent = 0;
  int reloadCount = 0;

  @override
  Stream<AppUser?> authStateChanges() => _authState;

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    verifiedResetCode = code;
    return 'user@example.com';
  }

  @override
  Future<void> applyEmailVerificationCode(String code) async {
    appliedVerificationCode = code;
  }

  @override
  Future<void> sendEmailVerification() async {
    verificationEmailsSent++;
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    reloadCount++;
    onReload?.call();
    return reloadedUser;
  }
}

void main() {
  Future<void> expectSignIn(WidgetTester tester, AppUser? user) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider
              .overrideWithValue(_TestAuthService(Stream.value(user))),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Date Dawn'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('Continue as guest'), findsNothing);
  }

  testWidgets('signed-out visitors are routed to sign in', (tester) async {
    await expectSignIn(tester, null);
  });

  testWidgets('anonymous sessions do not satisfy the sign-in gate',
      (tester) async {
    await expectSignIn(
      tester,
      const AppUser(
        id: 'anonymous-user',
        email: '',
        isAnonymous: true,
      ),
    );
  });

  testWidgets('Firebase password action links reach the public reset route',
      (tester) async {
    final auth = _TestAuthService(Stream.value(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MaterialApp));
    ProviderScope.containerOf(context, listen: false)
        .read(routerProvider)
        .go('/__/auth/action?mode=resetPassword&oobCode=router-code');
    await tester.pumpAndSettle();

    expect(auth.verifiedResetCode, 'router-code');
    expect(find.text('Choose a new password'), findsOneWidget);
  });

  testWidgets('Firebase email verification links apply the action code',
      (tester) async {
    final auth = _TestAuthService(Stream.value(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MaterialApp));
    ProviderScope.containerOf(context, listen: false)
        .read(routerProvider)
        .go('/__/auth/action?mode=verifyEmail&oobCode=verify-code');
    await tester.pumpAndSettle();

    expect(auth.appliedVerificationCode, 'verify-code');
    expect(find.text('Verify your email'), findsOneWidget);
  });

  testWidgets('unverified email accounts are redirected to verification',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(
            _TestAuthService(
              Stream.value(
                const AppUser(
                  id: 'email-user',
                  email: 'user@example.com',
                  emailVerified: false,
                ),
              ),
            ),
          ),
          eventRepositoryProvider.overrideWithValue(_TestRepository()),
          clockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('verified-email confirmation reload returns the user to home',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final users = StreamController<AppUser?>.broadcast(sync: true);
    addTearDown(users.close);
    const unverified = AppUser(
      id: 'email-user',
      email: 'user@example.com',
      emailVerified: false,
    );
    const verified = AppUser(
      id: 'email-user',
      email: 'user@example.com',
      emailVerified: true,
    );
    final auth = _TestAuthService(
      users.stream,
      onReload: () => users.add(verified),
    )..reloadedUser = verified;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          eventRepositoryProvider.overrideWithValue(_TestRepository()),
          clockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    users.add(unverified);
    await tester.pumpAndSettle();
    expect(find.byType(VerifyEmailScreen), findsOneWidget);

    await tester.tap(find.text('I have verified my email'));
    await tester.pumpAndSettle();

    expect(auth.reloadCount, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('verified email accounts go straight to the home screen',
      (tester) async {
    await _expectHomeForUser(
      tester,
      const AppUser(
        id: 'verified-user',
        email: 'user@example.com',
        emailVerified: true,
      ),
    );
  });

  testWidgets('Google accounts bypass email verification', (tester) async {
    await _expectHomeForUser(
      tester,
      const AppUser(
        id: 'google-user',
        email: 'google@example.com',
        isGoogleUser: true,
      ),
    );
  });

  testWidgets('verified Google accounts go straight to the home screen',
      (tester) async {
    await _expectHomeForUser(
      tester,
      const AppUser(
        id: 'verified-google-user',
        email: 'google@example.com',
        emailVerified: true,
        isGoogleUser: true,
      ),
    );
  });
}

Future<void> _expectHomeForUser(WidgetTester tester, AppUser user) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider
            .overrideWithValue(_TestAuthService(Stream.value(user))),
        eventRepositoryProvider.overrideWithValue(_TestRepository()),
        clockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byType(HomeScreen), findsOneWidget);
  expect(find.byType(VerifyEmailScreen), findsNothing);
}
