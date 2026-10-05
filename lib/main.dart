import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 moved `Override` out of the main entrypoint; it lives in `misc`.
import 'package:flutter_riverpod/misc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'firebase_config.dart';
import 'providers/app_providers.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'services/event_repository.dart';
import 'supabase_config.dart';

Future<void> main() async {
  // Launch breadcrumbs.
  //
  // The launch path is: Android window (launch_background) -> Flutter engine ->
  // Dart `main` -> first frame, at which point the engine removes the splash.
  // When the app "hangs on the splash", the cause is one of those stages, and
  // these lines make it unambiguous which: filter logcat for `datedawn` to see
  // exactly how far Dart got. Compiled out of release builds entirely.
  _trace('main() entered');
  WidgetsFlutterBinding.ensureInitialized();
  _trace('binding ready');

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  // On web the config must be supplied in code; on Android/iOS the native files
  // cover it. If web is missing its keys, show a page that says exactly what to
  // run rather than letting Firebase throw an opaque "API key not valid".
  if (kIsWeb && !hasWebFirebaseConfig) {
    _trace('web config missing: showing setup page');
    runApp(const _MissingConfigApp());
    return;
  }

  // Firebase is initialised from the platform config files that `flutterfire
  // configure` generates: android/app/google-services.json,
  // ios/Runner/GoogleService-Info.plist, and `firebaseOptions` for web.
  // See `lib/firebase_config.dart` and the README.
  //
  // On Android the google-services Gradle plugin registers `[DEFAULT]` during
  // process start, before Dart runs. `Firebase.apps` does not always see that
  // natively-created app, so calling `initializeApp` throws
  // `[core/duplicate-app]` and — because `main` awaits it — the app never gets
  // past the splash screen. The app is already usable in that case, so the
  // duplicate is the one error worth swallowing.
  try {
    if (Firebase.apps.isEmpty) {
      _trace('initializing Firebase');
      await Firebase.initializeApp(options: firebaseOptions);
      _trace('Firebase ready');
    } else {
      _trace('Firebase already initialised (native config)');
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    _trace('duplicate-app ignored');
  }

  _trace('calling runApp');
  runApp(const ProviderScope(child: DateDawnApp()));
  _trace('runApp returned (Dart frame scheduled)');
}

/// Launch breadcrumb. No-op in release builds, where `kDebugMode` is false and
/// the whole call is tree-shaken away.
void _trace(String message) {
  if (kDebugMode) debugPrint('[datedawn] $message');
}

/// Shown on web when `flutterfire configure` has not been run yet.
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    const palette = AppPalette.dark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(brightness: Brightness.dark),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firebase is not configured for web yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: palette.fg,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'The Firebase project id is baked in, but the web API key '
                    'and app id are not. Run this once from the project root, '
                    'then rebuild:',
                    style: TextStyle(
                        fontSize: 14, height: 1.5, color: palette.muted),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.border),
                    ),
                    child: const SelectableText(
                      'flutterfire configure --project=datedawn',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFF4FD1C5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'That writes lib/firebase_options.dart and the native config '
                    'files. Android and iOS already load theirs automatically.',
                    style: TextStyle(
                        fontSize: 13, height: 1.5, color: palette.subtle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DateDawnApp extends ConsumerWidget {
  const DateDawnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Date Dawn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(brightness: Brightness.light),
      darkTheme: AppTheme.build(brightness: Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => _FirstFrameLogger(
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: child!,
            ),
          ),
        ),
      ),
    );
  }
}

/// Logs once, on the first frame the engine actually presents.
class _FirstFrameLogger extends StatefulWidget {
  const _FirstFrameLogger({required this.child});

  final Widget child;

  @override
  State<_FirstFrameLogger> createState() => _FirstFrameLoggerState();
}

class _FirstFrameLoggerState extends State<_FirstFrameLogger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trace('first frame rendered — UI is live');
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Overrides used by tests and by `main` before Firebase is reachable, so the
/// widget tree can be pumped without a live project.
List<Override> buildOverrides({
  AuthService? authService,
  EventRepository? repository,
}) =>
    [
      if (authService != null)
        authServiceProvider.overrideWithValue(authService),
      if (repository != null)
        eventRepositoryProvider.overrideWithValue(repository),
    ];
