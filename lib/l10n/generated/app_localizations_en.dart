// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Date Dawn';

  @override
  String get language => 'Language';

  @override
  String get followSystemLanguage => 'Follow system language';

  @override
  String get languageChanged => 'Language changed.';

  @override
  String get languageSaveFailed => 'Could not save your language preference.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get settings => 'Settings';

  @override
  String get dateDawnUser => 'Date Dawn user';

  @override
  String get guestAccount => 'Guest account';

  @override
  String get notSignedIn => 'You are not signed in';

  @override
  String get syncAndShareDescription =>
      'Sign in to sync your countdowns across every device and share them with other people.';

  @override
  String get signIn => 'Sign in';

  @override
  String get appearance => 'APPEARANCE';

  @override
  String get darkTheme => 'Dark';

  @override
  String get lightTheme => 'Light';

  @override
  String get systemTheme => 'System';

  @override
  String get time => 'TIME';

  @override
  String get timeFormatDescription =>
      'How clock times are written. Your countdowns are stored as exact moments either way — this only changes how they read.';

  @override
  String get twelveHourTime => '12-hour (AM/PM)';

  @override
  String get twentyFourHourTime => '24-hour';

  @override
  String get about => 'ABOUT';

  @override
  String get version => 'Version';

  @override
  String get sync => 'Sync';

  @override
  String get safety => 'SAFETY';

  @override
  String get blockedPeople => 'Blocked people';

  @override
  String get legal => 'LEGAL';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get helpAndSupport => 'Help & support';

  @override
  String get signOut => 'Sign out';

  @override
  String get signedOut => 'Signed out.';

  @override
  String countdownsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count countdowns',
      one: '$count countdown',
    );
    return '$_temp0';
  }

  @override
  String get welcomeToDateDawn => 'Welcome to Date Dawn';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get countdownsSyncDescription =>
      'Your countdowns sync to every device you sign in on.';

  @override
  String get welcomeDescription =>
      'Count down to the moments that matter — on phone, tablet and web.';

  @override
  String get name => 'Name';

  @override
  String get nameHint => 'Alex Rivera';

  @override
  String get nameRequired => 'Tell us what to call you.';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Enter your email.';

  @override
  String get emailInvalid => 'That does not look like an email.';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get passwordTooShort => 'Use at least 6 characters.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordPrompt =>
      'Enter your email first, then tap “Forgot password”.';

  @override
  String get signInConnectionError =>
      'Could not reach the sign-in service. Check your connection.';

  @override
  String get createAccount => 'Create account';

  @override
  String get or => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get newHere => 'New here? ';

  @override
  String get createOne => 'Create one';

  @override
  String get troubleSigningIn => 'Trouble signing in? Get help';

  @override
  String get accountCreated => 'Account created.';

  @override
  String get welcomeBack => 'Welcome back.';

  @override
  String get signInFailed => 'Could not complete sign in. Please try again.';

  @override
  String get signedInWithGoogle => 'Signed in with Google.';

  @override
  String get home => 'Home';

  @override
  String get invitations => 'Invitations';

  @override
  String get circles => 'Circles';

  @override
  String get notifications => 'Notifications';

  @override
  String get support => 'Support';
}
