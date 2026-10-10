// Reproduces the grey content pane in a widget test.
//
// Every existing router test pumps `MaterialApp.router` directly, which skips
// `DateDawnApp`'s `builder` — the ColoredBox that paints the whole shell. This
// one pumps the real app widget, so the wrapper is exercised, and asserts that
// the content pane is not left empty.
import 'package:datedawn/main.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _TestAuthService extends AuthService {
  _TestAuthService(this._authState) : super(auth: _FakeFirebaseAuth());
  final Stream<AppUser?> _authState;

  @override
  Stream<AppUser?> authStateChanges() => _authState;
}

void main() {
  testWidgets('signed-out app renders the login content, not a blank pane',
      (tester) async {
    tester.view.physicalSize = const Size(944, 948);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider
              .overrideWithValue(_TestAuthService(Stream.value(null))),
        ],
        child: const DateDawnApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The login screen is a top-level route OUTSIDE the ShellRoute, so the
    // navigation sidebar must not be on screen with it.
    expect(find.text('Welcome to Date Dawn'), findsOneWidget,
        reason: 'login content should be visible');

    // The sidebar belongs to AppNavigationShell, which only mounts inside the
    // shell. Seeing it alongside the login screen is the contradiction the grey
    // screen presents.
    expect(find.text('Invitations'), findsNothing,
        reason:
            'the shell sidebar must not render on the top-level login route');
  });
}
