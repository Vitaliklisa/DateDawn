# Project-specific R8 / ProGuard rules.
#
# Applied from android/app/build.gradle.kts:
#   proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"),
#                 "proguard-rules.pro")
#
# The rules below are the ones R8 needs so that enabling shrinking does not
# break reflection-based code at runtime. Firebase, play-services and the
# plugins all reach their classes by name, so a class R8 decides is "unused" is
# still needed at runtime — dropping it shows up as a crash on first sign-in or
# a silent Auth failure, never as a build error.

# --- Firebase / Google Play Services ---
# The `com.google.firebase.provider.FirebaseInitProvider` and the
# `-keep` rules that ship inside each Firebase AAR cover most of the graph;
# these are the top-level safety nets for classes R8 cannot see referenced.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore's transport is a mix of generic-heavy, reflective code paths; the
# default optimize pass otherwise rewrites them into something that fails at
# runtime with a ClassCastException inside the Firestore pipeline.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod

# --- Google Sign-In ---
# Credential Manager / play-services-auth resolve account data reflectively.
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# --- flutter_local_notifications ---
# Serialises scheduled notifications to shared preferences and re-reads them by
# class name after a reboot (see the plugin's ScheduledNotificationReceiver).
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# --- share_plus / shared_preferences ---
# These expose plugin channels via reflection-free generated registration, but
# their `*Plugin` entry points and Pigeon-generated classes are still looked up
# by name by the Flutter engine.
-keep class io.flutter.plugins.** { *; }

# Keep line numbers so a Play Console stack trace is actually readable. Without
# this the crash report names only obfuscated frames (`a.b.c`), which makes a
# field crash impossible to diagnose. Omit the -renamesourcefileattribute line
# to keep the real file name in traces — the size cost is negligible.
-keepattributes SourceFile,LineNumberTable

# Suppress warnings for optional Firebase transitive deps that the app does not
# include (e.g. the desktop/server SDKs), which would otherwise fail the build.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn kotlinx.**

# If you use WebView with a JS interface, uncomment and name the class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}
