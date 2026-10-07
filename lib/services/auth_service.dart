import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_config.dart';

/// The signed-in identity, normalised so the UI never touches Firebase types.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;

  factory AppUser.fromFirebase(User user) => AppUser(
        id: user.uid,
        email: (user.email ?? '').toLowerCase(),
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isAnonymous: user.isAnonymous,
      );

  String get initials {
    final source =
        (displayName?.trim().isNotEmpty ?? false) ? displayName! : email;
    if (source.isEmpty) return 'U';
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// A failure worth showing the user. Firebase's own messages are developer-
/// facing ("Firebase: Error (auth/invalid-credential)"), so they are mapped to
/// plain sentences before they reach a SnackBar.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Everything the app needs from Firebase Authentication.
///
/// Google sign-in and email/password both work on Android, iOS and web, which
/// is exactly the free-tier surface this app targets. No server code is
/// involved: Firebase Auth issues and refreshes the tokens itself.
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? _defaultGoogleSignIn();

  /// Builds the Google client.
  ///
  /// google_sign_in 7 removed the bare `GoogleSignIn()` constructor. On mobile
  /// `instance` is the shared client and the scopes are supplied from the build
  /// config instead; the idToken the caller needs is still returned by
  /// `authentication`, so scopes are not repeated here. On web the `instance`
  /// singleton is created by the platform implementation relative to the current
  /// Firebase Auth domain, so it must not be constructed eagerly — the web
  /// branch in `signInWithGoogle` goes through Firebase's popup instead.
  static GoogleSignIn _defaultGoogleSignIn() {
    return GoogleSignIn.instance;
  }

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleSignInInitialization;

  /// Fires on every sign-in/sign-out. `null` means signed out.
  Stream<AppUser?> authStateChanges() => _auth
      .authStateChanges()
      .map((user) => user == null ? null : AppUser.fromFirebase(user));

  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : AppUser.fromFirebase(user);
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _freshToken(credential.user);
      return AppUser.fromFirebase(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      // Send the verification mail, but never block the sign-in on it — the app
      // is fully usable before the address is confirmed.
      unawaited(user.sendEmailVerification().catchError((_) {}));
      final current = _auth.currentUser ?? user;
      await _freshToken(current);
      return AppUser.fromFirebase(current);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  /// Forces a token refresh so claims written by a Firebase Auth blocking
  /// function are present before the first Supabase request.
  ///
  /// Supabase reads `role` from the JWT to pick a Postgres role; without it the
  /// request is `anon` and every RLS policy denies it. A blocking function
  /// stamps `role: 'authenticated'` during sign-up, but the token minted for the
  /// new session was created *before* that ran, so it must be re-minted here.
  ///
  /// Best-effort on purpose: if the claim is somehow still missing, the user is
  /// signed in and the app shows its normal "could not load" state rather than
  /// failing the sign-in itself.
  Future<void> _freshToken(User? user) async {
    if (user == null) return;
    try {
      await user.getIdToken(true);
    } catch (error) {
      debugPrint('[datedawn] Could not refresh the ID token: $error');
    }
  }

  /// Google sign-in.
  ///
  /// The flow differs per platform but the credential shape is the same:
  /// - **web**: `signInWithPopup` is the only option — `google_sign_in` on web
  ///   routes through it under the hood, and Firebase rejects a manual
  ///   `signInWithCredential` from a popup origin.
  /// - **mobile**: the native picker returns an idToken, which is exchanged for
  ///   a Firebase credential.
  Future<AppUser> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final credential = await _auth.signInWithPopup(provider);
        await _freshToken(credential.user);
        return AppUser.fromFirebase(credential.user!);
      }

      await (_googleSignInInitialization ??= _googleSignIn.initialize(
        serverClientId:
            googleServerClientId.isEmpty ? null : googleServerClientId,
      ));
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      await _freshToken(result.user);
      return AppUser.fromFirebase(result.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw AuthFailure(
          'Google sign-in needs an Android web client ID. Set '
          'GOOGLE_SERVER_CLIENT_ID and add this app’s signing SHA-1 to Firebase.',
          code: e.code.name,
        );
      }
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('Sign-in cancelled.', code: 'cancelled');
      }
      throw AuthFailure('Google sign-in failed. Please try again.',
          code: e.code.name);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure('Google sign-in failed. Please try again.',
          code: e.toString());
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  Future<void> signOut() async {
    // Google keeps its own session on mobile; clearing it avoids silently
    // re-signing the same account on the next tap.
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Not signed in with Google — nothing to clear.
      }
    }
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthFailure(
          'For security, please sign in again before deleting your account.',
          code: 'requires-recent-login',
        );
      }
      throw _mapException(e);
    }
  }

  AuthFailure _mapException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthFailure('That email address does not look right.',
            code: 'invalid-email');
      case 'user-disabled':
        return const AuthFailure('This account has been disabled.',
            code: 'user-disabled');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure(
          'Email or password is incorrect.',
          code: 'invalid-credential',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          'An account already exists for that email. Try signing in.',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthFailure(
          'Please choose a password of at least 6 characters.',
          code: 'weak-password',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          'That sign-in method is not enabled for this project yet.',
          code: 'operation-not-allowed',
        );
      case 'configuration-not-found':
        return const AuthFailure(
          'Firebase Authentication is not configured for this app yet. Enable '
          'Google and Email/Password sign-in in the Firebase console.',
          code: 'configuration-not-found',
        );
      case 'internal-error':
        if (e.message?.contains('CONFIGURATION_NOT_FOUND') ?? false) {
          return const AuthFailure(
            'Firebase Authentication is not configured for this app yet. Enable '
            'Google and Email/Password sign-in in the Firebase console.',
            code: 'configuration-not-found',
          );
        }
        return AuthFailure(
          e.message ?? 'Something went wrong signing you in.',
          code: e.code,
        );
      case 'network-request-failed':
        return const AuthFailure('No connection. Check your network and retry.',
            code: 'network-request-failed');
      case 'too-many-requests':
        return const AuthFailure(
          'Too many attempts. Please wait a moment and try again.',
          code: 'too-many-requests',
        );
      case 'popup-closed-by-user':
      case 'cancelled':
        return const AuthFailure('Sign-in cancelled.', code: 'cancelled');
      case 'account-exists-with-different-credential':
        return const AuthFailure(
          'That email is already registered with a different sign-in method.',
          code: 'account-exists-with-different-credential',
        );
      default:
        return AuthFailure(
          e.message ?? 'Something went wrong signing you in.',
          code: e.code,
        );
    }
  }
}
