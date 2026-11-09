import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/screens/password_reset_screen.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _TestAuthService extends AuthService {
  _TestAuthService() : super(auth: _FakeFirebaseAuth());

  String? verifiedCode;
  String? confirmedCode;
  String? confirmedPassword;

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    verifiedCode = code;
    return 'user@example.com';
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    confirmedCode = code;
    confirmedPassword = newPassword;
  }
}

void main() {
  testWidgets('validates the action link and updates the password',
      (tester) async {
    final auth = _TestAuthService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: MaterialApp(
          home: PasswordResetScreen(
            actionUri: Uri.parse(
              'https://datedawn.firebaseapp.com/__/auth/action'
              '?mode=resetPassword&oobCode=one-time-code',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.verifiedCode, 'one-time-code');
    expect(find.text('user@example.com'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'new-password',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'new-password',
    );
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();

    expect(auth.confirmedCode, 'one-time-code');
    expect(auth.confirmedPassword, 'new-password');
    expect(find.text('Welcome to Date Dawn'), findsNothing);
  });

  testWidgets('finds an action code inside a nested Firebase link',
      (tester) async {
    final auth = _TestAuthService();
    final nestedLink = Uri(
      scheme: 'https',
      host: 'datedawn.firebaseapp.com',
      path: '/__/auth/action',
      queryParameters: {'oobCode': 'nested-code'},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: MaterialApp(
          home: PasswordResetScreen(
            actionUri: Uri(
              scheme: 'https',
              host: 'datedawn.vercel.app',
              path: '/reset-password',
              queryParameters: {'link': nestedLink.toString()},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(auth.verifiedCode, 'nested-code');
    expect(find.text('Choose a new password'), findsOneWidget);
  });
}
