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

class _DuplicateEmailAuthService extends _TestAuthService {
  _DuplicateEmailAuthService() : super(Stream.value(null));

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    throw const AuthFailure(
      'An account already exists for this email. Please sign in instead.',
      code: 'email-already-in-use',
    );
  }
}

void main() {
  testWidgets('signed-out app renders the login content, not a blank pane',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
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

    final passwordFinder = find.byType(TextFormField).at(1);
    final passwordField = tester.widget<TextField>(
      find.descendant(
        of: passwordFinder,
        matching: find.byType(TextField),
      ),
    );
    expect(passwordField.obscureText, isTrue);
    expect(passwordField.keyboardType, TextInputType.visiblePassword);
    expect(passwordField.enableSuggestions, isFalse);
    expect(passwordField.autocorrect, isFalse);
    await tester.enterText(passwordFinder, 'test-password');
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pumpAndSettle();
    final visiblePasswordField = tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).at(1),
        matching: find.byType(TextField),
      ),
    );
    expect(visiblePasswordField.obscureText, isFalse);
    expect(visiblePasswordField.controller!.text, 'test-password');

    final modeSwitch = find.byKey(const ValueKey('auth-mode-switch'));
    final loginText = tester.widget<Text>(modeSwitch);
    final loginSpan = loginText.textSpan!;
    expect(loginSpan.toPlainText(), 'New here? Create one');
    expect(loginText.maxLines, 1);
    expect(loginText.softWrap, isFalse);

    final loginBounds = tester.getRect(modeSwitch);
    await tester.tapAt(
      Offset(loginBounds.right - 4, loginBounds.center.dy),
    );
    await tester.pumpAndSettle();

    final signupText = tester.widget<Text>(modeSwitch);
    final signupSpan = signupText.textSpan!;
    expect(signupSpan.toPlainText(), 'Already have an account? Sign in');
    expect(signupText.maxLines, 1);
    expect(signupText.softWrap, isFalse);
  });

  testWidgets('duplicate signup offers a direct switch to sign in',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_DuplicateEmailAuthService()),
        ],
        child: const DateDawnApp(),
      ),
    );
    await tester.pumpAndSettle();

    final modeSwitch = find.byKey(const ValueKey('auth-mode-switch'));
    await tester.tapAt(
      Offset(tester.getRect(modeSwitch).right - 4,
          tester.getRect(modeSwitch).center.dy),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Alex Rivera');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'An account already exists for this email. Please sign in instead.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBarAction), findsOneWidget);

    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(modeSwitch).textSpan!.toPlainText(),
      'New here? Create one',
    );
  });
}
