# Data Dawn — Play Store and App Store Publishing Checklist

This checklist covers the required setup before publishing **Data Dawn** to Google Play and the Apple App Store. It is ordered as a real submission path: accounts → identity → legal → signing → store listing → review → rollout.

## 0. Locked-in identity (do not change after first upload)

| Field | Value | Why it is permanent |
|---|---|---|
| Display name | **Data Dawn** | Changeable, but pick it now — reviews reset on rename |
| Android package / application id | `com.datedawn.app` | Fixed forever once the first bundle is uploaded |
| iOS bundle identifier | `com.datedawn.app` | Fixed forever once the first build is uploaded |
| Firebase project | `datedawn` (number `255395342604`) | Baked into every build |
| URL scheme | `com.datedawn.app` | Referenced by sign-in deep links |

> **Why this matters:** Google Play and App Store Connect both reject a re-upload that changes the package/bundle id. If the id is wrong, the only fix is to publish a *new* app and migrate users. Confirm it is `com.datedawn.app` before the first upload.

## 1. Required accounts

### Google Play
- Google Play Console account ([play.google.com/console](https://play.google.com/console))
- One-time **$25** developer registration fee
- Identity verification (personal or organisation) — **this now takes days**, start it first
- For a *new personal* developer account: Google requires a **closed test with 12+ testers for 14 continuous days** before you may apply for production. Organisation accounts are exempt. Budget 2–3 weeks for this alone.

### App Store
- Apple Developer Program membership — **$99/year**
- Enrolment approval can take **24–48 hours** (longer for a new individual, which may need identity documents)
- App Store Connect access with the **Admin** or **App Manager** role

## 2. Required app metadata

### For both stores
- App name and description
- Icon set and splash assets
- Privacy policy URL (public, non-PDF, reachable without sign-in)
- Support URL
- Contact email
- App category
- Screenshots for each required device size
- Data safety / privacy disclosures

### Required for App Store
- App Privacy section must be completed
- Upload screenshot set for required iPhone/iPad sizes
- Apple Developer signing certificates and provisioning profiles
- **Demo account** for the reviewer (see §4) — a sign-in-only app is rejected without one
- **Account deletion** reachable inside the app (Apple hard requirement since 2022)

### Required for Play Store
- Data safety form
- Content rating questionnaire
- Target audience declaration
- App content declaration
- **Account deletion** URL or in-app path (Google requires this too)

## 3. Privacy policy and support — the website you need

Both stores require a **live public web page**, not a file in the repo. The site
is built and checked in at `docs/`, and GitHub Pages serves it directly — no
build step, no separate host, no cost.

**The three URLs (live now, once Pages is switched on):**

| Purpose | URL |
|---|---|
| Marketing / home | `https://vitaliklisa.github.io/DateDawn/` |
| Privacy policy | `https://vitaliklisa.github.io/DateDawn/privacy.html` |
| Support / help | `https://vitaliklisa.github.io/DateDawn/support.html` |
| Contact email | `vhomenko119@gmail.com` |

### Turning Pages on (one-time, ~1 minute)

1. Repo → **Settings → Pages**.
2. **Source**: *Deploy from a branch*.
3. **Branch**: `main`, **Folder**: `/docs`. Save.
4. Wait ~1 minute, then load the home URL above.

`docs/.nojekyll` is checked in so Pages serves the files verbatim instead of
running them through Jekyll.

> **Repo name note.** These URLs assume the repository stays named `DateDawn`.
> Renaming it again changes every URL, and any URL already submitted to a store
> console breaks on rename. If you rename the repo, update this table, the
> `docs/*.html` pages and both store consoles in the same sitting.

> **Do not delete `docs/*.html`.** Google Play and App Store Connect both fetch
these URLs during review, and the privacy policy URL is also required by the
Data safety / App Privacy forms. If the page 404s at review time, the submission
is rejected.

### What the policy must disclose for *this* app
- Firebase Authentication and Cloud Firestore as the data processors
- Google Sign-In, if enabled
- The exact data collected: name, email, event titles/descriptions/dates, circle membership, invitations, device push token
- Retention and deletion (what happens when a user deletes their account)
- **Data Safety form must match this policy.** Apple and Google both cross-check the policy against the questionnaire, and a mismatch is a rejection (Apple Guideline 5.1.1, Google's Data safety policy).

### Account deletion URL

Both stores require a **public URL** where a user can request account deletion
(Google: *App content → Data deletion*; Apple: guideline 5.1.1(v)).
`docs/support.html` is that page — it documents the in-app path
(*Settings → Delete account*) and the email fallback. Point both consoles at it.

## 4. The sign-in wall (the most common rejection for this kind of app)

Data Dawn is **useless without an account**, so reviewers cannot see any feature. Both stores reject "login required, no demo access":

- **Apple** (Guideline 2.1 / 5.1.1): you must supply a demo account in App Store Connect → *App Review Information* → *Sign-in required*.
- **Google** (Play Console → App content): declare that sign-in is required and provide credentials.

**Action before submitting:** create a real `reviewer@datedawn.app`-style account, pre-populate it with 2–3 sample countdowns (including one shared/circle event so the collaborative features are visible), and put those credentials in both consoles. Do not rely on "Continue without an account" — check whether that path exposes enough of the app to be reviewable.

## 5. App signing and release build

### Android
1. Generate a release keystore (**do this once — losing it means you can never update the app**):
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\bin\keytool.exe" -genkey -v `
     -keystore $env:USERPROFILE\datedawn-upload.jks `
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Store the `.jks` **and its passwords** somewhere you will still have in five years (password manager + offline backup).
2. Create `android/key.properties` (already gitignored):
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=C:/Users/Vi/datedawn-upload.jks
   ```
3. The release build currently signs with the **debug** key so CI can build without the keystore (`android/app/build.gradle.kts`). Before uploading, that `signingConfig = signingConfigs.getByName("debug")` must read the `key.properties` values — otherwise Play rejects the bundle.
4. Build and upload:
   ```powershell
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`
5. **Play App Signing**: Google re-signs your bundle with a key it holds. Your `.jks` becomes the *upload* key. This is the default and is recommended — accept it.

### iOS
1. Configure certificates and provisioning profiles in Xcode (or let `flutter build ipa` do it with automatic signing).
2. Bundle identifier must be `com.datedawn.app` (already set in `ios/Runner.xcodeproj/project.pbxproj`).
3. Enable capabilities: **Push Notifications** and **Background Modes → Remote notifications** if you ship reminders.
4. Archive and upload: `flutter build ipa --release` → open in **Transporter** or Xcode Organizer → upload to App Store Connect.
5. Wait for processing, then attach the build to a version and submit.

## 6. Screenshots

Both stores reject screenshots that show placeholder content, a simulator status bar, or a device frame that does not match the required size.

| Store | Requirement |
|---|---|
| App Store | 6.7" (iPhone 15/16 Pro Max) and 6.5" minimum; iPad if you ship iPad support |
| Play Store | At least 2 phone screenshots; 16:9 or 9:16 |

Take them from a **release build on a real device or a clean emulator**, signed in as the demo account with realistic countdowns. `flutter run --release` then use the device's own screenshot tool.

## 7. Firebase and security checks

- Regenerate native config for the **renamed** Firebase project and package: `flutterfire configure --project=datedawn`. This writes `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`.
- The Android app in Firebase must be registered with package name **`com.datedawn.app`** — a mismatch produces a silent auth failure on device.
- Add the release **SHA-1 and SHA-256** of your upload keystore to the Firebase Android app, or Google Sign-In fails in release builds while working in debug. Firebase takes exactly these two — **there is no SHA-512 field**, so do not go looking for one.

  Extract them from the keystore with:
  ```powershell
  & "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\keytool.exe" `
    -list -v -keystore "$env:USERPROFILE\datedawn-upload.jks" -alias upload
  ```

  **This project's fingerprints** (verify they still match before pasting):

  | Key | SHA-1 | SHA-256 |
  |---|---|---|
  | Upload (`datedawn-upload.jks`) | `0F:1A:9C:9B:82:EE:DD:04:77:96:01:EE:26:E3:C1:49:0B:42:CE:AB` | `6A:71:15:B9:09:94:1A:9F:88:17:B1:B7:9E:16:2E:42:E2:04:BC:69:75:46:0E:C1:9C:9A:35:A1:7A:DE:94:D8` |
  | Debug (`~/.android/debug.keystore`) | `0B:A5:C0:B1:31:D2:0B:21:C8:90:81:B7:36:87:AF:86:04:5C:3B:E2` | `69:66:12:6C:08:77:B3:6D:94:A1:FB:30:8A:9E:09:CE:B1:F3:FB:57:1D:23:EF:8B:DD:C8:71:E6:0A:7D:F9:37` |

  Register **both**, and add both to the same Firebase Android app. Debug and
  release are signed by different keys, so a build that works with one will fail
  Google Sign-In with the other until both are listed.

  > **If you enable Play App Signing**, Google re-signs your bundle with a key it
  > holds, and that key — not your upload key — becomes the one the installed app
  > is signed with. Copy the **App signing key certificate** SHA-1/SHA-256 from
  > Play Console → *Release → Setup → App signing* into Firebase as well, or
  > Google Sign-In breaks in the Play-distributed build only.

- Review `firestore.rules` before opening to the public — rules are the only thing protecting the data, and the config in `lib/firebase_config.dart` is public by design.
- Test sign-in, event creation, invitations, notifications and cross-device sync **on real devices**, signed in with two different accounts.

## 8. Pre-launch validation

- sign-in works on a real Android device and a real iPhone
- events save and sync across two accounts
- notifications arrive when enabled
- account deletion works and actually removes data
- no crashes on a cold start with no network
- screenshots match the final app state
- store listing text contains no placeholder values

## 9. Production promotion

### Google Play
Internal testing → Closed testing (**12 testers / 14 days** for new personal accounts) → Production

### App Store
TestFlight (internal first, then external beta review) → App Review submission → Production

App Review typically answers within 24–48 hours. Google's first review of a new account can take **up to 7 days**.

## 10. Final URL checklist

These are live once GitHub Pages is enabled (see §3). Fill them into both
consoles, the policy page and the store listings — they must match exactly.

- Privacy Policy: `https://vitaliklisa.github.io/DateDawn/privacy.html`
- Support / Help: `https://vitaliklisa.github.io/DateDawn/support.html`
- Account deletion: `https://vitaliklisa.github.io/DateDawn/support.html`
- Marketing / home: `https://vitaliklisa.github.io/DateDawn/`
- Contact Email: `vhomenko119@gmail.com`

Every one of these must be live and load without a sign-in before you submit.
