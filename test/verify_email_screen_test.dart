import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/screens/verify_email_screen.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _TestAuthService extends AuthService {
  _TestAuthService() : super(auth: _FakeFirebaseAuth());

  int verificationEmailsSent = 0;
  int reloadCount = 0;
  AppUser? reloadedUser = const AppUser(
    id: 'user-id',
    email: 'user@example.com',
    emailVerified: false,
  );

  @override
  Future<void> sendEmailVerification() async {
    verificationEmailsSent++;
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    reloadCount++;
    return reloadedUser;
  }
}

void main() {
  testWidgets('verification screen can resend and recheck email status',
      (tester) async {
    final auth = _TestAuthService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          currentUserProvider.overrideWithValue(
            const AppUser(
              id: 'user-id',
              email: 'user@example.com',
              emailVerified: false,
            ),
          ),
        ],
        child: const MaterialApp(home: VerifyEmailScreen()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('user@example.com'), findsOneWidget);
    expect(
      find.textContaining('check your Spam or Junk folder'),
      findsOneWidget,
    );
    expect(find.text('Resend email'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Resend email'));
    await tester.pump();
    expect(auth.verificationEmailsSent, 1);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(
      find.text('Please wait 60 seconds before requesting another email.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 60));
    expect(find.text('Resend email'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );

    ScaffoldMessenger.of(tester.element(find.byType(VerifyEmailScreen)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.text('I have verified my email'));
    await tester.pumpAndSettle();
    expect(auth.reloadCount, 1);
    expect(find.text('Not verified yet. Check your inbox.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
