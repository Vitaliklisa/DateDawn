import 'dart:async';

import 'package:datedawn/core/theme.dart';
import 'package:datedawn/l10n/generated/app_localizations.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/router.dart';
import 'package:datedawn/screens/delete_account_screen.dart';
import 'package:datedawn/services/auth_service.dart';
import 'package:datedawn/services/deletion_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {}

class _TestAuthService extends AuthService {
  _TestAuthService({this.failure, this.completion})
      : super(
          auth: _FakeFirebaseAuth(),
          deletionService: DeletionService(
            auth: _FakeFirebaseAuth(),
            client: MockClient((_) async => http.Response('', 200)),
          ),
        );

  final Object? failure;
  final Completer<void>? completion;
  String? submittedConfirmation;

  @override
  String? get currentEmail => 'Alex@example.com';

  @override
  Future<void> deleteAccount({required String confirmation}) async {
    submittedConfirmation = confirmation;
    if (failure != null) throw failure!;
    await completion?.future;
  }
}

Widget _buildApp(_TestAuthService authService) {
  final router = GoRouter(
    initialLocation: Routes.deleteAccount,
    routes: [
      GoRoute(
        path: Routes.deleteAccount,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login screen')),
        ),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Settings screen'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(authService),
      currentUserProvider.overrideWith(
        (ref) => const AppUser(id: 'user-id', email: 'alex@example.com'),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.build(brightness: Brightness.light),
    ),
  );
}

void main() {
  testWidgets('requires exact email and deletes, clears preferences, and exits',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'light',
      'time_format': '24',
      'app_locale': 'fr',
    });
    final completion = Completer<void>();
    final authService = _TestAuthService(completion: completion);

    await tester.pumpWidget(_buildApp(authService));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(
      find.text('Your profile will be permanently deleted.'),
      findsOneWidget,
    );
    expect(
      find.text('You will lose access to all your events and circles.'),
      findsOneWidget,
    );
    expect(find.text('This action cannot be undone.'), findsOneWidget);

    final input = find.byKey(const ValueKey('delete-account-confirmation'));
    await tester.ensureVisible(input);
    final submit = find.byKey(const ValueKey('delete-account-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(input, 'alex@example.com');
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(input, 'Alex@example.com');
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    completion.complete();
    await tester.pumpAndSettle();

    expect(authService.submittedConfirmation, 'Alex@example.com');
    expect(find.text('Login screen'), findsOneWidget);
    expect(find.text('Account deleted successfully'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('theme_mode'), isNull);
    expect(preferences.getString('time_format'), isNull);
    expect(preferences.getString('app_locale'), 'fr');
  });

  testWidgets('shows the server error message for a rejected request',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _TestAuthService(
          failure: const DeletionFailure(
            'Your session is invalid. Sign in again.',
            statusCode: 401,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('delete-account-confirmation')),
      'Alex@example.com',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('delete-account-confirmation')),
    );
    await tester.tap(find.byKey(const ValueKey('delete-account-submit')));
    await tester.pumpAndSettle();

    expect(
        find.text('Your session is invalid. Sign in again.'), findsOneWidget);
    expect(find.text('Login screen'), findsNothing);
  });

  for (final statusCode in [500, 504]) {
    testWidgets('shows the timeout message for HTTP $statusCode',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _TestAuthService(
            failure: DeletionFailure(
              'Internal server error.',
              statusCode: statusCode,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('delete-account-confirmation')),
        'Alex@example.com',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('delete-account-confirmation')),
      );
      await tester.tap(find.byKey(const ValueKey('delete-account-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Server timed out. Please try again later.'),
          findsOneWidget);
    });
  }
}
