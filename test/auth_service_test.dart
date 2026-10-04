import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:datedawn/services/auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  group('AuthService guest sign-in', () {
    test('explains when Firebase Authentication is not configured', () async {
      final auth = _MockFirebaseAuth();
      when(() => auth.signInAnonymously()).thenThrow(
        FirebaseAuthException(
          code: 'internal-error',
          message:
              'An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]',
        ),
      );

      await expectLater(
        AuthService(auth: auth).signInAnonymously(),
        throwsA(
          isA<AuthFailure>()
              .having((error) => error.code, 'code', 'configuration-not-found')
              .having(
                (error) => error.message,
                'message',
                contains(
                  'Enable Anonymous, Google, and Email/Password sign-in',
                ),
              ),
        ),
      );
    });
  });
}
