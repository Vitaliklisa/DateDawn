# ==============================================================================
# DateDawn — Optimized R8 / ProGuard Configuration
# ==============================================================================
# Applied from android/app/build.gradle.kts:
#   proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"),
#                 "proguard-rules.pro")
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Essential Attributes for Flutter & Firebase Reflection/Serialization
# ------------------------------------------------------------------------------
# Preserves generic type signatures required by Firestore deserialization,
# runtime annotations, and inner class references.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod

# Retain line numbers and source file names for readable Play Console stack traces.
-keepattributes SourceFile,LineNumberTable

# ------------------------------------------------------------------------------
# 2. Flutter Engine Core
# ------------------------------------------------------------------------------
# Keep JNI entry points and generated plugin registrar interfaces.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# ------------------------------------------------------------------------------
# 3. Firebase & Google Play Services (Targeted Rules)
# ------------------------------------------------------------------------------
# Firebase SDKs ship their own R8 consumer rules inside their AARs (META-INF/com.android.tools/r8/).
# Do NOT use broad wildcard rules like "-keep class com.google.firebase.** { *; }"
# as they disable shrinking for the entire Firebase graph.

# Suppress harmless missing dependency warnings for transitive library paths.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn kotlinx.**
-dontwarn com.google.protobuf.**
-dontwarn com.google.android.play.core.**

# ------------------------------------------------------------------------------
# 4. App Plugins (Targeted Keep Rules)
# ------------------------------------------------------------------------------
# flutter_local_notifications: keep models serialized into SharedPreferences
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
