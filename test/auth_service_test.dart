import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:datedawn/services/auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

class _FakeActionCodeSettings extends Fake implements ActionCodeSettings {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeActionCodeSettings());
  });

  group('AuthService email sign-in', () {
    test('explains when Firebase Authentication is not configured', () async {
      final auth = _MockFirebaseAuth();
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password',
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'internal-error',
          message:
              'An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]',
        ),
      );

      await expectLater(
        AuthService(auth: auth).signInWithEmail(
          email: 'user@example.com',
          password: 'password',
        ),
        throwsA(
          isA<AuthFailure>()
              .having((error) => error.code, 'code', 'configuration-not-found')
              .having(
                (error) => error.message,
                'message',
                contains(
                  'Enable Google and Email/Password sign-in',
                ),
              ),
        ),
      );
    });
  });

  test('signup saves the display name and sends verification email', () async {
    final auth = _MockFirebaseAuth();
    final credential = _MockUserCredential();
    final user = _MockUser();
    when(
      () => auth.createUserWithEmailAndPassword(
        email: 'user@example.com',
        password: 'password',
      ),
    ).thenAnswer((_) async => credential);
    when(() => credential.user).thenReturn(user);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.email).thenReturn('user@example.com');
    when(() => user.uid).thenReturn('user-id');
    when(() => user.displayName).thenReturn('Alex Rivera');
    when(() => user.photoURL).thenReturn(null);
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.emailVerified).thenReturn(false);
    when(() => user.providerData).thenReturn(const []);
    when(() => user.updateDisplayName('Alex Rivera')).thenAnswer((_) async {});
    when(() => user.reload()).thenAnswer((_) async {});
    when(() => user.sendEmailVerification()).thenAnswer((_) async {});
    when(() => user.getIdToken(true)).thenAnswer((_) async => 'token');

    final registered = await AuthService(auth: auth).registerWithEmail(
      email: ' user@example.com ',
      password: 'password',
      displayName: '  Alex Rivera  ',
    );

    expect(registered.displayName, 'Alex Rivera');
    verifyInOrder([
      () => user.updateDisplayName('Alex Rivera'),
      () => user.reload(),
      () => user.sendEmailVerification(),
    ]);
  });

  test('duplicate email has a clear sign-in instruction', () async {
    final auth = _MockFirebaseAuth();
    when(
      () => auth.createUserWithEmailAndPassword(
        email: 'user@example.com',
        password: 'password',
      ),
    ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

    await expectLater(
      AuthService(auth: auth).registerWithEmail(
        email: 'user@example.com',
        password: 'password',
        displayName: 'Alex',
      ),
      throwsA(
        isA<AuthFailure>()
            .having((error) => error.code, 'code', 'email-already-in-use')
            .having(
              (error) => error.message,
              'message',
              'An account already exists for this email. Please sign in instead.',
            ),
      ),
    );
  });

  test('trims the email before sending a password reset', () async {
    final auth = _MockFirebaseAuth();
    ActionCodeSettings? sentSettings;
    when(
      () => auth.sendPasswordResetEmail(
        email: 'user@example.com',
        actionCodeSettings: any(named: 'actionCodeSettings'),
      ),
    ).thenAnswer((invocation) async {
      sentSettings =
          invocation.namedArguments[#actionCodeSettings] as ActionCodeSettings;
    });

    await AuthService(auth: auth).sendPasswordReset('  user@example.com  ');

    verify(
      () => auth.sendPasswordResetEmail(
        email: 'user@example.com',
        actionCodeSettings: any(named: 'actionCodeSettings'),
      ),
    ).called(1);
    expect(sentSettings!.url, 'https://datedawn.vercel.app/reset-password');
    expect(sentSettings!.handleCodeInApp, isTrue);
    expect(sentSettings!.androidPackageName, 'com.datedawn.app');
    expect(sentSettings!.androidInstallApp, isTrue);
    expect(sentSettings!.androidMinimumVersion, '1');
    expect(sentSettings!.iOSBundleId, 'com.datedawn.app');
  });

  test('verifies a password reset code and exposes the account email',
      () async {
    final auth = _MockFirebaseAuth();
    when(() => auth.verifyPasswordResetCode('action-code'))
        .thenAnswer((_) async => 'user@example.com');

    final email =
        await AuthService(auth: auth).verifyPasswordResetCode('action-code');

    expect(email, 'user@example.com');
  });

  test('confirms a password reset with the supplied action code', () async {
    final auth = _MockFirebaseAuth();
    when(
      () => auth.confirmPasswordReset(
        code: 'action-code',
        newPassword: 'new-password',
      ),
    ).thenAnswer((_) async {});

    await AuthService(auth: auth).confirmPasswordReset(
      code: 'action-code',
      newPassword: 'new-password',
    );

    verify(
      () => auth.confirmPasswordReset(
        code: 'action-code',
        newPassword: 'new-password',
      ),
    ).called(1);
  });
}
