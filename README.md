# Date Dawn — Flutter + Firebase

Count down to the moments that matter. A Flutter app for **Android, iOS and
web**, backed by Firebase Authentication and Cloud Firestore. Android, iOS,
and web all use the same Flutter/Dart app in `lib/`; there is no separate React
web interface.

Vercel builds the web app from this same Dart source with the pinned Flutter
SDK. Run `flutter build web --release` to build it locally. Before deploying,
add the Vercel site hostname (for example, `date-dawn.vercel.app`) to Firebase
Authentication's authorized domains so web sign-in works.

---

## What it does

- **One hero countdown**, counting years / months / days / hours, with the
  minutes and seconds ticking beneath it.
- **Name a day** — a wedding, a launch, a trip home. Any moment ahead of you.
- **Arrival celebration** — when the countdown reaches zero, confetti rains over
  the whole screen and the card says so.
- **Share a countdown** with other people, by email, with a role:
  `admin` (can invite, edit, delete), `editor` (can edit), `viewer` (read-only).
- **Circles** — invite someone **once** into a group (family, friends, a team),
  then share any future countdown with the whole group in a single tap. See
  below.
- **Couples** — mark a circle as *us* and it shares automatically: anything one
  partner creates, the other sees immediately, with no invitation to accept.
- **Invitations with a real answer** — an invitee gets Accept / Decline, and
  whoever sent it is told what they chose ("Sam joined 'Trip home'").
- **Notes** on a shared countdown, so the people counting down together can
  leave each other messages.
- **Duplicate** a countdown a year on — useful for annual events.
- **Dark and light**, following the device by default.
- **A real route for every section** — Home, Invitations, Circles, Notifications,
  and Settings are directly addressable, with persistent desktop navigation and
  mobile bottom navigation. Sign-in is required before entering any section.

---

## Circles and sharing

There are three ways a countdown reaches another person, and they exist because
re-typing an email for every event is the thing that makes a counting-down app
annoying to use more than once.

| | How it works | Who has to accept |
|---|---|---|
| **Invite to a countdown** | Add one person to one event, by email | The person invited |
| **Share with a circle** | Anyone in the circle sees the countdown | Nobody — members already opted in |
| **Couple circle** | Marked *us*; every new countdown is shared automatically | Nobody — that is what partners asked for |

### Inviting someone to a countdown

1. Open a countdown → **Collaborators** → enter their email → pick a role.
2. If they already have an account, the countdown appears as a pending invite
   in their app. If they do not, the invitation waits in the `invitations`
   collection until someone signs up with that address.
3. They get **Accept** / **Decline**. Either way, a line lands in the inviter's
   **Notifications** naming them and what they chose.

### Circles

A circle is a standing group. Create one (Family, Tokyo 2027, Us), invite people
into it once, and afterwards a countdown can be shared with the whole group by
ticking it in the composer.

- Only the **owner** can invite into a circle.
- Joining a circle is always the invitee's choice — a circle invitation is never
  auto-accepted, unlike a couple.
- Members can leave; the owner can rename.

### Couples

Creating a circle with the **"This is us — a couple"** toggle changes its
behaviour: any countdown either partner creates is attached to that circle and
every member gets an accepted `editor` participant row in the same batch. No
invitation, nothing to accept.

The flow end to end:

1. Alex creates a circle named *Us* with the couple toggle on, and invites Sam
   by email.
2. Sam sees **"Become Alex's partner"** in their invitations and accepts.
3. Alex creates *Anniversary trip*. It is shared with *Us* automatically.
4. Sam opens the app and the countdown is already there — nothing to accept.

---

## Stack

| Concern | Choice | Why |
|---|---|---|
| UI | Flutter 3.22+ | One codebase → Android, iOS, web |
| State | Riverpod | Testable, no `BuildContext` plumbing |
| Routing | go_router | All app routes require a signed-in account on web and mobile |
| Auth | Firebase Authentication | Free, unlimited for email/password and Google |
| Data | Supabase selected; current event repository still uses Cloud Firestore | Supabase client is initialized; migrate the existing event/sharing repository before moving production data |
| Dates | intl | Locale-aware formatting |

### Firebase free-tier limits (Spark plan)

Comfortably enough for a launch, and it does not ask for a card:

- **Authentication** — unlimited email/password and Google sign-ins.
- **Firestore** — 1 GiB stored, 50k document reads and 20k writes per day.
- **Hosting** (optional, for the web build) — 10 GB/month transfer.

A countdown document is a few hundred bytes, so 1 GiB is on the order of a
million countdowns. The daily read quota is the real ceiling: one active user
costs roughly a few hundred reads a day with the realtime listeners this app
opens.

---

## Setup

> **Firebase project: `datedawn`** (number `255395342604`) — already wired into
> `lib/firebase_config.dart`. The account that owns the Firebase project still
> needs to run the steps below once; everything else is done.

### 1. Flutter

```bash
flutter --version   # 3.22 or newer
```

### 2. Confirm the Firebase project

The project exists as **`datedawn`**. In the
[Firebase console](https://console.firebase.google.com/project/datedawn)
confirm that:

1. **Authentication → Sign-in method** has enabled:
   - **Email/Password**
   - **Google**
2. **Firestore Database** exists (production mode). The region cannot be
   changed later, so pick one close to your users.
3. **Authentication → Settings → Authorized domains** contains `localhost` and
   your production domain — Google sign-in on web is refused otherwise.

Every route except `/login` requires a non-anonymous Firebase account. There is
no guest path. Supabase is initialized from `lib/supabase_config.dart`; the
existing countdown, circle, and invitation reads/writes are still implemented
against Firestore and need a separate schema/repository migration before
Supabase becomes the app's active data store.

### 3. Connect the app to the project

```bash
npm install -g firebase-tools      # or: curl -sL https://firebase.tools | bash
firebase login
dart pub global activate flutterfire_cli

flutterfire configure --project=datedawn
```

`flutterfire configure` writes:

- `lib/firebase_options.dart` — the generated per-platform config
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- and registers the web app

Until you run it, the app **compiles, analyzes and passes its tests**, and
Android/iOS are already pointed at the right project. Only the **web** build
needs the generated keys: open it in a browser and it will show a page telling
you to run `flutterfire configure --project=datedawn` rather than failing
with an opaque Firebase error.

To keep web keys out of the source instead, pass them at build time (they are
public identifiers, so either way is safe):

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=...
```

### 4. Google sign-in per platform

**Android** — add your debug and release signing keys' SHA-1/SHA-256 fingerprints
to the Firebase Android app (Project settings → Your apps → Add fingerprint):

```bash
cd android && ./gradlew signingReport
```

**iOS** — the `GoogleService-Info.plist` carries the `REVERSED_CLIENT_ID`. Make
sure `ios/Runner/Info.plist` has a matching URL scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
 <dict>
    <key>CFBundleTypeRole</key><string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array><string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string></array>
 </dict>
</array>
```

**Web** — in Firebase console → Authentication → Settings → **Authorized
domains**, add `localhost` and your production domain. Google sign-in on web
only works from an authorized domain.

### 5. Deploy the security rules

The rules in `firestore.rules` are the real authority — the client mirrors them
only so it can show a readable error.

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

The composite indexes in `firestore.indexes.json` are required: Firestore will
otherwise refuse the "my events, soonest first, not deleted" query. Deploying
the indexes file creates them for you.

### 6. Run it

```bash
flutter pub get
flutter run -d chrome      # web
flutter run                # attached Android/iOS device or emulator
```

---

## Android build notes

Four things had to be right before `flutter build appbundle --release` would
produce an uploadable bundle. They are recorded here because each one fails with
an error message that points somewhere other than the real cause.

**1. The `flutterEmbedding` meta-data tag is required.**

Flutter's `computeEmbeddingVersion()` returns the *v1* embedding as its default
and only recognises v2 if `AndroidManifest.xml` contains:

```xml
<meta-data android:name="flutterEmbedding" android:value="2" />
```

Without it the build stops with *"Build failed due to use of deleted Android v1
embedding"* even though nothing in the project is v1. If you ever regenerate the
manifest, re-add this tag.

**2. Core library desugaring.**

`flutter_local_notifications` uses `java.time` on API levels below 26, so
`android/app/build.gradle.kts` sets `isCoreLibraryDesugaringEnabled = true` and
adds `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`. Without
it the build fails at `:app:checkReleaseAarMetadata`.

**3. The base theme must not use AppCompat or `Theme.SplashScreen`.**

The app does not depend on either library, so
`android/app/src/main/res/values/styles.xml` uses plain platform themes
(`@android:style/Theme.Black.NoTitleBar`). Referencing `Theme.SplashScreen`
fails at resource linking with *"resource style/Theme.SplashScreen not found"*.

**4. A Gradle wrapper new enough for the Android Gradle Plugin.**

`android/gradle/wrapper/gradle-wrapper.properties` pins a Gradle version that
satisfies the AGP the Flutter plugin resolves. A mismatch fails with *"Minimum
supported Gradle version is X. Current version is Y"*.

The NDK version is pinned in `build.gradle.kts` to the highest one any plugin
requires. `llvm-strip` (used to shrink the bundle by stripping native debug
symbols) needs Android SDK `cmdline-tools`; the CI job installs them explicitly,
because the runner image ships an SDK without them.

---

## Testing

```bash
flutter analyze
flutter test
```

The unit tests cover the parts most likely to break silently:

- `test/countdown_test.dart` — the calendar maths. A "month" is a calendar
  month, not 30 days; 29 February clamps correctly; a past moment reports
  `isPast` rather than negative units.
- `test/models_test.dart` — permission resolution (creator is always an admin,
  strangers are always viewers), Firestore document parsing, and tolerance of
  sparse or string-dated documents.

---

## Publishing

### Android → Google Play

1. **Bump the version** in `pubspec.yaml` — Play rejects a re-used
   `versionCode`:
   ```yaml
   version: 1.0.0+1   # name+code; the code must increase every upload
   ```

2. **Create an upload keystore** (once, and keep it safe — losing it means you
   can never update the app again):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

3. **Point Gradle at it.** Create `android/key.properties` (and make sure it is
   in `.gitignore` — never commit a keystore or its password):
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

4. **Reference it** in `android/app/build.gradle`:
   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }

   android {
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile file(keystoreProperties['storeFile'])
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
               minifyEnabled true
               shrinkResources true
           }
       }
   }
   ```

5. **Build the bundle** (Play wants an `.aab`, not an `.apk`):
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`

6. **Upload** in the [Play Console](https://play.google.com/console):
   - Create the app, then complete **App content**: privacy policy, data safety
     form, content rating, target audience.
   - **Internal testing** first — add yourself, install from the Play link,
     confirm sign-in and sync work on a real device.
   - Promote to **Closed → Open → Production**.

   The data safety form must declare what Firebase collects: email address and
   user IDs (for authentication), and app activity (for Firestore). Firebase
   Analytics, if you enable it, additionally collects device identifiers.

### iOS → App Store

1. **Open the workspace** (not the `.xcodeproj`):
   ```bash
   cd ios && pod install && open Runner.xcworkspace
   ```

2. **Signing** — in Xcode → Runner → Signing & Capabilities, select your team
   and let Xcode manage the provisioning profile. Set the bundle identifier to
   match the one in Firebase.

3. **Capabilities** — add **Push Notifications** if you plan to add reminders
   later, and **Background Modes → Remote notifications**.

4. **Info.plist** — the Google sign-in URL scheme from step 4 above.

5. **Archive and upload:**
   ```bash
   flutter build ipa --release
   ```
   Then either upload the `.ipa` with **Transporter**, or open
   `build/ios/archive/Runner.xcarchive` in Xcode and use **Distribute App**.

6. **App Store Connect:**
   - Create the app record, fill in the description, keywords, screenshots
     (6.7", 6.5" and 5.5" iPhone sizes are required), and support URL.
   - **App Privacy** — declare the same data types as the Play data safety form.
   - Submit for review. A first review typically takes a day or two.

   Apple requires a **privacy policy URL** for any app that collects an email
   address; a plain page on your own domain is fine.

### Web (optional)

```bash
flutter build web --release
firebase deploy --only hosting
```

Or host `build/web` on any static host. Because the app is a client-side
Firebase app, no server runtime is needed — but note that the Firebase web
config is public by design, which is why the security rules matter.

---

## App icon and splash

Both are generated **from code**, not checked-in binaries, so a palette change
re-propagates everywhere in one run. The mark is the same dark-tile cream-clock
as the web favicon: `assets/icon/icon.png`, `assets/splash/*`, and the PWA icons
under `web/icons/`.

```bash
node scripts/generate-flutter-icons.mjs   # draws the PNGs (needs: npm i sharp)
dart run flutter_launcher_icons           # writes Android + iOS app icons
dart run flutter_native_splash:create     # writes Android + iOS splash screens
```

- Config lives in `flutter_launcher_icons.yaml` and
  `flutter_native_splash.yaml`.
- The mark is drawn at 62% of the canvas so Android's adaptive-icon mask
  (circle, squircle or rounded square) never clips it.
- The splash background is the app's own dark canvas, so launching never
  flashes white — the most jarring launch bug on a dark-themed app.
- iOS icons are flattened (no alpha), because App Store review rejects an alpha
  channel in `AppIcon`.

---

## How the data is shaped

```
events/{eventId}
  title, description, at, createdBy, createdAt, updatedAt, deletedAt?
  sharedWithCircleIds[]
  participants/{userId}   email, role, inviteStatus, joinedAt, displayName, photoUrl
  notes/{noteId}          userId, text, createdAt, updatedAt

invitations/{inviteId}    eventId, invitedBy, inviteeEmail, role, status,
                          createdAt, expiresAt, eventTitle

circles/{circleId}        name, ownerId, memberIds[], isCouple, emoji, createdAt
  members/{userId}        email, displayName, photoUrl, isOwner, joinedAt

circle_invitations/{id}   circleId, invitedBy, inviteeEmail, circleName,
                          isCouple, status, createdAt, expiresAt

responses/{id}            recipientId, eventId, eventTitle, responderEmail,
                          responderName, accepted, respondedAt, read

users/{userId}            email, displayName
```

**Visibility.** A user sees an event when they created it, hold an accepted
participant row, **or** belong to a circle in its `sharedWithCircleIds`.
Enforced in `firestore.rules`; the client mirrors the rule in
`CountdownEvent.canEdit` / `canManage` so buttons hide instead of failing.

**Why `memberIds` is duplicated onto the circle.** Security rules have no
subcollection query, so membership is checked against a plain array on the
circle document — one `get()` instead of a scan. The array and the `members`
subcollection are written in the same batch, so they cannot drift.

**Soft delete.** Deleting stamps `deletedAt` rather than removing the document,
so an accidental delete is recoverable and participant/note history is not
orphaned. Every read filters `deletedAt == null`.

**Inviting by email.** If the email already has an account, a participant row is
written immediately (pending). If not, the invitation waits in `invitations`
until someone signs up with that address, at which point it surfaces as a banner
they can accept.

---

## Project layout

```
lib/
  core/
    countdown.dart      calendar-aware countdown maths + formatting
    models.dart         CountdownEvent, Participant, EventNote, Invitation
    circles.dart        Circle, CircleMember, CircleInvitation, InvitationResponse
    theme.dart          design tokens (dark + light)
  services/
    auth_service.dart   Firebase Auth: Google and email/password
    event_repository.dart  Firestore reads/writes, merged visibility query
  providers/
    app_providers.dart  Riverpod wiring: auth, events, clock, theme
  screens/
    home_screen.dart          hero countdown + list + inbox badges
    event_editor_screen.dart  create/edit, invites, circle picker, live preview
    event_detail_screen.dart  full view, notes, sharing
    invitations_screen.dart   invitations awaiting your answer
    circles_screen.dart       create circles, invite members
    notifications_screen.dart answers to invitations you sent
    login_screen.dart         required sign in / register
    settings_screen.dart      account + appearance
  widgets/
    countdown_face.dart       the four tiles + ticking line
    arrival_celebration.dart  confetti burst
    brand_kit.dart            wordmark, avatar, status chip
    invitations_inbox.dart    countdown + circle invitations, accept/decline
    event_actions_sheet.dart  long-press actions
    share_event.dart          text sharing
  main.dart             Firebase init + app root
  firebase_config.dart  project id + web options
  router.dart           go_router routes
```

## Cost expectations

Everything above runs on the Firebase **Spark (free)** plan and Apple/Google's
one-off developer fees:

- **Google Play** — $25 once.
- **Apple Developer Program** — $99/year (required to publish to the App Store).
- **Firebase** — free at launch scale; you only start paying if you exceed the
  daily quotas above.

That is the whole running cost: the recurring spend is Apple's annual fee, and
nothing else until the app has enough users to outgrow the free tier.
