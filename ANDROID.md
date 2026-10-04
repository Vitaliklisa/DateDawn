# Date Dawn — Android app

Date Dawn is the Flutter app: a countdown app for Android, iOS and web, backed by Firebase (auth + Firestore). See **[docs/PUBLISHING_CHECKLIST.md](./docs/PUBLISHING_CHECKLIST.md)** for the store submission path.

> **Naming.** The app is **Date Dawn**; the Firebase project and package id are **`datedawn`** / **`com.datedawn.app`**. `com.datedawn.app` is permanent once the first Play bundle is uploaded — see the publishing checklist before you build an upload.

## Architecture

Date Dawn is a **pure Flutter** app: the UI, countdown maths, and every Firebase
call run on the device. There is no server component and no web app to load, so
the APK/AAB is fully self-contained and works offline except for sign-in and
Firestore sync.

```
lib/
  main.dart                 app entry, Firebase bootstrap
  firebase_config.dart      project id + web options
  router.dart               go_router table
  core/                     models, countdown maths, theme
  providers/                Riverpod providers (auth, events, circles, clock)
  screens/                  one file per screen
  services/                 auth + Firestore repositories
  widgets/                  shared UI
```

## Two modes

|         | Debug                                              | Release                                    |
| ------- | -------------------------------------------------- | ------------------------------------------ |
| Command | `flutter run` / `flutter build apk --debug`        | `flutter build appbundle --release`        |
| Signing | Debug key                                          | Your upload key (`android/key.properties`) |
| Backend | The Firebase project in `lib/firebase_config.dart` | Same                                       |
| Use for | Development, testing on a device                   | Google Play upload                         |

## One-time setup (already done in this repo)

- Flutter 3.47+ / Dart 3.13+ installed
- Android Studio + Android SDK with **NDK 28.2.13676358** installed
- `flutterfire configure --project=datedawn` run once, to generate
  `lib/firebase_options.dart`, `android/app/google-services.json` and
  `ios/Runner/GoogleService-Info.plist`

`lib/firebase_options.dart` contains public Firebase client identifiers and is
tracked so every build initializes Firebase with the same valid options.
Platform service files and signing keys remain local/secret and are not
committed.

## The NDK version must match the plugins

The Firebase, `share_plus`, `google_sign_in_android`, `jni` and
`flutter_local_notifications` plugins all require **NDK 28.2.13676358** or
higher. `android/app/build.gradle.kts` pins it explicitly:

```kotlin
ndkVersion = "28.2.13676358"
```

If a build ever reports `Your project is configured with Android NDK X, but the
following plugin(s) depend on a different Android NDK version`, do **not** lower
this value. NDK releases are backward compatible, so the fix is always to raise
it to the highest version any plugin asks for, then sync:

1. In Android Studio: **SDK Manager → SDK Tools → NDK (Side by side)** → tick
   the required version.
2. Re-run the build.

`android/local.properties` points Gradle at the SDK, and the NDK is resolved
from there.

## Build

```powershell
# debug APK, for installing directly on a device
flutter build apk --debug

# the artifact you upload to Play
flutter build appbundle --release
```

Outputs:

```
build/app/outputs/flutter-apk/app-debug.apk          (debug)
build/app/outputs/bundle/release/app-release.aab     (Play upload)
```

For an emulator, simpler still: `flutter run`. For a release build on a real
device: `flutter run --release`.

## Run the web build locally

```powershell
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=...
```

Web is the one platform with no native config file, so its keys arrive as
`--dart-define` values (see `lib/firebase_config.dart`). Without them the app
renders a page that says exactly which command to run instead of failing with
Firebase's opaque "API key not valid".

`flutterfire configure --project=datedawn` fills these in permanently by writing
`lib/firebase_options.dart`.

## Install on a device

1. `flutter build apk --debug`
2. Copy `build/app/outputs/flutter-apk/app-debug.apk` to the phone (USB, cloud
   storage, or `adb install`).
3. Tap the file → allow "Install unknown apps" for your file manager/browser.
4. Open **Date Dawn** from the home screen.

Or, phone plugged in over USB with USB debugging on:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "build\app\outputs\flutter-apk\app-debug.apk"
```

## App icon and splash

Both are generated from a single source rather than checked-in binaries, so a
palette change re-propagates:

```powershell
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

- Config: `flutter_launcher_icons.yaml` and `flutter_native_splash.yaml`.
- Theme colors live in `android/app/src/main/res/values/colors.xml`; the launcher
  background and splash use the app's dark canvas so there is no white flash on
  launch.
- **Rename note:** the icon and splash artwork still carries the old clock mark.
  Regenerate from the new Date Dawn artwork before the store screenshots are
  taken, so the listing and the installed app match.

## Push notifications — current status

**Wired:** `flutter_local_notifications` is a dependency and the Android manifest
permits network access. There is no FCM sender yet.

**Not yet wired — the last mile:** actually _sending_ a push. That needs FCM
credentials from the `datedawn` Firebase project:

1. In the Firebase console, add an **Android app** to the `datedawn` project with
   package name **`com.datedawn.app`** (exactly — a mismatch silently breaks
   sign-in and messaging).
2. Download `google-services.json` → place it at
   `android/app/google-services.json`.
3. Add the `google-services` Gradle plugin in `android/settings.gradle.kts` and
   apply it in `android/app/build.gradle.kts`, then add
   `firebase_messaging` to `pubspec.yaml`.
4. Add request-time permission (`POST_NOTIFICATIONS` on Android 13+,
   `UNUserNotificationCenter` on iOS) and register the FCM token against the
   signed-in user.
5. Send from a server (or a scheduled Cloud Function) using a service-account key
   held in an env var — never in the app bundle.

Until step 5, notifications are local-scheduled only and nothing is delivered
from the server.

## Firebase setup after the rename

The Firebase project is **`datedawn`** (project number `255395342604`) and the
package is **`com.datedawn.app`**. To regenerate every platform config file at
once:

```powershell
flutterfire configure --project=datedawn
```

This writes `lib/firebase_options.dart`, `android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist`. In Firebase Console → Authentication →
Sign-in method, enable Anonymous, Google, and Email/Password; the app cannot
create guest sessions or authenticate accounts until those providers are on.

**Google Sign-In:** Android also needs a Web OAuth client ID. If it is not
included in `google-services.json`, pass it as
`--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>` when building. Add both
the debug and release signing SHA-1/SHA-256 fingerprints to the Firebase Android
app (Project settings → Your apps). Without the provider, client ID, or matching
fingerprints, Google sign-in is unavailable even though the button is present.
