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
  String get languageFrench => 'French';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageUkrainian => 'Ukrainian';

  @override
  String get languageGerman => 'German';

  @override
  String get languageChinese => 'Traditional Chinese (Taiwan)';

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

  @override
  String get homeEmptyTitle => 'Name a day.';

  @override
  String get homeEmptyDescription =>
      'Pick a future moment — a wedding, a launch, a trip home. Date Dawn counts the years, months, days and hours left, then celebrates when it arrives.';

  @override
  String get homeLoadError =>
      'Could not reach your countdowns. Pull down to try again.';

  @override
  String get getStarted => 'Get started';

  @override
  String get homeSyncTitle => 'Keep them everywhere';

  @override
  String get homeSyncDescription =>
      'Sign in to sync your countdowns across phone, tablet and web — and to share them with the people counting down with you.';

  @override
  String get otherCountdowns => 'OTHER COUNTDOWNS';

  @override
  String get arrived => 'ARRIVED';

  @override
  String get countingDown => 'COUNTING DOWN';

  @override
  String get options => 'Options';

  @override
  String get open => 'Open';

  @override
  String get openCountdown => 'Open countdown';

  @override
  String get newCountdown => 'New countdown';

  @override
  String get editCountdown => 'Edit countdown';

  @override
  String get countdownTitleLabel => 'Title';

  @override
  String get countdownDescriptionLabel => 'Description';

  @override
  String get whenLabel => 'When';

  @override
  String get titleExampleHint => 'Wedding, launch, reunion';

  @override
  String get descriptionExampleHint => 'A short note about the day';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get presetWeek => '+1 week';

  @override
  String get presetMonth => '+1 month';

  @override
  String get presetYear => '+1 year';

  @override
  String get presetFiveYears => '+5 years';

  @override
  String get createCountdown => 'Create countdown';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get deleteCountdown => 'Delete countdown';

  @override
  String get countdownActions => 'Countdown actions';

  @override
  String get deleteCountdownQuestion => 'Delete this countdown?';

  @override
  String get countdownCannotUndo => 'The countdown cannot be undone.';

  @override
  String get giveCountdownTitle => 'Give this countdown a title.';

  @override
  String get pickFutureMoment => 'Pick a moment still ahead of you.';

  @override
  String get signInToSaveCountdown => 'Sign in to save countdowns.';

  @override
  String get countdownCreated => 'Countdown created.';

  @override
  String get changesSaved => 'Changes saved.';

  @override
  String get countdownDeleted => 'Countdown deleted.';

  @override
  String get partnerLabel => 'your partner';

  @override
  String partnerNotAdded(String partnerName) {
    return 'Countdown created, but $partnerName was not added. Invite them manually from the countdown.';
  }

  @override
  String partnerAdded(String partnerName) {
    return 'Countdown created. $partnerName was added.';
  }

  @override
  String get noPartnerAdded =>
      'Countdown created, but no partner was added. Invite them manually.';

  @override
  String get chooseFutureDateHint =>
      'Choose a future date to see the countdown.';

  @override
  String countingDownRemaining(String remaining) {
    return 'Counting down $remaining';
  }

  @override
  String get cannotEditCountdown =>
      'You can view this countdown but not change it.';

  @override
  String get shareWith => 'Share with';

  @override
  String get circleShareDescription =>
      'A couple circle shares instantly. Other circles get an invitation.';

  @override
  String get collaborators => 'Collaborators';

  @override
  String get collaboratorsCanFollow =>
      'Anyone you invite can follow this countdown on their own devices.';

  @override
  String get peopleFollowing => 'People following this countdown.';

  @override
  String get noCollaboratorsYet => 'No one else yet.';

  @override
  String get nameEmailHint => 'name@example.com';

  @override
  String get recentContactsCouldNotLoad =>
      'Recent contacts could not load. Check your connection or Firestore rules.';

  @override
  String invitationSentTo(String email) {
    return 'Invitation sent to $email.';
  }

  @override
  String sharedWithCircle(String circleName) {
    return 'Shared with $circleName';
  }

  @override
  String get inviteAgain => 'Invite again';

  @override
  String get removePersonQuestion => 'Remove this person?';

  @override
  String collaboratorLosesAccess(String email) {
    return '$email will lose access to this countdown and will no longer see it in their list.';
  }

  @override
  String get changeRole => 'Change role';

  @override
  String changeRoleFor(String personName) {
    return 'Change role for $personName';
  }

  @override
  String roleChangeDescription(String role) {
    return 'This changes what they can do on this countdown from now on. They currently have $role access.';
  }

  @override
  String rolesNotAssignable(String roles, String topRole) {
    return '$roles cannot be assigned by you — you are $topRole.';
  }

  @override
  String get circlesDescriptionTitle => 'Groups you count down with';

  @override
  String get circlesDescription =>
      'Invite someone to a circle once, then share any countdown with the whole group in a single tap. A couple circle shares automatically — anything one of you creates, the other sees.';

  @override
  String get circlesLoadError =>
      'Could not load your circles. Pull down to retry.';

  @override
  String get noCircles => 'No circles yet';

  @override
  String get noCirclesDescription =>
      'Create one for the people you count down with — a partner, family, or the friends you take a trip with every year.';

  @override
  String get newCircle => 'New circle';

  @override
  String get sharesAutomatically => 'Shares automatically';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '$count person',
    );
    return '$_temp0';
  }

  @override
  String get inviteSomeone => 'Invite someone';

  @override
  String get you => 'You';

  @override
  String get leaveCircle => 'Leave circle';

  @override
  String get deleteCircle => 'Delete circle';

  @override
  String get removeFromCircle => 'Remove from circle';

  @override
  String removeMemberQuestion(String personName) {
    return 'Remove $personName?';
  }

  @override
  String get removeMemberExplanation =>
      'They will stop seeing countdowns shared with this circle. Nothing they created is deleted.';

  @override
  String leaveCircleQuestion(String circleName) {
    return 'Leave “$circleName”?';
  }

  @override
  String get leaveCircleExplanation =>
      'Countdowns shared with this circle will no longer appear for you. You can be invited back.';

  @override
  String deleteCircleQuestion(String circleName) {
    return 'Delete “$circleName”?';
  }

  @override
  String get deleteCircleExplanation =>
      'The group goes away. Countdowns shared with it are kept and stay yours — they are just no longer shared with these people.';

  @override
  String get circleNameHint => 'Family, Tokyo 2027, Us';

  @override
  String get coupleCircleTitle => 'This is us — a couple';

  @override
  String get coupleCircleDescription =>
      'Countdowns are shared with your partner automatically, with no invitation to accept.';

  @override
  String get circleCreated => 'Circle created.';

  @override
  String get coupleCircleCreated => 'Created. Invite your partner next.';

  @override
  String get inviteYourPartner => 'Invite your partner';

  @override
  String inviteToCircle(String circleName) {
    return 'Invite to “$circleName”';
  }

  @override
  String get coupleInviteExplanation =>
      'If they already have an account, they will be added automatically. Otherwise, they will be added when they sign in. Future countdowns shared with this circle will appear automatically.';

  @override
  String get circleInviteExplanation =>
      'They will get an invitation to accept or decline. After they join, you can share countdowns with this circle in one tap.';

  @override
  String get inviteEmailHint => 'them@example.com';

  @override
  String get sendInvitation => 'Send invitation';

  @override
  String get partnerAddedAutomatically =>
      'Your partner will be added automatically.';

  @override
  String get signInToUseCircles => 'Sign in to use circles';

  @override
  String get circlesRequireAccounts =>
      'Circles invite people by email, so they need an account to be invited to.';

  @override
  String get waitingOnYou => 'Waiting on you';

  @override
  String get invitationsEmptyDescription =>
      'Nothing is shared with you until you accept. Declining tells the person who invited you, so they are not left guessing.';

  @override
  String get signInToSeeInvitations => 'Sign in to see invitations';

  @override
  String get invitationsEmailAccount =>
      'Invitations are addressed to your email, so sign in with the address someone invited.';

  @override
  String get invitationsCouldNotLoad =>
      'Invitations could not load. Check your connection or Firestore rules.';

  @override
  String get nothingWaiting => 'Nothing waiting';

  @override
  String get invitationInboxEmpty =>
      'Invitations people send you will appear here. Countdown and standard circle invitations need your response; couple circles join automatically.';

  @override
  String get retryAddingYou => 'Retry adding you';

  @override
  String get decline => 'Decline';

  @override
  String joinInviteQuestion(String eventTitle) {
    return 'Join “$eventTitle”?';
  }

  @override
  String get joinInviteExplanation =>
      'It will appear in your list and you will get its countdown on this device.';

  @override
  String get join => 'Join';

  @override
  String alreadyMemberOf(String name) {
    return 'You are already a member of “$name”.';
  }

  @override
  String youJoined(String name) {
    return 'You joined “$name”.';
  }

  @override
  String youWereAddedTo(String name) {
    return 'You were added to “$name”.';
  }

  @override
  String get invitationDeclined => 'Invitation declined.';

  @override
  String get countdownInvitation => 'Countdown invitation';

  @override
  String get aCountdown => 'A countdown';

  @override
  String invitedToFollowCountdown(String role) {
    return 'You have been invited to follow this countdown. Accepting adds it to your list as $role.';
  }

  @override
  String get accept => 'Accept';

  @override
  String get partnerInvitation => 'Partner invitation';

  @override
  String get circleInvitation => 'Circle invitation';

  @override
  String partnerCircleAddTitle(String personName) {
    return 'You’re being added to $personName’s circle';
  }

  @override
  String get partnerCircleAddExplanation =>
      'You will be added automatically. Countdown events shared with this circle will show up in your list.';

  @override
  String circleJoinExplanation(String circleName) {
    return 'Joining “$circleName” means the countdowns they share with this circle will show up in your list.';
  }

  @override
  String get becomePartners => 'Become partners';

  @override
  String get joinCircle => 'Join circle';

  @override
  String get automaticJoinFailed => 'Automatic join could not be completed.';

  @override
  String get notNow => 'Not now';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get markedAllRead => 'Marked all read.';

  @override
  String get moreOptions => 'More options';

  @override
  String get noReadMessagesToDelete => 'No read messages to delete.';

  @override
  String get deleteReadMessages => 'Delete read messages';

  @override
  String get deletedReadMessages => 'Deleted read messages.';

  @override
  String get notificationsSignInFirst => 'Sign in first';

  @override
  String get notificationsAccountOnly =>
      'Notifications are tied to your account.';

  @override
  String get couldNotLoad => 'Could not load';

  @override
  String get checkConnectionRetry => 'Check your connection and try again.';

  @override
  String get nothingYet => 'Nothing yet';

  @override
  String get notificationsEmptyDescription =>
      'When something happens with your countdowns or invitations, it will show up here.';

  @override
  String get liveNotificationsCouldNotLoad =>
      'Live notifications could not be loaded.';

  @override
  String get inbox => 'INBOX';

  @override
  String get invitationResponses => 'INVITATION RESPONSES';

  @override
  String get invitationResponsesCouldNotLoad =>
      'Invitation responses could not be loaded.';

  @override
  String get countdownUnavailable => 'This countdown is no longer available.';

  @override
  String get viewDetails => 'View details';

  @override
  String get sharedWith => 'SHARED WITH';

  @override
  String get notes => 'NOTES';

  @override
  String get notesEmpty =>
      'Nothing yet. Leave a thought for everyone counting down with you.';

  @override
  String get addNote => 'Add a note';

  @override
  String get years => 'Years';

  @override
  String get months => 'Months';

  @override
  String get days => 'Days';

  @override
  String get hours => 'Hours';

  @override
  String remainingMinutes(int count) {
    return '$count min';
  }

  @override
  String remainingSeconds(int count) {
    return '$count sec remaining';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get keep => 'Keep';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get remove => 'Remove';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get tryAgain => 'Try again';

  @override
  String get share => 'Share';

  @override
  String get passed => 'Passed';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get accepted => 'Accepted';

  @override
  String get declined => 'Declined';

  @override
  String get removed => 'Removed';

  @override
  String get reopened => 'Reopened';

  @override
  String get waiting => 'Waiting';

  @override
  String get itHasArrived => 'It has arrived.';

  @override
  String remainingToGo(String remaining) {
    return '$remaining to go';
  }

  @override
  String get momentHasPassed => 'The moment has passed';

  @override
  String remainingAnd(String first, String last) {
    return '$first and $last';
  }

  @override
  String get dayHasCome => 'THE DAY HAS COME';

  @override
  String eventArrivedWithDescription(String title, String description) {
    return '$title is here — $description';
  }

  @override
  String eventArrivedTitleOnly(String title) {
    return '$title is here — enjoy every minute of it.';
  }

  @override
  String personRemovedFromCircle(String personName, String circleName) {
    return '$personName was removed from “$circleName”.';
  }

  @override
  String youLeftCircle(String circleName) {
    return 'You left “$circleName”.';
  }

  @override
  String circleDeleted(String circleName) {
    return 'Deleted “$circleName”.';
  }

  @override
  String get someone => 'Someone';

  @override
  String invitedYouToCircle(String personName, String circleName) {
    return '$personName invited you to “$circleName”';
  }

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleEditor => 'Editor';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get roleAdminDescription =>
      'Can manage the countdown and its participants.';

  @override
  String get roleEditorDescription =>
      'Can edit the countdown and invite others.';

  @override
  String get roleViewerDescription => 'Can view the countdown and leave notes.';

  @override
  String remainingYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '$count year',
    );
    return '$_temp0';
  }

  @override
  String remainingMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '$count month',
    );
    return '$_temp0';
  }

  @override
  String remainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String remainingHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '$count hour',
    );
    return '$_temp0';
  }

  @override
  String remainingMinuteUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String remainingSecondUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '$count second',
    );
    return '$_temp0';
  }

  @override
  String get moreActions => 'More actions';

  @override
  String get block => 'Block';

  @override
  String roleChanged(String personName, String role) {
    return '$personName is now $role.';
  }

  @override
  String personRemoved(String personName) {
    return '$personName was removed.';
  }

  @override
  String get signInToSaveIt => 'Sign in to save it';

  @override
  String get countdownsFollowYou =>
      'Countdowns live in your account, so they follow you to every device and can be shared with other people.';

  @override
  String get savePermissionError =>
      'Firestore refused the save. If this keeps happening, the deployed security rules are older than the app — run `firebase deploy --only firestore:rules`.';

  @override
  String get saveNetworkError =>
      'Could not reach Firestore. Check your connection and try again.';

  @override
  String get saveFailed => 'Could not save. Please try again.';

  @override
  String get momentPassed => 'The moment has passed';

  @override
  String get and => 'and';

  @override
  String get back => 'Back';

  @override
  String get policyLastUpdated =>
      'Last updated: February 2026 · Compliant with EU GDPR & Canada PIPEDA';

  @override
  String get privacyIntroTitle => '1. Introduction & Data Controller';

  @override
  String privacyIntroBody(String supportEmail) {
    return 'Date Dawn (\"we\", \"our\", or \"us\") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile and web applications, in full compliance with the EU General Data Protection Regulation (GDPR) and the Personal Information Protection and Electronic Documents Act (PIPEDA) of Canada.\n\nData Controller Contact: $supportEmail';
  }

  @override
  String get privacyCollectTitle => '2. Information We Collect';

  @override
  String get privacyCollectBody =>
      '• Account Data: Email address and display name provided during authentication (Firebase Auth).\n• User Content: Countdowns, titles, dates, descriptions, and circle memberships you explicitly create or share.\n• Device & Notification Data: Push notification tokens to deliver countdown reminders and invitation alerts.\n\nWe do NOT collect browsing history, advertising identifiers, location data, or sell any personal information to third parties.';

  @override
  String get privacyBasisTitle => '3. Legal Basis for Processing (EU GDPR)';

  @override
  String get privacyBasisBody =>
      'We process your data under the following lawful bases:\n• Contractual Necessity: Providing countdown syncing, circle sharing, and invitation features.\n• Consent: When you grant push notification permissions or opt-in to shared circles.\n• Legitimate Interests: Ensuring application security, reliability, and preventing abuse.';

  @override
  String get privacySharingTitle => '4. Sharing & Blocking';

  @override
  String get privacySharingBody =>
      'Date Dawn lets people interact one-to-one: you can invite someone to a countdown, and both of you can leave notes on one you share. That content is visible only to the people on that countdown — never public, never shown to anyone else.\n\nYou can block another person at any time: open a countdown you share with them and long-press their name (or secondary-click it on desktop). Blocking removes you from each other’s countdowns, cancels invitations between you, and stops them inviting you again. The person is not told. The list of people you have blocked is private to you, and you can unblock anyone from Settings → Blocked people.';

  @override
  String get privacyStorageTitle => '5. Data Storage & Security';

  @override
  String get privacyStorageBody =>
      'Your data is securely stored and processed using Firebase (Google Cloud Platform) infrastructure adhering to high industry security standards. Data transmitted between your device and our servers is encrypted in transit using TLS.';

  @override
  String get privacyRightsTitle =>
      '6. Your Rights (Access, Correction & Erasure)';

  @override
  String privacyRightsBody(String supportEmail) {
    return 'Under GDPR and PIPEDA, you have the right to:\n• Access: Request a copy of the personal data we hold about you.\n• Rectification: Update or correct your profile information in Settings.\n• Erasure (Right to be Forgotten): Request complete deletion of your account and all associated countdowns and notifications at any time by contacting $supportEmail.';
  }

  @override
  String get termsAcceptanceTitle => '1. Acceptance of Terms';

  @override
  String get termsAcceptanceBody =>
      'By accessing or using Date Dawn, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.';

  @override
  String get termsUseTitle => '2. Use of the Service';

  @override
  String get termsUseBody =>
      'Date Dawn is provided for personal, non-commercial countdown and shared moment tracking. You agree not to misuse the service, upload malicious content, harass other users through shared circles or invitations, or attempt to bypass security controls.';

  @override
  String get termsOwnershipTitle => '3. User Content & Ownership';

  @override
  String get termsOwnershipBody =>
      'You retain all ownership rights to the countdown events, titles, and content you create. You grant Date Dawn a limited license solely to store and sync your content across your authenticated devices and shared circle members.';

  @override
  String get termsTerminationTitle => '4. Termination & Account Deletion';

  @override
  String get termsTerminationBody =>
      'You may stop using Date Dawn at any time and request account deletion by emailing support. We reserve the right to suspend or terminate accounts that violate these terms or abuse platform infrastructure.';

  @override
  String get termsLiabilityTitle => '5. Limitation of Liability';

  @override
  String get termsLiabilityBody =>
      'Date Dawn is provided \"as is\" without warranties of any kind. We shall not be liable for any indirect, incidental, or consequential damages arising from your use of the application.';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get supportHeading => 'We read every message';

  @override
  String supportIntro(String responseTime) {
    return 'Date Dawn is a small, independent app. Email is the fastest way to reach the person who builds it — there is no support desk in between. We usually reply $responseTime.';
  }

  @override
  String get supportResponseTime => 'within 2 business days';

  @override
  String get supportCommonQuestions => 'Common questions';

  @override
  String get supportFaqGoogleQuestion =>
      'I signed in with Google and my countdowns are missing.';

  @override
  String get supportFaqGoogleAnswer =>
      'Use the same method you used when you created your account. Google and email/password are not automatically linked. If you need to switch methods or think you have data in two accounts, contact us before creating another account.';

  @override
  String get supportFaqSharingQuestion =>
      'Someone I shared with cannot see the countdown.';

  @override
  String get supportFaqSharingAnswer =>
      'Sharing a countdown with a circle sends an invitation — it does not add people automatically. They need to open Invitations in the app and accept it. A couple circle is the one exception: those share instantly.';

  @override
  String get supportFaqDeclinedQuestion =>
      'I declined an invitation by mistake.';

  @override
  String get supportFaqDeclinedAnswer =>
      'Ask the person who invited you to invite you again — they can do that from the countdown by tapping the refresh icon next to your name. Nothing is lost in the meantime.';

  @override
  String get supportFaqDeleteQuestion =>
      'How do I delete my account and my data?';

  @override
  String get supportFaqDeleteAnswer =>
      'Email us from the address you signed up with and ask for deletion. Every countdown, invitation and notification tied to the account is removed, and we confirm when it is done.';

  @override
  String get supportFaqBlockQuestion => 'How do I block someone?';

  @override
  String get supportFaqBlockAnswer =>
      'Open a countdown you share with them and long-press their name in the people list (secondary-click on a computer). They are removed from your shared countdowns and cannot invite you again. To undo it, go to Settings → Blocked people.';

  @override
  String get supportFaqAdsQuestion => 'Do you sell my data or show ads?';

  @override
  String get supportFaqAdsAnswer =>
      'No. There are no ads, no analytics profiles and no third-party tracking. What you count down to is nobody\'s business but yours, so it is stored under your own account for nobody else to read.';

  @override
  String get supportLegal => 'Legal';

  @override
  String get supportNotice =>
      'A refund, a billing question or a crash report all belong at the same address. If the app misbehaves, telling us your device and what you were doing when it happened is the single most useful thing you can include.';

  @override
  String get supportEmailLabel => 'Email support';

  @override
  String supportEmailCopied(String email) {
    return '$email copied';
  }

  @override
  String get openMail => 'Open mail';

  @override
  String get linkCopiedClipboard => 'Link copied to your clipboard.';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailInstructions(String email) {
    return 'We sent a verification link to $email. Please verify to continue.';
  }

  @override
  String get yourEmailAddress => 'your email address';

  @override
  String resetLinkSent(String email) {
    return 'Reset link sent to $email. Use the newest email.';
  }

  @override
  String get verificationEmailSent => 'Verification email sent.';

  @override
  String get verificationNotComplete => 'Not verified yet. Check your inbox.';

  @override
  String get verifiedSignInToContinue =>
      'Your email is verified. Sign in to continue if needed.';

  @override
  String get checkSpamFolder =>
      'Can\'t find the email? Please check your Spam or Junk folder.';

  @override
  String get confirmEmailVerified => 'I have verified my email';

  @override
  String get sendingEmail => 'Sending…';

  @override
  String get resendEmail => 'Resend email';

  @override
  String get waitBeforeResending =>
      'Please wait 60 seconds before requesting another email.';

  @override
  String get resetCodeMissing =>
      'This reset link is missing its security code.';

  @override
  String get passwordUpdatedSignIn => 'Password updated. Sign in again.';

  @override
  String get resetLinkInvalidTitle => 'This reset link can\'t be used';

  @override
  String get resetLinkInvalidBody =>
      'The link may have expired or already been used. Return to sign in and request a new password reset email.';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get chooseNewPassword => 'Choose a new password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordMinLength => 'Use at least 6 characters.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get updatePassword => 'Update password';

  @override
  String get editCountdownAction => 'Edit';

  @override
  String get duplicateYearLater => 'Duplicate a year later';

  @override
  String get countdownDuplicated => 'Duplicated — open it to adjust the date.';

  @override
  String get onlyOwnerCanDelete => 'Only the owner can delete this countdown.';

  @override
  String get countdownDeleteFailed => 'Could not delete. Try again.';

  @override
  String get countdownDeleteWarning => 'The countdown cannot be undone.';

  @override
  String blockPersonQuestion(String personName) {
    return 'Block $personName?';
  }

  @override
  String get blockExplanation =>
      'You will stop seeing each other. They are removed from every countdown you share, invitations between you are cancelled, and they cannot invite you again. They are not told.';

  @override
  String get undoBlockInSettings =>
      'You can undo this any time in Settings → Blocked people.';

  @override
  String get blocking => 'Blocking…';

  @override
  String get blockAction => 'Block';

  @override
  String personBlocked(String personName) {
    return '$personName is blocked.';
  }

  @override
  String get undo => 'Undo';

  @override
  String personUnblocked(String personName) {
    return '$personName is unblocked.';
  }

  @override
  String get blockAccessNotRestored => 'Countdown access was not restored.';

  @override
  String get undoBlockFailed => 'Could not undo block. Please try again.';

  @override
  String get blockSaveFailed =>
      'Your block could not be saved. Sign in again and retry.';

  @override
  String get noConnectionRetry =>
      'No connection. Check your network and try again.';

  @override
  String blockPersonFailed(String personName) {
    return 'Could not block $personName. Please try again.';
  }

  @override
  String get blockedPeopleTitle => 'Blocked people';

  @override
  String get nobodyBlocked => 'Nobody is blocked';

  @override
  String get howToBlockPerson =>
      'To block someone, open a countdown you share with them, open the ⋮ menu on their row, and tap Block.';

  @override
  String get blockedPeopleDescription =>
      'These people cannot invite you, and you do not share any countdown with them. They are not told they are blocked.';

  @override
  String get unblock => 'Unblock';

  @override
  String get blockedListLoadFailed => 'Could not load your blocked list';

  @override
  String get blockedListPermissionError =>
      'Your account is not allowed to read this list. If this keeps happening, update the app.';

  @override
  String get deleteAccount => 'Instructions on how to delete account';

  @override
  String get deleteAccountWarning =>
      'This action is permanent. All your events, circles, and data will be deleted forever.';

  @override
  String get deleteAccountConfirmationPrompt =>
      'Type your exact account email to continue.';

  @override
  String get deleteAccountConfirmationLabel => 'Account email';

  @override
  String get permanentlyDeleteAccount => 'Permanently Delete Account';

  @override
  String get deleteAccountProfileConsequence =>
      'Your profile will be permanently deleted.';

  @override
  String get deleteAccountAccessConsequence =>
      'You will lose access to all your events and circles.';

  @override
  String get deleteAccountIrreversibleConsequence =>
      'This action cannot be undone.';

  @override
  String get deleteAccountPermanentlyAction => 'Delete Account Permanently';

  @override
  String get accountDeleted => 'Account deleted successfully';

  @override
  String get serverTimedOutTryAgain =>
      'Server timed out. Please try again later.';

  @override
  String get accountDeletionFailed =>
      'Account deletion could not be completed. Please try again.';

  @override
  String get accountDeletedCleanupWarning =>
      'The account was deleted, but some local settings could not be cleared. Restart the app before using another account.';
}
