import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/router.dart';
import 'package:datedawn/services/auth_service.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _TestAuthService extends AuthService {
  _TestAuthService(Stream<AppUser?> authState)
      : _authState = authState,
        super(auth: _FakeFirebaseAuth());

  final Stream<AppUser?> _authState;
  String? verifiedResetCode;

  @override
  Stream<AppUser?> authStateChanges() => _authState;

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    verifiedResetCode = code;
    return 'user@example.com';
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
}
