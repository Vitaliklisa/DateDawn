import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// The app's display name.
  ///
  /// In en, this message translates to:
  /// **'Date Dawn'**
  String get appTitle;

  /// Settings label for choosing the app language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Choice that follows the device language and clears a saved language preference.
  ///
  /// In en, this message translates to:
  /// **'Follow system language'**
  String get followSystemLanguage;

  /// Confirmation after the user changes the app language.
  ///
  /// In en, this message translates to:
  /// **'Language changed.'**
  String get languageChanged;

  /// Error shown when saving the selected language fails.
  ///
  /// In en, this message translates to:
  /// **'Could not save your language preference.'**
  String get languageSaveFailed;

  /// Display name of English in the language picker.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Display name of French in the language picker.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// Display name of Spanish in the language picker.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Fallback display name for an account with no name.
  ///
  /// In en, this message translates to:
  /// **'Date Dawn user'**
  String get dateDawnUser;

  /// Account type label for a guest.
  ///
  /// In en, this message translates to:
  /// **'Guest account'**
  String get guestAccount;

  /// Message shown in Settings to signed-out users.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in'**
  String get notSignedIn;

  /// Explains the benefits of signing in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your countdowns across every device and share them with other people.'**
  String get syncAndShareDescription;

  /// Action and label to sign into an account.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Settings section heading for theme preferences.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Theme option that follows the device.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// Settings section heading for clock display.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get time;

  /// Explains the time format preference.
  ///
  /// In en, this message translates to:
  /// **'How clock times are written. Your countdowns are stored as exact moments either way — this only changes how they read.'**
  String get timeFormatDescription;

  /// Twelve-hour clock display option.
  ///
  /// In en, this message translates to:
  /// **'12-hour (AM/PM)'**
  String get twelveHourTime;

  /// Twenty-four-hour clock display option.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get twentyFourHourTime;

  /// Settings section heading for app information.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about;

  /// Label for the app version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Label for synchronization service.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// Settings section heading for safety controls.
  ///
  /// In en, this message translates to:
  /// **'SAFETY'**
  String get safety;

  /// Link to the list of blocked people.
  ///
  /// In en, this message translates to:
  /// **'Blocked people'**
  String get blockedPeople;

  /// Settings section heading for legal documents.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get legal;

  /// Link to the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// Link to the terms of service.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// Link to help and support.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpAndSupport;

  /// Action to sign out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Confirmation after signing out.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get signedOut;

  /// Number of countdowns associated with the account.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# countdown} other{# countdowns}}'**
  String countdownsCount(int count);

  /// Login headline.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Date Dawn'**
  String get welcomeToDateDawn;

  /// Registration headline.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// Registration description.
  ///
  /// In en, this message translates to:
  /// **'Your countdowns sync to every device you sign in on.'**
  String get countdownsSyncDescription;

  /// Login description.
  ///
  /// In en, this message translates to:
  /// **'Count down to the moments that matter — on phone, tablet and web.'**
  String get welcomeDescription;

  /// Name field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Example name in the registration field.
  ///
  /// In en, this message translates to:
  /// **'Alex Rivera'**
  String get nameHint;

  /// Validation shown when a name is missing.
  ///
  /// In en, this message translates to:
  /// **'Tell us what to call you.'**
  String get nameRequired;

  /// Email address field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Example email address in the email field.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// Validation shown when email is missing.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get emailRequired;

  /// Validation shown when email is malformed.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email.'**
  String get emailInvalid;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Validation shown when password is missing.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// Validation shown when password is too short.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get passwordTooShort;

  /// Action to request a password reset.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Prompt shown when password reset is tapped without an email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first, then tap “Forgot password”.'**
  String get forgotPasswordPrompt;

  /// Message shown when authentication cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the sign-in service. Check your connection.'**
  String get signInConnectionError;

  /// Action that creates a new account.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// Divider between sign-in methods.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Google sign-in action.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Prefix for switching from registration to sign-in.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Prefix for switching from sign-in to registration.
  ///
  /// In en, this message translates to:
  /// **'New here? '**
  String get newHere;

  /// Action to switch from sign-in to registration.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// Link to support from the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Trouble signing in? Get help'**
  String get troubleSigningIn;

  /// Confirmation after account creation.
  ///
  /// In en, this message translates to:
  /// **'Account created.'**
  String get accountCreated;

  /// Confirmation after signing in.
  ///
  /// In en, this message translates to:
  /// **'Welcome back.'**
  String get welcomeBack;

  /// Generic sign-in failure message.
  ///
  /// In en, this message translates to:
  /// **'Could not complete sign in. Please try again.'**
  String get signInFailed;

  /// Confirmation after Google sign-in.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Google.'**
  String get signedInWithGoogle;

  /// Home navigation destination.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Invitations navigation destination.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// Circles navigation destination.
  ///
  /// In en, this message translates to:
  /// **'Circles'**
  String get circles;

  /// Notifications navigation destination.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Support navigation destination.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
