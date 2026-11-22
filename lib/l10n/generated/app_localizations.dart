import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('uk'),
    Locale('zh')
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
  /// **'French'**
  String get languageFrench;

  /// Display name of Spanish in the language picker.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// Display name of Ukrainian in the language picker.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get languageUkrainian;

  /// Display name of German in the language picker.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// Display name of Traditional Chinese (Taiwan) in the language picker.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese (Taiwan)'**
  String get languageChinese;

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
  /// **'{count, plural, one{{count} countdown} other{{count} countdowns}}'**
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

  /// Empty home screen headline.
  ///
  /// In en, this message translates to:
  /// **'Name a day.'**
  String get homeEmptyTitle;

  /// Empty home screen introduction.
  ///
  /// In en, this message translates to:
  /// **'Pick a future moment — a wedding, a launch, a trip home. Date Dawn counts the years, months, days and hours left, then celebrates when it arrives.'**
  String get homeEmptyDescription;

  /// Error when the home countdown list cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Could not reach your countdowns. Pull down to try again.'**
  String get homeLoadError;

  /// Action for a signed-out user to begin creating a countdown.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// Home screen title for countdown syncing.
  ///
  /// In en, this message translates to:
  /// **'Keep them everywhere'**
  String get homeSyncTitle;

  /// Home screen explanation of syncing and sharing.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your countdowns across phone, tablet and web — and to share them with the people counting down with you.'**
  String get homeSyncDescription;

  /// Heading for the secondary countdown list.
  ///
  /// In en, this message translates to:
  /// **'OTHER COUNTDOWNS'**
  String get otherCountdowns;

  /// Status shown when a countdown moment has arrived.
  ///
  /// In en, this message translates to:
  /// **'ARRIVED'**
  String get arrived;

  /// Status shown while a countdown is active.
  ///
  /// In en, this message translates to:
  /// **'COUNTING DOWN'**
  String get countingDown;

  /// Button and tooltip for more countdown actions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// Action to open a countdown.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// Action to open a countdown detail page.
  ///
  /// In en, this message translates to:
  /// **'Open countdown'**
  String get openCountdown;

  /// Title for the new countdown screen.
  ///
  /// In en, this message translates to:
  /// **'New countdown'**
  String get newCountdown;

  /// Title for editing a countdown.
  ///
  /// In en, this message translates to:
  /// **'Edit countdown'**
  String get editCountdown;

  /// Countdown title field label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get countdownTitleLabel;

  /// Countdown description field label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get countdownDescriptionLabel;

  /// Heading for the countdown date and time.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get whenLabel;

  /// Example countdown title shown in the title field.
  ///
  /// In en, this message translates to:
  /// **'Wedding, launch, reunion'**
  String get titleExampleHint;

  /// Hint for the optional countdown description.
  ///
  /// In en, this message translates to:
  /// **'A short note about the day'**
  String get descriptionExampleHint;

  /// Date picker label.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// Time picker label.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// Quick date preset for one week from now.
  ///
  /// In en, this message translates to:
  /// **'+1 week'**
  String get presetWeek;

  /// Quick date preset for one month from now.
  ///
  /// In en, this message translates to:
  /// **'+1 month'**
  String get presetMonth;

  /// Quick date preset for one year from now.
  ///
  /// In en, this message translates to:
  /// **'+1 year'**
  String get presetYear;

  /// Quick date preset for five years from now.
  ///
  /// In en, this message translates to:
  /// **'+5 years'**
  String get presetFiveYears;

  /// Action to create a countdown.
  ///
  /// In en, this message translates to:
  /// **'Create countdown'**
  String get createCountdown;

  /// Action to save edits to a countdown.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// Action to delete a countdown.
  ///
  /// In en, this message translates to:
  /// **'Delete countdown'**
  String get deleteCountdown;

  /// Tooltip for the countdown action menu.
  ///
  /// In en, this message translates to:
  /// **'Countdown actions'**
  String get countdownActions;

  /// Confirmation title before deleting a countdown.
  ///
  /// In en, this message translates to:
  /// **'Delete this countdown?'**
  String get deleteCountdownQuestion;

  /// Warning that deleting a countdown cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'The countdown cannot be undone.'**
  String get countdownCannotUndo;

  /// Validation when the countdown title is empty.
  ///
  /// In en, this message translates to:
  /// **'Give this countdown a title.'**
  String get giveCountdownTitle;

  /// Validation when the selected countdown moment has passed.
  ///
  /// In en, this message translates to:
  /// **'Pick a moment still ahead of you.'**
  String get pickFutureMoment;

  /// Message shown when a signed-out user tries to save.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save countdowns.'**
  String get signInToSaveCountdown;

  /// Confirmation after creating a countdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown created.'**
  String get countdownCreated;

  /// Confirmation after editing a countdown.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get changesSaved;

  /// Confirmation after deleting a countdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown deleted.'**
  String get countdownDeleted;

  /// Fallback name for a user's partner.
  ///
  /// In en, this message translates to:
  /// **'your partner'**
  String get partnerLabel;

  /// Warning when a partner could not be automatically added.
  ///
  /// In en, this message translates to:
  /// **'Countdown created, but {partnerName} was not added. Invite them manually from the countdown.'**
  String partnerNotAdded(String partnerName);

  /// Confirmation when a partner is automatically added.
  ///
  /// In en, this message translates to:
  /// **'Countdown created. {partnerName} was added.'**
  String partnerAdded(String partnerName);

  /// Warning when automatic partner sharing did not add anyone.
  ///
  /// In en, this message translates to:
  /// **'Countdown created, but no partner was added. Invite them manually.'**
  String get noPartnerAdded;

  /// Preview shown when the selected date is in the past.
  ///
  /// In en, this message translates to:
  /// **'Choose a future date to see the countdown.'**
  String get chooseFutureDateHint;

  /// Countdown preview followed by the remaining time.
  ///
  /// In en, this message translates to:
  /// **'Counting down {remaining}'**
  String countingDownRemaining(String remaining);

  /// Notice shown to a user without edit permission.
  ///
  /// In en, this message translates to:
  /// **'You can view this countdown but not change it.'**
  String get cannotEditCountdown;

  /// Heading for selecting circles to share a countdown with.
  ///
  /// In en, this message translates to:
  /// **'Share with'**
  String get shareWith;

  /// Explains how circle sharing works in the countdown editor.
  ///
  /// In en, this message translates to:
  /// **'A couple circle shares instantly. Other circles get an invitation.'**
  String get circleShareDescription;

  /// Heading for people on a countdown.
  ///
  /// In en, this message translates to:
  /// **'Collaborators'**
  String get collaborators;

  /// Description of collaborator access.
  ///
  /// In en, this message translates to:
  /// **'Anyone you invite can follow this countdown on their own devices.'**
  String get collaboratorsCanFollow;

  /// Description of the countdown collaborators list.
  ///
  /// In en, this message translates to:
  /// **'People following this countdown.'**
  String get peopleFollowing;

  /// Empty state for countdown collaborators.
  ///
  /// In en, this message translates to:
  /// **'No one else yet.'**
  String get noCollaboratorsYet;

  /// Example email address in an invitation field.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get nameEmailHint;

  /// Error loading recent invite suggestions.
  ///
  /// In en, this message translates to:
  /// **'Recent contacts could not load. Check your connection or Firestore rules.'**
  String get recentContactsCouldNotLoad;

  /// Confirmation after sending an invitation.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {email}.'**
  String invitationSentTo(String email);

  /// Countdown collaborator row representing a shared circle.
  ///
  /// In en, this message translates to:
  /// **'Shared with {circleName}'**
  String sharedWithCircle(String circleName);

  /// Action to resend a declined invitation.
  ///
  /// In en, this message translates to:
  /// **'Invite again'**
  String get inviteAgain;

  /// Confirmation title before removing a countdown collaborator.
  ///
  /// In en, this message translates to:
  /// **'Remove this person?'**
  String get removePersonQuestion;

  /// Explains the effect of removing a collaborator.
  ///
  /// In en, this message translates to:
  /// **'{email} will lose access to this countdown and will no longer see it in their list.'**
  String collaboratorLosesAccess(String email);

  /// Action to change a collaborator's role.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get changeRole;

  /// Title for the collaborator role picker.
  ///
  /// In en, this message translates to:
  /// **'Change role for {personName}'**
  String changeRoleFor(String personName);

  /// Explains collaborator role changes.
  ///
  /// In en, this message translates to:
  /// **'This changes what they can do on this countdown from now on. They currently have {role} access.'**
  String roleChangeDescription(String role);

  /// Explains why some collaborator roles are unavailable.
  ///
  /// In en, this message translates to:
  /// **'{roles} cannot be assigned by you — you are {topRole}.'**
  String rolesNotAssignable(String roles, String topRole);

  /// Introductory heading on the circles page.
  ///
  /// In en, this message translates to:
  /// **'Groups you count down with'**
  String get circlesDescriptionTitle;

  /// Explains circles and automatic couple sharing.
  ///
  /// In en, this message translates to:
  /// **'Invite someone to a circle once, then share any countdown with the whole group in a single tap. A couple circle shares automatically — anything one of you creates, the other sees.'**
  String get circlesDescription;

  /// Error loading the user's circles.
  ///
  /// In en, this message translates to:
  /// **'Could not load your circles. Pull down to retry.'**
  String get circlesLoadError;

  /// Empty state title for the circles page.
  ///
  /// In en, this message translates to:
  /// **'No circles yet'**
  String get noCircles;

  /// Empty state explanation for circles.
  ///
  /// In en, this message translates to:
  /// **'Create one for the people you count down with — a partner, family, or the friends you take a trip with every year.'**
  String get noCirclesDescription;

  /// Action and title for creating a circle.
  ///
  /// In en, this message translates to:
  /// **'New circle'**
  String get newCircle;

  /// Label for a couple circle that automatically shares countdowns.
  ///
  /// In en, this message translates to:
  /// **'Shares automatically'**
  String get sharesAutomatically;

  /// Number of people in a circle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} person} other{{count} people}}'**
  String peopleCount(int count);

  /// Tooltip for inviting a circle member.
  ///
  /// In en, this message translates to:
  /// **'Invite someone'**
  String get inviteSomeone;

  /// Label for the current user in a member list.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Action to leave a circle.
  ///
  /// In en, this message translates to:
  /// **'Leave circle'**
  String get leaveCircle;

  /// Action to delete a circle.
  ///
  /// In en, this message translates to:
  /// **'Delete circle'**
  String get deleteCircle;

  /// Tooltip for removing a circle member.
  ///
  /// In en, this message translates to:
  /// **'Remove from circle'**
  String get removeFromCircle;

  /// Confirmation title for removing a member from a circle.
  ///
  /// In en, this message translates to:
  /// **'Remove {personName}?'**
  String removeMemberQuestion(String personName);

  /// Explains the effect of removing a circle member.
  ///
  /// In en, this message translates to:
  /// **'They will stop seeing countdowns shared with this circle. Nothing they created is deleted.'**
  String get removeMemberExplanation;

  /// Confirmation title for leaving a circle.
  ///
  /// In en, this message translates to:
  /// **'Leave “{circleName}”?'**
  String leaveCircleQuestion(String circleName);

  /// Explains the effect of leaving a circle.
  ///
  /// In en, this message translates to:
  /// **'Countdowns shared with this circle will no longer appear for you. You can be invited back.'**
  String get leaveCircleExplanation;

  /// Confirmation title for deleting a circle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{circleName}”?'**
  String deleteCircleQuestion(String circleName);

  /// Explains the effect of deleting a circle.
  ///
  /// In en, this message translates to:
  /// **'The group goes away. Countdowns shared with it are kept and stay yours — they are just no longer shared with these people.'**
  String get deleteCircleExplanation;

  /// Example name for a circle.
  ///
  /// In en, this message translates to:
  /// **'Family, Tokyo 2027, Us'**
  String get circleNameHint;

  /// Title for the automatic couple-sharing option.
  ///
  /// In en, this message translates to:
  /// **'This is us — a couple'**
  String get coupleCircleTitle;

  /// Explains automatic sharing in a couple circle.
  ///
  /// In en, this message translates to:
  /// **'Countdowns are shared with your partner automatically, with no invitation to accept.'**
  String get coupleCircleDescription;

  /// Confirmation after creating a circle.
  ///
  /// In en, this message translates to:
  /// **'Circle created.'**
  String get circleCreated;

  /// Confirmation after creating a couple circle.
  ///
  /// In en, this message translates to:
  /// **'Created. Invite your partner next.'**
  String get coupleCircleCreated;

  /// Title for inviting someone to a couple circle.
  ///
  /// In en, this message translates to:
  /// **'Invite your partner'**
  String get inviteYourPartner;

  /// Title for inviting someone to a circle.
  ///
  /// In en, this message translates to:
  /// **'Invite to “{circleName}”'**
  String inviteToCircle(String circleName);

  /// Explains how invitations to a couple circle work.
  ///
  /// In en, this message translates to:
  /// **'If they already have an account, they will be added automatically. Otherwise, they will be added when they sign in. Future countdowns shared with this circle will appear automatically.'**
  String get coupleInviteExplanation;

  /// Explains invitations to a regular circle.
  ///
  /// In en, this message translates to:
  /// **'They will get an invitation to accept or decline. After they join, you can share countdowns with this circle in one tap.'**
  String get circleInviteExplanation;

  /// Example email address for inviting a circle member.
  ///
  /// In en, this message translates to:
  /// **'them@example.com'**
  String get inviteEmailHint;

  /// Action to send an invitation.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get sendInvitation;

  /// Confirmation that a partner will be added automatically.
  ///
  /// In en, this message translates to:
  /// **'Your partner will be added automatically.'**
  String get partnerAddedAutomatically;

  /// Message shown when signed-out users open circles.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use circles'**
  String get signInToUseCircles;

  /// Explains why a circle invitation requires an account.
  ///
  /// In en, this message translates to:
  /// **'Circles invite people by email, so they need an account to be invited to.'**
  String get circlesRequireAccounts;

  /// Invitations page heading for invitations awaiting a response.
  ///
  /// In en, this message translates to:
  /// **'Waiting on you'**
  String get waitingOnYou;

  /// Explains how invitations work when none are waiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing is shared with you until you accept. Declining tells the person who invited you, so they are not left guessing.'**
  String get invitationsEmptyDescription;

  /// Message shown when signed-out users open invitations.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see invitations'**
  String get signInToSeeInvitations;

  /// Explains which account to use to see invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations are addressed to your email, so sign in with the address someone invited.'**
  String get invitationsEmailAccount;

  /// Error loading invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations could not load. Check your connection or Firestore rules.'**
  String get invitationsCouldNotLoad;

  /// Empty invitation inbox heading.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting'**
  String get nothingWaiting;

  /// Empty invitation inbox explanation.
  ///
  /// In en, this message translates to:
  /// **'Invitations people send you will appear here. Countdown and standard circle invitations need your response; couple circles join automatically.'**
  String get invitationInboxEmpty;

  /// Action to retry automatically adding a user to a circle.
  ///
  /// In en, this message translates to:
  /// **'Retry adding you'**
  String get retryAddingYou;

  /// Action to decline an invitation.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// Confirmation before joining a countdown invitation.
  ///
  /// In en, this message translates to:
  /// **'Join “{eventTitle}”?'**
  String joinInviteQuestion(String eventTitle);

  /// Explains the effect of accepting a countdown invitation.
  ///
  /// In en, this message translates to:
  /// **'It will appear in your list and you will get its countdown on this device.'**
  String get joinInviteExplanation;

  /// Action to join a shared countdown or circle.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Notice shown when the user already belongs to an invited circle.
  ///
  /// In en, this message translates to:
  /// **'You are already a member of “{name}”.'**
  String alreadyMemberOf(String name);

  /// Confirmation after joining a countdown or circle.
  ///
  /// In en, this message translates to:
  /// **'You joined “{name}”.'**
  String youJoined(String name);

  /// Confirmation after being added to a circle.
  ///
  /// In en, this message translates to:
  /// **'You were added to “{name}”.'**
  String youWereAddedTo(String name);

  /// Confirmation after declining an invitation.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined.'**
  String get invitationDeclined;

  /// Invitation type label for a shared countdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown invitation'**
  String get countdownInvitation;

  /// Fallback title for an unnamed countdown.
  ///
  /// In en, this message translates to:
  /// **'A countdown'**
  String get aCountdown;

  /// Explanation of a countdown invitation.
  ///
  /// In en, this message translates to:
  /// **'You have been invited to follow this countdown. Accepting adds it to your list as {role}.'**
  String invitedToFollowCountdown(String role);

  /// Action to accept an invitation.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Invitation type label for a couple circle.
  ///
  /// In en, this message translates to:
  /// **'Partner invitation'**
  String get partnerInvitation;

  /// Invitation type label for a circle.
  ///
  /// In en, this message translates to:
  /// **'Circle invitation'**
  String get circleInvitation;

  /// Title shown for an automatic couple circle invitation.
  ///
  /// In en, this message translates to:
  /// **'You’re being added to {personName}’s circle'**
  String partnerCircleAddTitle(String personName);

  /// Explains automatic joining of a couple circle.
  ///
  /// In en, this message translates to:
  /// **'You will be added automatically. Countdown events shared with this circle will show up in your list.'**
  String get partnerCircleAddExplanation;

  /// Explains what happens when joining a regular circle.
  ///
  /// In en, this message translates to:
  /// **'Joining “{circleName}” means the countdowns they share with this circle will show up in your list.'**
  String circleJoinExplanation(String circleName);

  /// Action to join a couple circle.
  ///
  /// In en, this message translates to:
  /// **'Become partners'**
  String get becomePartners;

  /// Action to join a circle.
  ///
  /// In en, this message translates to:
  /// **'Join circle'**
  String get joinCircle;

  /// Error when automatically joining a couple circle fails.
  ///
  /// In en, this message translates to:
  /// **'Automatic join could not be completed.'**
  String get automaticJoinFailed;

  /// Action to dismiss a prompt.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// Notifications screen title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Action to mark all notifications as read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// Confirmation after marking notifications as read.
  ///
  /// In en, this message translates to:
  /// **'Marked all read.'**
  String get markedAllRead;

  /// Tooltip for a menu containing more options.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// Notice when there are no read notifications to delete.
  ///
  /// In en, this message translates to:
  /// **'No read messages to delete.'**
  String get noReadMessagesToDelete;

  /// Action to delete read notifications.
  ///
  /// In en, this message translates to:
  /// **'Delete read messages'**
  String get deleteReadMessages;

  /// Confirmation after deleting read notifications.
  ///
  /// In en, this message translates to:
  /// **'Deleted read messages.'**
  String get deletedReadMessages;

  /// Empty notification state title for signed-out users.
  ///
  /// In en, this message translates to:
  /// **'Sign in first'**
  String get notificationsSignInFirst;

  /// Explains that notifications require an account.
  ///
  /// In en, this message translates to:
  /// **'Notifications are tied to your account.'**
  String get notificationsAccountOnly;

  /// Generic title when content cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get couldNotLoad;

  /// Network retry guidance.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnectionRetry;

  /// Empty notifications screen title.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get nothingYet;

  /// Empty notifications screen explanation.
  ///
  /// In en, this message translates to:
  /// **'When something happens with your countdowns or invitations, it will show up here.'**
  String get notificationsEmptyDescription;

  /// Warning when live notifications cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Live notifications could not be loaded.'**
  String get liveNotificationsCouldNotLoad;

  /// Heading for the notifications inbox.
  ///
  /// In en, this message translates to:
  /// **'INBOX'**
  String get inbox;

  /// Heading for invitation response notifications.
  ///
  /// In en, this message translates to:
  /// **'INVITATION RESPONSES'**
  String get invitationResponses;

  /// Warning when invitation responses cannot be loaded.
  ///
  /// In en, this message translates to:
  /// **'Invitation responses could not be loaded.'**
  String get invitationResponsesCouldNotLoad;

  /// Message shown when a countdown cannot be found.
  ///
  /// In en, this message translates to:
  /// **'This countdown is no longer available.'**
  String get countdownUnavailable;

  /// Action to view countdown details without editing.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// Heading for people who can see a countdown.
  ///
  /// In en, this message translates to:
  /// **'SHARED WITH'**
  String get sharedWith;

  /// Heading for countdown notes.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get notes;

  /// Empty state for countdown notes.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Leave a thought for everyone counting down with you.'**
  String get notesEmpty;

  /// Hint for adding a note to a countdown.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get addNote;

  /// Countdown unit label for years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// Countdown unit label for months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// Countdown unit label for days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// Countdown unit label for hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// Short minute unit shown in the live countdown.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String remainingMinutes(int count);

  /// Short second unit shown in the live countdown.
  ///
  /// In en, this message translates to:
  /// **'{count} sec remaining'**
  String remainingSeconds(int count);

  /// Action to cancel a dialog or operation.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Action to keep an item instead of deleting it.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// Action to stay in a circle.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// Action to leave a circle.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// Action to remove a person or item.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Destructive action to delete an item.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Action to create an item.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Action to retry after an error.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Action to share a countdown.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Status for a countdown whose moment has passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// Status for a future countdown.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// Invitation status after acceptance.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// Invitation status after decline.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// Invitation status after removal.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get removed;

  /// Invitation status after it is sent again.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get reopened;

  /// Invitation status while awaiting a response.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// Countdown summary for a moment that has arrived.
  ///
  /// In en, this message translates to:
  /// **'It has arrived.'**
  String get itHasArrived;

  /// Countdown summary for the time left until an event.
  ///
  /// In en, this message translates to:
  /// **'{remaining} to go'**
  String remainingToGo(String remaining);

  /// Countdown summary after a moment has passed.
  ///
  /// In en, this message translates to:
  /// **'The moment has passed'**
  String get momentHasPassed;

  /// Conjunction between the final units in a remaining-time summary.
  ///
  /// In en, this message translates to:
  /// **'{first} and {last}'**
  String remainingAnd(String first, String last);

  /// Celebration heading when a countdown reaches its date.
  ///
  /// In en, this message translates to:
  /// **'THE DAY HAS COME'**
  String get dayHasCome;

  /// Celebration message with an event description.
  ///
  /// In en, this message translates to:
  /// **'{title} is here — {description}'**
  String eventArrivedWithDescription(String title, String description);

  /// Celebration message without an event description.
  ///
  /// In en, this message translates to:
  /// **'{title} is here — enjoy every minute of it.'**
  String eventArrivedTitleOnly(String title);

  /// Confirmation after removing a circle member.
  ///
  /// In en, this message translates to:
  /// **'{personName} was removed from “{circleName}”.'**
  String personRemovedFromCircle(String personName, String circleName);

  /// Confirmation after leaving a circle.
  ///
  /// In en, this message translates to:
  /// **'You left “{circleName}”.'**
  String youLeftCircle(String circleName);

  /// Confirmation after deleting a circle.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{circleName}”.'**
  String circleDeleted(String circleName);

  /// Fallback name for an inviter whose name is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// Title for a circle invitation.
  ///
  /// In en, this message translates to:
  /// **'{personName} invited you to “{circleName}”'**
  String invitedYouToCircle(String personName, String circleName);

  /// Administrator role label.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// Editor role label.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get roleEditor;

  /// Viewer role label.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// Description of administrator countdown access.
  ///
  /// In en, this message translates to:
  /// **'Can manage the countdown and its participants.'**
  String get roleAdminDescription;

  /// Description of editor countdown access.
  ///
  /// In en, this message translates to:
  /// **'Can edit the countdown and invite others.'**
  String get roleEditorDescription;

  /// Description of viewer countdown access.
  ///
  /// In en, this message translates to:
  /// **'Can view the countdown and leave notes.'**
  String get roleViewerDescription;

  /// Long-form pluralized years in the remaining-time summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} year} other{{count} years}}'**
  String remainingYears(int count);

  /// Long-form pluralized months in the remaining-time summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} month} other{{count} months}}'**
  String remainingMonths(int count);

  /// Long-form pluralized days in the remaining-time summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String remainingDays(int count);

  /// Long-form pluralized hours in the remaining-time summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hour} other{{count} hours}}'**
  String remainingHours(int count);

  /// Long-form pluralized minutes in the remaining-time summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} minute} other{{count} minutes}}'**
  String remainingMinuteUnit(int count);

  /// Long-form pluralized seconds in the remaining-time summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} second} other{{count} seconds}}'**
  String remainingSecondUnit(int count);

  /// Tooltip for additional item actions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// Action to block a person.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// Confirmation after changing a collaborator's role.
  ///
  /// In en, this message translates to:
  /// **'{personName} is now {role}.'**
  String roleChanged(String personName, String role);

  /// Confirmation after removing a collaborator.
  ///
  /// In en, this message translates to:
  /// **'{personName} was removed.'**
  String personRemoved(String personName);

  /// Title shown when sign-in is required to save a countdown.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save it'**
  String get signInToSaveIt;

  /// Explains why countdowns are saved to an account.
  ///
  /// In en, this message translates to:
  /// **'Countdowns live in your account, so they follow you to every device and can be shared with other people.'**
  String get countdownsFollowYou;

  /// Actionable message for a Firestore permission error while saving.
  ///
  /// In en, this message translates to:
  /// **'Firestore refused the save. If this keeps happening, the deployed security rules are older than the app — run `firebase deploy --only firestore:rules`.'**
  String get savePermissionError;

  /// Message for a network failure while saving.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Firestore. Check your connection and try again.'**
  String get saveNetworkError;

  /// Generic message for an unexpected save failure.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get saveFailed;

  /// Remaining-time text when a countdown has passed.
  ///
  /// In en, this message translates to:
  /// **'The moment has passed'**
  String get momentPassed;

  /// Conjunction between the final two units in a remaining-time summary.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// Back navigation tooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Last-updated note at the top of the legal policy.
  ///
  /// In en, this message translates to:
  /// **'Last updated: February 2026 · Compliant with EU GDPR & Canada PIPEDA'**
  String get policyLastUpdated;

  /// First privacy policy section heading.
  ///
  /// In en, this message translates to:
  /// **'1. Introduction & Data Controller'**
  String get privacyIntroTitle;

  /// Introduction and data controller contact in the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Date Dawn (\"we\", \"our\", or \"us\") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile and web applications, in full compliance with the EU General Data Protection Regulation (GDPR) and the Personal Information Protection and Electronic Documents Act (PIPEDA) of Canada.\n\nData Controller Contact: {supportEmail}'**
  String privacyIntroBody(String supportEmail);

  /// Second privacy policy section heading.
  ///
  /// In en, this message translates to:
  /// **'2. Information We Collect'**
  String get privacyCollectTitle;

  /// Information collected and not collected, as described in the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'• Account Data: Email address and display name provided during authentication (Firebase Auth).\n• User Content: Countdowns, titles, dates, descriptions, and circle memberships you explicitly create or share.\n• Device & Notification Data: Push notification tokens to deliver countdown reminders and invitation alerts.\n\nWe do NOT collect browsing history, advertising identifiers, location data, or sell any personal information to third parties.'**
  String get privacyCollectBody;

  /// Third privacy policy section heading.
  ///
  /// In en, this message translates to:
  /// **'3. Legal Basis for Processing (EU GDPR)'**
  String get privacyBasisTitle;

  /// Legal bases for processing personal data.
  ///
  /// In en, this message translates to:
  /// **'We process your data under the following lawful bases:\n• Contractual Necessity: Providing countdown syncing, circle sharing, and invitation features.\n• Consent: When you grant push notification permissions or opt-in to shared circles.\n• Legitimate Interests: Ensuring application security, reliability, and preventing abuse.'**
  String get privacyBasisBody;

  /// Fourth privacy policy section heading.
  ///
  /// In en, this message translates to:
  /// **'4. Sharing & Blocking'**
  String get privacySharingTitle;

  /// Privacy policy explanation of sharing and blocking.
  ///
  /// In en, this message translates to:
  /// **'Date Dawn lets people interact one-to-one: you can invite someone to a countdown, and both of you can leave notes on one you share. That content is visible only to the people on that countdown — never public, never shown to anyone else.\n\nYou can block another person at any time: open a countdown you share with them and long-press their name (or secondary-click it on desktop). Blocking removes you from each other’s countdowns, cancels invitations between you, and stops them inviting you again. The person is not told. The list of people you have blocked is private to you, and you can unblock anyone from Settings → Blocked people.'**
  String get privacySharingBody;

  /// Fifth privacy policy section heading.
  ///
  /// In en, this message translates to:
  /// **'5. Data Storage & Security'**
  String get privacyStorageTitle;

  /// Privacy policy explanation of data storage and security.
  ///
  /// In en, this message translates to:
  /// **'Your data is securely stored and processed using Firebase (Google Cloud Platform) infrastructure adhering to high industry security standards. Data transmitted between your device and our servers is encrypted in transit using TLS.'**
  String get privacyStorageBody;

  /// Sixth privacy policy section heading.
  ///
  /// In en, this message translates to:
  /// **'6. Your Rights (Access, Correction & Erasure)'**
  String get privacyRightsTitle;

  /// User rights to access, correct, and erase personal data.
  ///
  /// In en, this message translates to:
  /// **'Under GDPR and PIPEDA, you have the right to:\n• Access: Request a copy of the personal data we hold about you.\n• Rectification: Update or correct your profile information in Settings.\n• Erasure (Right to be Forgotten): Request complete deletion of your account and all associated countdowns and notifications at any time by contacting {supportEmail}.'**
  String privacyRightsBody(String supportEmail);

  /// First terms of service section heading.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get termsAcceptanceTitle;

  /// Terms of service acceptance section.
  ///
  /// In en, this message translates to:
  /// **'By accessing or using Date Dawn, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.'**
  String get termsAcceptanceBody;

  /// Second terms of service section heading.
  ///
  /// In en, this message translates to:
  /// **'2. Use of the Service'**
  String get termsUseTitle;

  /// Terms of service acceptable-use section.
  ///
  /// In en, this message translates to:
  /// **'Date Dawn is provided for personal, non-commercial countdown and shared moment tracking. You agree not to misuse the service, upload malicious content, harass other users through shared circles or invitations, or attempt to bypass security controls.'**
  String get termsUseBody;

  /// Third terms of service section heading.
  ///
  /// In en, this message translates to:
  /// **'3. User Content & Ownership'**
  String get termsOwnershipTitle;

  /// Terms of service explanation of user content ownership.
  ///
  /// In en, this message translates to:
  /// **'You retain all ownership rights to the countdown events, titles, and content you create. You grant Date Dawn a limited license solely to store and sync your content across your authenticated devices and shared circle members.'**
  String get termsOwnershipBody;

  /// Fourth terms of service section heading.
  ///
  /// In en, this message translates to:
  /// **'4. Termination & Account Deletion'**
  String get termsTerminationTitle;

  /// Terms of service account termination and deletion section.
  ///
  /// In en, this message translates to:
  /// **'You may stop using Date Dawn at any time and request account deletion by emailing support. We reserve the right to suspend or terminate accounts that violate these terms or abuse platform infrastructure.'**
  String get termsTerminationBody;

  /// Fifth terms of service section heading.
  ///
  /// In en, this message translates to:
  /// **'5. Limitation of Liability'**
  String get termsLiabilityTitle;

  /// Terms of service limitation of liability section.
  ///
  /// In en, this message translates to:
  /// **'Date Dawn is provided \"as is\" without warranties of any kind. We shall not be liable for any indirect, incidental, or consequential damages arising from your use of the application.'**
  String get termsLiabilityBody;

  /// Title displayed on the privacy policy page.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// Title displayed on the terms of service page.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// Heading on the help and support page.
  ///
  /// In en, this message translates to:
  /// **'We read every message'**
  String get supportHeading;

  /// Introduction and expected response time on support page.
  ///
  /// In en, this message translates to:
  /// **'Date Dawn is a small, independent app. Email is the fastest way to reach the person who builds it — there is no support desk in between. We usually reply {responseTime}.'**
  String supportIntro(String responseTime);

  /// Typical support email response time.
  ///
  /// In en, this message translates to:
  /// **'within 2 business days'**
  String get supportResponseTime;

  /// FAQ section heading on the support page.
  ///
  /// In en, this message translates to:
  /// **'Common questions'**
  String get supportCommonQuestions;

  /// Support FAQ question about missing countdowns after Google sign-in.
  ///
  /// In en, this message translates to:
  /// **'I signed in with Google and my countdowns are missing.'**
  String get supportFaqGoogleQuestion;

  /// Support FAQ answer about account sign-in methods.
  ///
  /// In en, this message translates to:
  /// **'Use the same method you used when you created your account. Google and email/password are not automatically linked. If you need to switch methods or think you have data in two accounts, contact us before creating another account.'**
  String get supportFaqGoogleAnswer;

  /// Support FAQ question about a shared countdown.
  ///
  /// In en, this message translates to:
  /// **'Someone I shared with cannot see the countdown.'**
  String get supportFaqSharingQuestion;

  /// Support FAQ answer about accepting countdown invitations.
  ///
  /// In en, this message translates to:
  /// **'Sharing a countdown with a circle sends an invitation — it does not add people automatically. They need to open Invitations in the app and accept it. A couple circle is the one exception: those share instantly.'**
  String get supportFaqSharingAnswer;

  /// Support FAQ question about a declined invitation.
  ///
  /// In en, this message translates to:
  /// **'I declined an invitation by mistake.'**
  String get supportFaqDeclinedQuestion;

  /// Support FAQ answer about reopening an invitation.
  ///
  /// In en, this message translates to:
  /// **'Ask the person who invited you to invite you again — they can do that from the countdown by tapping the refresh icon next to your name. Nothing is lost in the meantime.'**
  String get supportFaqDeclinedAnswer;

  /// Support FAQ question about deleting an account.
  ///
  /// In en, this message translates to:
  /// **'How do I delete my account and my data?'**
  String get supportFaqDeleteQuestion;

  /// Support FAQ answer about account deletion.
  ///
  /// In en, this message translates to:
  /// **'Email us from the address you signed up with and ask for deletion. Every countdown, invitation and notification tied to the account is removed, and we confirm when it is done.'**
  String get supportFaqDeleteAnswer;

  /// Support FAQ question about blocking a person.
  ///
  /// In en, this message translates to:
  /// **'How do I block someone?'**
  String get supportFaqBlockQuestion;

  /// Support FAQ answer about blocking and unblocking.
  ///
  /// In en, this message translates to:
  /// **'Open a countdown you share with them and long-press their name in the people list (secondary-click on a computer). They are removed from your shared countdowns and cannot invite you again. To undo it, go to Settings → Blocked people.'**
  String get supportFaqBlockAnswer;

  /// Support FAQ question about advertising and data.
  ///
  /// In en, this message translates to:
  /// **'Do you sell my data or show ads?'**
  String get supportFaqAdsQuestion;

  /// Support FAQ answer about ads and data privacy.
  ///
  /// In en, this message translates to:
  /// **'No. There are no ads, no analytics profiles and no third-party tracking. What you count down to is nobody\'s business but yours, so it is stored under your own account for nobody else to read.'**
  String get supportFaqAdsAnswer;

  /// Legal links section heading on support page.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get supportLegal;

  /// Support contact guidance at the bottom of the support page.
  ///
  /// In en, this message translates to:
  /// **'A refund, a billing question or a crash report all belong at the same address. If the app misbehaves, telling us your device and what you were doing when it happened is the single most useful thing you can include.'**
  String get supportNotice;

  /// Label for the support email contact card.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get supportEmailLabel;

  /// Confirmation that the support email was copied.
  ///
  /// In en, this message translates to:
  /// **'{email} copied'**
  String supportEmailCopied(String email);

  /// Action to open a mail app.
  ///
  /// In en, this message translates to:
  /// **'Open mail'**
  String get openMail;

  /// Notice shown when a link is copied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to your clipboard.'**
  String get linkCopiedClipboard;

  /// Title on the email verification screen.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// Email verification instructions.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. Please verify to continue.'**
  String verifyEmailInstructions(String email);

  /// Fallback when the user's email address is not available.
  ///
  /// In en, this message translates to:
  /// **'your email address'**
  String get yourEmailAddress;

  /// Confirmation that a password reset email was sent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email}. Use the newest email.'**
  String resetLinkSent(String email);

  /// Confirmation after resending a verification email.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent.'**
  String get verificationEmailSent;

  /// Notice when email verification is not complete.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet. Check your inbox.'**
  String get verificationNotComplete;

  /// Message after verifying an email for a signed-out user.
  ///
  /// In en, this message translates to:
  /// **'Your email is verified. Sign in to continue if needed.'**
  String get verifiedSignInToContinue;

  /// Reminder to check spam for the verification email.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find the email? Please check your Spam or Junk folder.'**
  String get checkSpamFolder;

  /// Action to confirm email verification.
  ///
  /// In en, this message translates to:
  /// **'I have verified my email'**
  String get confirmEmailVerified;

  /// Progress label while an email is being sent.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendingEmail;

  /// Action to resend a verification email.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmail;

  /// Cooldown notice between verification email requests.
  ///
  /// In en, this message translates to:
  /// **'Please wait 60 seconds before requesting another email.'**
  String get waitBeforeResending;

  /// Error when a password reset link lacks its action code.
  ///
  /// In en, this message translates to:
  /// **'This reset link is missing its security code.'**
  String get resetCodeMissing;

  /// Confirmation after a password reset.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in again.'**
  String get passwordUpdatedSignIn;

  /// Title for an invalid password reset link.
  ///
  /// In en, this message translates to:
  /// **'This reset link can\'t be used'**
  String get resetLinkInvalidTitle;

  /// Explanation for an expired or used password reset link.
  ///
  /// In en, this message translates to:
  /// **'The link may have expired or already been used. Return to sign in and request a new password reset email.'**
  String get resetLinkInvalidBody;

  /// Navigation action back to sign in.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// Heading for the new password form.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get chooseNewPassword;

  /// Label for the new password field.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// Label for the confirm password field.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// Validation message for a short password.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get passwordMinLength;

  /// Validation message when password fields differ.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// Action to save a new password.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// Action to edit a countdown.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editCountdownAction;

  /// Action to duplicate a countdown one year later.
  ///
  /// In en, this message translates to:
  /// **'Duplicate a year later'**
  String get duplicateYearLater;

  /// Confirmation after duplicating a countdown.
  ///
  /// In en, this message translates to:
  /// **'Duplicated — open it to adjust the date.'**
  String get countdownDuplicated;

  /// Permission notice when a non-owner tries to delete.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can delete this countdown.'**
  String get onlyOwnerCanDelete;

  /// Error shown when deleting a countdown fails.
  ///
  /// In en, this message translates to:
  /// **'Could not delete. Try again.'**
  String get countdownDeleteFailed;

  /// Confirmation dialog warning about deleting a countdown.
  ///
  /// In en, this message translates to:
  /// **'The countdown cannot be undone.'**
  String get countdownDeleteWarning;

  /// Confirmation heading for blocking a person.
  ///
  /// In en, this message translates to:
  /// **'Block {personName}?'**
  String blockPersonQuestion(String personName);

  /// Explains what happens when another person is blocked.
  ///
  /// In en, this message translates to:
  /// **'You will stop seeing each other. They are removed from every countdown you share, invitations between you are cancelled, and they cannot invite you again. They are not told.'**
  String get blockExplanation;

  /// Explains where to undo a block.
  ///
  /// In en, this message translates to:
  /// **'You can undo this any time in Settings → Blocked people.'**
  String get undoBlockInSettings;

  /// Progress label while blocking a person.
  ///
  /// In en, this message translates to:
  /// **'Blocking…'**
  String get blocking;

  /// Action to block a person.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockAction;

  /// Confirmation after blocking a person.
  ///
  /// In en, this message translates to:
  /// **'{personName} is blocked.'**
  String personBlocked(String personName);

  /// Action to undo a recent change.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Confirmation after unblocking a person.
  ///
  /// In en, this message translates to:
  /// **'{personName} is unblocked.'**
  String personUnblocked(String personName);

  /// Clarifies that unblocking does not restore prior countdown access.
  ///
  /// In en, this message translates to:
  /// **'Countdown access was not restored.'**
  String get blockAccessNotRestored;

  /// Error when undoing a block fails.
  ///
  /// In en, this message translates to:
  /// **'Could not undo block. Please try again.'**
  String get undoBlockFailed;

  /// Error when saving a block is refused.
  ///
  /// In en, this message translates to:
  /// **'Your block could not be saved. Sign in again and retry.'**
  String get blockSaveFailed;

  /// Network error with retry guidance.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get noConnectionRetry;

  /// Error when blocking a person fails.
  ///
  /// In en, this message translates to:
  /// **'Could not block {personName}. Please try again.'**
  String blockPersonFailed(String personName);

  /// Title of the blocked people screen.
  ///
  /// In en, this message translates to:
  /// **'Blocked people'**
  String get blockedPeopleTitle;

  /// Empty state title for the blocked people screen.
  ///
  /// In en, this message translates to:
  /// **'Nobody is blocked'**
  String get nobodyBlocked;

  /// Instructions for blocking someone from a countdown.
  ///
  /// In en, this message translates to:
  /// **'To block someone, open a countdown you share with them, open the ⋮ menu on their row, and tap Block.'**
  String get howToBlockPerson;

  /// Explanation of the blocked people list.
  ///
  /// In en, this message translates to:
  /// **'These people cannot invite you, and you do not share any countdown with them. They are not told they are blocked.'**
  String get blockedPeopleDescription;

  /// Action to unblock a person.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// Title for a blocked people list loading error.
  ///
  /// In en, this message translates to:
  /// **'Could not load your blocked list'**
  String get blockedListLoadFailed;

  /// Permission error when reading the blocked people list.
  ///
  /// In en, this message translates to:
  /// **'Your account is not allowed to read this list. If this keeps happening, update the app.'**
  String get blockedListPermissionError;

  /// Destructive account deletion action in Settings.
  ///
  /// In en, this message translates to:
  /// **'Instructions on how to delete account'**
  String get deleteAccount;

  /// Permanent account deletion warning.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent. All your events, circles, and data will be deleted forever.'**
  String get deleteAccountWarning;

  /// Instructions for confirming account deletion.
  ///
  /// In en, this message translates to:
  /// **'Type your exact account email to continue.'**
  String get deleteAccountConfirmationPrompt;

  /// Account deletion confirmation input label.
  ///
  /// In en, this message translates to:
  /// **'Account email'**
  String get deleteAccountConfirmationLabel;

  /// Final account deletion confirmation button.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Account'**
  String get permanentlyDeleteAccount;

  /// Account deletion consequence about the profile.
  ///
  /// In en, this message translates to:
  /// **'Your profile will be permanently deleted.'**
  String get deleteAccountProfileConsequence;

  /// Account deletion consequence about events and circles.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to all your events and circles.'**
  String get deleteAccountAccessConsequence;

  /// Account deletion consequence about irreversibility.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteAccountIrreversibleConsequence;

  /// Final account deletion screen button.
  ///
  /// In en, this message translates to:
  /// **'Delete Account Permanently'**
  String get deleteAccountPermanentlyAction;

  /// Success message after account deletion.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeleted;

  /// Error shown when account deletion returns a server timeout.
  ///
  /// In en, this message translates to:
  /// **'Server timed out. Please try again later.'**
  String get serverTimedOutTryAgain;

  /// Unexpected account deletion failure.
  ///
  /// In en, this message translates to:
  /// **'Account deletion could not be completed. Please try again.'**
  String get accountDeletionFailed;

  /// Warning shown when local settings could not be cleared after account deletion.
  ///
  /// In en, this message translates to:
  /// **'The account was deleted, but some local settings could not be cleared. Restart the app before using another account.'**
  String get accountDeletedCleanupWarning;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'uk',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
