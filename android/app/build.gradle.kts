import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is read from android/key.properties, which is deliberately
// gitignored (it holds the upload-key password). When the file is absent — a
// fresh clone or CI — the release build falls back to the debug key so that
// `flutter build apk --release` still compiles and can be smoke-tested. A Play
// upload MUST use the real key, so the build prints a loud warning when it is
// falling back.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasUploadKey = keystorePropertiesFile.exists()
if (hasUploadKey) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.datedawn.app"
    // 36 is the highest version any current plugin requires
    // (`flutter_local_notifications`, `google_sign_in_android`, `share_plus` and
    // `shared_preferences_android` all compile against 36; `jni`/`jni_flutter`
    // need 35). Android SDKs are backward compatible, so compiling against the
    // highest one is always the fix — compiling against a lower one fails
    // `:app:checkDebugAarMetadata` with "requires libraries and applications that
    // depend on it to compile against version 36 or later".
    compileSdk = 36
    // Pinned rather than taken from `flutter.ndkVersion`: an explicit version
    // makes Gradle fetch the NDK it needs (including `llvm-strip`, which the
    // release pipeline uses to strip native debug symbols) instead of failing
    // when the host SDK has a different one installed.
    //
    // 28.2.13676358 is the highest version any current plugin requires
    // (`cloud_firestore`/`jni`, `share_plus`, `shared_preferences_android`),
    // and NDK releases are backward compatible — pinning lower than a plugin
    // asks for is what makes the build complain.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications, which uses java.time on API
        // levels below 26. Without this the release build fails at
        // `:app:checkReleaseAarMetadata` with "requires core library
        // desugaring to be enabled". The extra dependency is the desugaring
        // runtime that back-ports those APIs.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // DateDawn's permanent package name. This value is what Google Play uses
        // to identify the app: once the first bundle is uploaded it can NEVER be
        // changed, and every future `google-services.json` must be generated for
        // exactly this package name.
        applicationId = "com.datedawn.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Play requires a recent targetSdk for new uploads; 36 keeps the app
        // eligible and matches what the plugins are compiled against.
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Only declared when key.properties exists; declaring it with missing
        // values would fail configuration on every debug build too.
        if (hasUploadKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("release")
            } else {
                // No upload key on this machine: sign with the debug key so the
                // build still produces an installable artifact for smoke testing.
                // This bundle CANNOT be uploaded to Play — Play rejects it.
                logger.warn(
                    "[datedawn] android/key.properties not found: release build is " +
                        "signed with the DEBUG key. Do not upload this to Play."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    // The back-port of java.time that core library desugaring needs at runtime.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
