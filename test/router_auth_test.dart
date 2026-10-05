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

  @override
  Stream<AppUser?> authStateChanges() => _authState;
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
}
