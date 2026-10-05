import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:datedawn/services/auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
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
}
