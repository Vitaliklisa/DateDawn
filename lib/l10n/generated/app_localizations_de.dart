// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Date Dawn';

  @override
  String get language => 'Sprache';

  @override
  String get followSystemLanguage => 'Sprache des Systems verwenden';

  @override
  String get languageChanged => 'Sprache geändert.';

  @override
  String get languageSaveFailed =>
      'Ihre Spracheinstellung konnte nicht gespeichert werden.';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageSpanish => 'Spanisch';

  @override
  String get languageUkrainian => 'Ukrainisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageChinese => 'Traditionelles Chinesisch (Taiwan)';

  @override
  String get settings => 'Einstellungen';

  @override
  String get dateDawnUser => 'Date-Dawn-Nutzer';

  @override
  String get guestAccount => 'Gastkonto';

  @override
  String get notSignedIn => 'Sie sind nicht angemeldet';

  @override
  String get syncAndShareDescription =>
      'Melden Sie sich an, um Ihre Countdowns auf allen Geräten zu synchronisieren und mit anderen zu teilen.';

  @override
  String get signIn => 'Anmelden';

  @override
  String get appearance => 'DARSTELLUNG';

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get lightTheme => 'Hell';

  @override
  String get systemTheme => 'System';

  @override
  String get time => 'ZEIT';

  @override
  String get timeFormatDescription =>
      'So werden Uhrzeiten dargestellt. Ihre Countdowns werden so oder so als genaue Zeitpunkte gespeichert — dies ändert lediglich die Anzeige.';

  @override
  String get twelveHourTime => '12-Stunden-Anzeige (AM/PM)';

  @override
  String get twentyFourHourTime => '24-Stunden-Anzeige';

  @override
  String get about => 'ÜBER DIE APP';

  @override
  String get version => 'Version';

  @override
  String get sync => 'Synchronisierung';

  @override
  String get safety => 'SICHERHEIT';

  @override
  String get blockedPeople => 'Blockierte Personen';

  @override
  String get legal => 'RECHTLICHES';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get helpAndSupport => 'Hilfe & Support';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signedOut => 'Abgemeldet.';

  @override
  String countdownsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Countdowns',
      one: '$count Countdown',
    );
    return '$_temp0';
  }

  @override
  String get welcomeToDateDawn => 'Willkommen bei Date Dawn';

  @override
  String get createYourAccount => 'Konto erstellen';

  @override
  String get countdownsSyncDescription =>
      'Ihre Countdowns werden auf allen Geräten synchronisiert, auf denen Sie angemeldet sind.';

  @override
  String get welcomeDescription =>
      'Zählen Sie bis zu den Momenten, die zählen — auf Smartphone, Tablet und im Web.';

  @override
  String get name => 'Name';

  @override
  String get nameHint => 'Alex Rivera';

  @override
  String get nameRequired => 'Nennen Sie uns Ihren Namen.';

  @override
  String get email => 'E-Mail';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Geben Sie Ihre E-Mail-Adresse ein.';

  @override
  String get emailInvalid => 'Das sieht nicht nach einer E-Mail-Adresse aus.';

  @override
  String get password => 'Passwort';

  @override
  String get passwordRequired => 'Geben Sie Ihr Passwort ein.';

  @override
  String get passwordTooShort => 'Verwenden Sie mindestens 6 Zeichen.';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get forgotPasswordPrompt =>
      'Geben Sie zuerst Ihre E-Mail-Adresse ein und tippen Sie dann auf ?Passwort vergessen?.';

  @override
  String get signInConnectionError =>
      'Der Anmeldedienst konnte nicht erreicht werden. Prüfen Sie Ihre Verbindung.';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get or => 'ODER';

  @override
  String get continueWithGoogle => 'Mit Google fortfahren';

  @override
  String get alreadyHaveAccount => 'Sie haben bereits ein Konto? ';

  @override
  String get newHere => 'Neu hier? ';

  @override
  String get createOne => 'Konto erstellen';

  @override
  String get troubleSigningIn => 'Probleme bei der Anmeldung? Hilfe erhalten';

  @override
  String get accountCreated => 'Konto erstellt.';

  @override
  String get welcomeBack => 'Willkommen zurück.';

  @override
  String get signInFailed =>
      'Die Anmeldung konnte nicht abgeschlossen werden. Bitte versuchen Sie es erneut.';

  @override
  String get signedInWithGoogle => 'Mit Google angemeldet.';

  @override
  String get home => 'Startseite';

  @override
  String get invitations => 'Einladungen';

  @override
  String get circles => 'Kreise';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get support => 'Support';

  @override
  String get homeEmptyTitle => 'Benennen Sie einen Tag.';

  @override
  String get homeEmptyDescription =>
      'Wählen Sie einen zukünftigen Moment — eine Hochzeit, eine Produkteinführung, eine Heimreise. Date Dawn zählt die verbleibenden Jahre, Monate, Tage und Stunden und feiert, wenn der Moment da ist.';

  @override
  String get homeLoadError =>
      'Ihre Countdowns konnten nicht geladen werden. Ziehen Sie nach unten, um es erneut zu versuchen.';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get homeSyncTitle => 'Überall dabei';

  @override
  String get homeSyncDescription =>
      'Melden Sie sich an, um Ihre Countdowns auf Smartphone, Tablet und im Web zu synchronisieren — und um sie mit den Personen zu teilen, die mit Ihnen herunterzählen.';

  @override
  String get otherCountdowns => 'WEITERE COUNTDOWNS';

  @override
  String get arrived => 'ERREICHT';

  @override
  String get countingDown => 'COUNTDOWN LÄUFT';

  @override
  String get options => 'Optionen';

  @override
  String get open => 'öffnen';

  @override
  String get openCountdown => 'Countdown öffnen';

  @override
  String get newCountdown => 'Neuer Countdown';

  @override
  String get editCountdown => 'Countdown bearbeiten';

  @override
  String get countdownTitleLabel => 'Titel';

  @override
  String get countdownDescriptionLabel => 'Beschreibung';

  @override
  String get whenLabel => 'Wann';

  @override
  String get titleExampleHint => 'Hochzeit, Produkteinführung, Wiedersehen';

  @override
  String get descriptionExampleHint => 'Eine kurze Notiz zu diesem Tag';

  @override
  String get dateLabel => 'Datum';

  @override
  String get timeLabel => 'Uhrzeit';

  @override
  String get presetWeek => '+1 Woche';

  @override
  String get presetMonth => '+1 Monat';

  @override
  String get presetYear => '+1 Jahr';

  @override
  String get presetFiveYears => '+5 Jahre';

  @override
  String get createCountdown => 'Countdown erstellen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get deleteCountdown => 'Countdown löschen';

  @override
  String get countdownActions => 'Countdown-Aktionen';

  @override
  String get deleteCountdownQuestion => 'Diesen Countdown löschen?';

  @override
  String get countdownCannotUndo =>
      'Das Löschen des Countdowns kann nicht rückgängig gemacht werden.';

  @override
  String get giveCountdownTitle => 'Geben Sie diesem Countdown einen Titel.';

  @override
  String get pickFutureMoment =>
      'Wählen Sie einen Zeitpunkt, der noch bevorsteht.';

  @override
  String get signInToSaveCountdown =>
      'Melden Sie sich an, um Countdowns zu speichern.';

  @override
  String get countdownCreated => 'Countdown erstellt.';

  @override
  String get changesSaved => 'Änderungen gespeichert.';

  @override
  String get countdownDeleted => 'Countdown gelöscht.';

  @override
  String get partnerLabel => 'Ihr Partner bzw. Ihre Partnerin';

  @override
  String partnerNotAdded(String partnerName) {
    return 'Countdown erstellt, aber $partnerName wurde nicht hinzugefügt. Laden Sie die Person manuell aus dem Countdown ein.';
  }

  @override
  String partnerAdded(String partnerName) {
    return 'Countdown erstellt. $partnerName wurde hinzugefügt.';
  }

  @override
  String get noPartnerAdded =>
      'Countdown erstellt, aber keine Partnerperson wurde hinzugefügt. Laden Sie sie oder ihn manuell ein.';

  @override
  String get chooseFutureDateHint =>
      'Wählen Sie ein zukünftiges Datum, um den Countdown zu sehen.';

  @override
  String countingDownRemaining(String remaining) {
    return 'Countdown: $remaining';
  }

  @override
  String get cannotEditCountdown =>
      'Sie können diesen Countdown ansehen, aber nicht ändern.';

  @override
  String get shareWith => 'Teilen mit';

  @override
  String get circleShareDescription =>
      'Ein Paar-Kreis wird sofort geteilt. Andere Kreise erhalten eine Einladung.';

  @override
  String get collaborators => 'Mitwirkende';

  @override
  String get collaboratorsCanFollow =>
      'Alle Eingeladenen können diesem Countdown auf ihren eigenen Geräten folgen.';

  @override
  String get peopleFollowing => 'Personen, die diesem Countdown folgen.';

  @override
  String get noCollaboratorsYet => 'Noch niemand sonst.';

  @override
  String get nameEmailHint => 'name@example.com';

  @override
  String get recentContactsCouldNotLoad =>
      'Zuletzt verwendete Kontakte konnten nicht geladen werden. Prüfen Sie Ihre Verbindung oder die Firestore-Regeln.';

  @override
  String invitationSentTo(String email) {
    return 'Einladung an $email gesendet.';
  }

  @override
  String sharedWithCircle(String circleName) {
    return 'Mit $circleName geteilt';
  }

  @override
  String get inviteAgain => 'Erneut einladen';

  @override
  String get removePersonQuestion => 'Diese Person entfernen?';

  @override
  String collaboratorLosesAccess(String email) {
    return '$email verliert den Zugriff auf diesen Countdown und sieht ihn nicht mehr in der Liste.';
  }

  @override
  String get changeRole => 'Rolle ändern';

  @override
  String changeRoleFor(String personName) {
    return 'Rolle für $personName ändern';
  }

  @override
  String roleChangeDescription(String role) {
    return 'Ab sofort ändert dies, was die Person bei diesem Countdown tun kann. Derzeit hat sie Zugriff als $role.';
  }

  @override
  String rolesNotAssignable(String roles, String topRole) {
    return '$roles können nicht von Ihnen zugewiesen werden — Sie sind $topRole.';
  }

  @override
  String get circlesDescriptionTitle => 'Gruppen, mit denen Sie herunterzählen';

  @override
  String get circlesDescription =>
      'Laden Sie jemandem einmal in einen Kreis ein und teilen Sie dann jeden Countdown mit der gesamten Gruppe durch einen einzigen Tipp. Ein Paar-Kreis wird automatisch geteilt — was eine Person erstellt, sieht die andere.';

  @override
  String get circlesLoadError =>
      'Ihre Kreise konnten nicht geladen werden. Zum Wiederholen nach unten ziehen.';

  @override
  String get noCircles => 'Noch keine Kreise';

  @override
  String get noCirclesDescription =>
      'Erstellen Sie einen Kreis für die Menschen, mit denen Sie gemeinsam herunterzählen — einen Partner, die Familie oder Freunde, mit denen Sie jedes Jahr eine Reise unternehmen.';

  @override
  String get newCircle => 'Neuer Kreis';

  @override
  String get sharesAutomatically => 'Automatische Freigabe';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '$count Person',
    );
    return '$_temp0';
  }

  @override
  String get inviteSomeone => 'Jemanden einladen';

  @override
  String get you => 'Sie';

  @override
  String get leaveCircle => 'Kreis verlassen';

  @override
  String get deleteCircle => 'Kreis löschen';

  @override
  String get removeFromCircle => 'Aus dem Kreis entfernen';

  @override
  String removeMemberQuestion(String personName) {
    return '$personName entfernen?';
  }

  @override
  String get removeMemberExplanation =>
      'Die Person sieht keine Countdowns mehr, die mit diesem Kreis geteilt werden. Erstellte Inhalte werden nicht gelöscht.';

  @override
  String leaveCircleQuestion(String circleName) {
    return '„$circleName“ verlassen?';
  }

  @override
  String get leaveCircleExplanation =>
      'Mit diesem Kreis geteilte Countdowns werden Ihnen nicht mehr angezeigt. Sie können erneut eingeladen werden.';

  @override
  String deleteCircleQuestion(String circleName) {
    return '„$circleName“ löschen?';
  }

  @override
  String get deleteCircleExplanation =>
      'Die Gruppe wird entfernt. Die damit geteilten Countdowns bleiben erhalten und gehören Ihnen weiterhin — sie werden nur nicht mehr mit diesen Personen geteilt.';

  @override
  String get circleNameHint => 'Familie, Tokio 2027, Wir';

  @override
  String get coupleCircleTitle => 'Wir — ein Paar';

  @override
  String get coupleCircleDescription =>
      'Countdowns werden automatisch mit Ihrem Partner bzw. Ihrer Partnerin geteilt — ohne Annahme einer Einladung.';

  @override
  String get circleCreated => 'Kreis erstellt.';

  @override
  String get coupleCircleCreated =>
      'Erstellt. Laden Sie als Nächstes Ihren Partner bzw. Ihre Partnerin ein.';

  @override
  String get inviteYourPartner => 'Partner bzw. Partnerin einladen';

  @override
  String inviteToCircle(String circleName) {
    return 'In „$circleName“ einladen';
  }

  @override
  String get coupleInviteExplanation =>
      'Wenn die Person bereits ein Konto hat, wird sie automatisch hinzugefügt. Andernfalls wird sie hinzugefügt, sobald sie sich anmeldet. Zukünftige Countdowns, die mit diesem Kreis geteilt werden, erscheinen automatisch.';

  @override
  String get circleInviteExplanation =>
      'Die Person erhält eine Einladung zum Annehmen oder Ablehnen. Nach dem Beitritt können Sie mit diesem Kreis geteilte Countdowns mit einem Tipp teilen.';

  @override
  String get inviteEmailHint => 'them@example.com';

  @override
  String get sendInvitation => 'Einladung senden';

  @override
  String get partnerAddedAutomatically =>
      'Ihr Partner bzw. Ihre Partnerin wird automatisch hinzugefügt.';

  @override
  String get signInToUseCircles => 'Melden Sie sich an, um Kreise zu verwenden';

  @override
  String get circlesRequireAccounts =>
      'Kreise laden Personen per E-Mail ein, daher benötigen diese ein Konto, zu dem die Einladung gesendet werden kann.';

  @override
  String get waitingOnYou => 'Warten auf Ihre Antwort';

  @override
  String get invitationsEmptyDescription =>
      'Nichts wird für Sie freigegeben, solange Sie nicht akzeptieren. Mit Ablehnen informieren Sie die einladende Person, sodass sie nicht im Unklaren bleibt.';

  @override
  String get signInToSeeInvitations =>
      'Melden Sie sich an, um Einladungen zu sehen';

  @override
  String get invitationsEmailAccount =>
      'Einladungen werden an Ihre E-Mail-Adresse gerichtet. Melden Sie sich daher mit der Adresse an, an die jemand eine Einladung gesendet hat.';

  @override
  String get invitationsCouldNotLoad =>
      'Einladungen konnten nicht geladen werden. Prüfen Sie Ihre Verbindung oder die Firestore-Regeln.';

  @override
  String get nothingWaiting => 'Keine ausstehenden Einladungen';

  @override
  String get invitationInboxEmpty =>
      'Einladungen, die Ihnen andere senden, erscheinen hier. Countdown- und normale Kreiseinladungen erfordern Ihre Antwort; Paar-Kreise werden automatisch hinzugefügt.';

  @override
  String get retryAddingYou => 'Erneut hinzufügen';

  @override
  String get decline => 'Ablehnen';

  @override
  String joinInviteQuestion(String eventTitle) {
    return '„$eventTitle“ beitreten?';
  }

  @override
  String get joinInviteExplanation =>
      'Der Countdown erscheint in Ihrer Liste und wird auf diesem Gerät heruntergezählt.';

  @override
  String get join => 'Beitreten';

  @override
  String alreadyMemberOf(String name) {
    return 'Sie sind bereits Mitglied von „$name“.';
  }

  @override
  String youJoined(String name) {
    return 'Sie sind „$name“ beigetreten.';
  }

  @override
  String youWereAddedTo(String name) {
    return 'Sie wurden zu „$name“ hinzugefügt.';
  }

  @override
  String get invitationDeclined => 'Einladung abgelehnt.';

  @override
  String get countdownInvitation => 'Countdown-Einladung';

  @override
  String get aCountdown => 'Ein Countdown';

  @override
  String invitedToFollowCountdown(String role) {
    return 'Sie wurden eingeladen, diesem Countdown zu folgen. Mit der Annahme wird er mit der Rolle $role zu Ihrer Liste hinzugefügt.';
  }

  @override
  String get accept => 'Annehmen';

  @override
  String get partnerInvitation => 'Partner-Einladung';

  @override
  String get circleInvitation => 'Kreiseinladung';

  @override
  String partnerCircleAddTitle(String personName) {
    return 'Sie werden zum Kreis von $personName hinzugefügt';
  }

  @override
  String get partnerCircleAddExplanation =>
      'Sie werden automatisch hinzugefügt. Countdown-Events, die mit diesem Kreis geteilt werden, erscheinen in Ihrer Liste.';

  @override
  String circleJoinExplanation(String circleName) {
    return 'Mit dem Beitritt zu „$circleName“ erscheinen die von diesem Kreis geteilten Countdowns in Ihrer Liste.';
  }

  @override
  String get becomePartners => 'Partner werden';

  @override
  String get joinCircle => 'Kreis beitreten';

  @override
  String get automaticJoinFailed =>
      'Der automatische Beitritt konnte nicht abgeschlossen werden.';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String get markedAllRead => 'Alle als gelesen markiert.';

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get noReadMessagesToDelete =>
      'Keine gelesenen Nachrichten zum Löschen.';

  @override
  String get deleteReadMessages => 'Gelesene Nachrichten löschen';

  @override
  String get deletedReadMessages => 'Gelesene Nachrichten gelöscht.';

  @override
  String get notificationsSignInFirst => 'Zuerst anmelden';

  @override
  String get notificationsAccountOnly =>
      'Benachrichtigungen sind mit Ihrem Konto verknüpft.';

  @override
  String get couldNotLoad => 'Laden nicht möglich';

  @override
  String get checkConnectionRetry =>
      'Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get nothingYet => 'Noch nichts';

  @override
  String get notificationsEmptyDescription =>
      'Wenn sich etwas bei Ihren Countdowns oder Einladungen ereignet, wird es hier angezeigt.';

  @override
  String get liveNotificationsCouldNotLoad =>
      'Live-Benachrichtigungen konnten nicht geladen werden.';

  @override
  String get inbox => 'POSTEINGANG';

  @override
  String get invitationResponses => 'ANTWORTEN AUF EINLADUNGEN';

  @override
  String get invitationResponsesCouldNotLoad =>
      'Antworten auf Einladungen konnten nicht geladen werden.';

  @override
  String get countdownUnavailable =>
      'Dieser Countdown ist nicht mehr verfügbar.';

  @override
  String get viewDetails => 'Details anzeigen';

  @override
  String get sharedWith => 'GETEILT MIT';

  @override
  String get notes => 'NOTIZEN';

  @override
  String get notesEmpty =>
      'Noch nichts. Hinterlassen Sie einen Gedanke für alle, die mit Ihnen herunterzählen.';

  @override
  String get addNote => 'Notiz hinzufügen';

  @override
  String get years => 'Jahre';

  @override
  String get months => 'Monate';

  @override
  String get days => 'Tage';

  @override
  String get hours => 'Stunden';

  @override
  String remainingMinutes(int count) {
    return '$count Min.';
  }

  @override
  String remainingSeconds(int count) {
    return 'Noch $count Sek.';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get keep => 'Behalten';

  @override
  String get stay => 'Bleiben';

  @override
  String get leave => 'Verlassen';

  @override
  String get remove => 'Entfernen';

  @override
  String get delete => 'Löschen';

  @override
  String get create => 'Erstellen';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get share => 'Teilen';

  @override
  String get passed => 'Vorbei';

  @override
  String get upcoming => 'Bevorstehend';

  @override
  String get accepted => 'Angenommen';

  @override
  String get declined => 'Abgelehnt';

  @override
  String get removed => 'Entfernt';

  @override
  String get reopened => 'Erneut geöffnet';

  @override
  String get waiting => 'Wartend';

  @override
  String get itHasArrived => 'Der Moment ist da.';

  @override
  String remainingToGo(String remaining) {
    return 'Noch $remaining';
  }

  @override
  String get momentHasPassed => 'Der Moment ist vorbei';

  @override
  String remainingAnd(String first, String last) {
    return '$first und $last';
  }

  @override
  String get dayHasCome => 'DER TAG IST GEKOMMEN';

  @override
  String eventArrivedWithDescription(String title, String description) {
    return '$title ist da — $description';
  }

  @override
  String eventArrivedTitleOnly(String title) {
    return '$title ist da — genießen Sie jede Minute.';
  }

  @override
  String personRemovedFromCircle(String personName, String circleName) {
    return '$personName wurde aus „$circleName“ entfernt.';
  }

  @override
  String youLeftCircle(String circleName) {
    return 'Sie haben „$circleName“ verlassen.';
  }

  @override
  String circleDeleted(String circleName) {
    return '„$circleName“ wurde gelöscht.';
  }

  @override
  String get someone => 'Jemand';

  @override
  String invitedYouToCircle(String personName, String circleName) {
    return '$personName hat Sie zu „$circleName“ eingeladen';
  }

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleEditor => 'Bearbeiter';

  @override
  String get roleViewer => 'Betrachter';

  @override
  String get roleAdminDescription =>
      'Kann den Countdown und seine Teilnehmer verwalten.';

  @override
  String get roleEditorDescription =>
      'Kann den Countdown bearbeiten und andere einladen.';

  @override
  String get roleViewerDescription =>
      'Kann den Countdown ansehen und Notizen hinterlassen.';

  @override
  String remainingYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jahre',
      one: '$count Jahr',
    );
    return '$_temp0';
  }

  @override
  String remainingMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Monate',
      one: '$count Monat',
    );
    return '$_temp0';
  }

  @override
  String remainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '$count Tag',
    );
    return '$_temp0';
  }

  @override
  String remainingHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '$count Stunde',
    );
    return '$_temp0';
  }

  @override
  String remainingMinuteUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '$count Minute',
    );
    return '$_temp0';
  }

  @override
  String remainingSecondUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sekunden',
      one: '$count Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get block => 'Blockieren';

  @override
  String roleChanged(String personName, String role) {
    return '$personName hat jetzt die Rolle $role.';
  }

  @override
  String personRemoved(String personName) {
    return '$personName wurde entfernt.';
  }

  @override
  String get signInToSaveIt => 'Zum Speichern anmelden';

  @override
  String get countdownsFollowYou =>
      'Countdowns werden in Ihrem Konto gespeichert und folgen Ihnen auf jedes Gerät; Sie können sie mit anderen teilen.';

  @override
  String get savePermissionError =>
      'Firestore hat das Speichern abgelehnt. Falls dies weiterhin passiert, sind die bereitgestellten Sicherheitsregeln älter als die App — führen Sie `firebase deploy --only firestore:rules` aus.';

  @override
  String get saveNetworkError =>
      'Firestore konnte nicht erreicht werden. Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get saveFailed =>
      'Speichern fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get momentPassed => 'Der Moment ist vorbei';

  @override
  String get and => 'und';

  @override
  String get back => 'Zurück';

  @override
  String get policyLastUpdated =>
      'Zuletzt aktualisiert: Februar 2026 — Entspricht der EU-DSGVO und dem kanadischen PIPEDA';

  @override
  String get privacyIntroTitle => '1. Einleitung & Verantwortlicher';

  @override
  String privacyIntroBody(String supportEmail) {
    return 'Date Dawn („wir“, „ens“ oder „unser“) respektiert Ihre Privatsphäre und verpflichtet sich zum Schutz Ihrer personenbezogenen Daten. Diese Datenschutzrichtlinie erläutert, wie wir Ihre Informationen erfassen, verwenden und schützen, wenn Sie unsere mobilen und Webanwendungen nutzen, vollständig gemäß der Datenschutz-Grundverordnung der Europäischen Union (DSGVO) und dem Personal Information Protection and Electronic Documents Act (PIPEDA) Kanadas.\n\nAnschrift des Verantwortlichen: $supportEmail';
  }

  @override
  String get privacyCollectTitle => '2. Von uns erfasste Informationen';

  @override
  String get privacyCollectBody =>
      '• Kontodaten: E-Mail-Adresse und Anzeigename, die bei der Authentifizierung angegeben werden (Firebase Auth).\n• Nutzerinhalte: Countdowns, Titel, Daten, Beschreibungen und Kreis-Mitgliedschaften, die Sie ausdrücklich erstellen oder teilen.\n• Geräte- und Benachrichtigungsdaten: Push-Benachrichtigungstokens zur Zustellung von Countdown-Erinnerungen und Einladungsbenachrichtigungen.\n\nWir erfassen KEINEN Browserverlauf, KEINE Werbe-IDs, KEINE Standortdaten und verkaufen keine personenbezogenen Informationen an Dritte.';

  @override
  String get privacyBasisTitle =>
      '3. Rechtsgrundlagen der Verarbeitung (EU-DSGVO)';

  @override
  String get privacyBasisBody =>
      'Wir verarbeiten Ihre Daten auf folgenden Rechtsgrundlagen:\n• Vertragserfüllung: Bereitstellung der Countdown-Synchronisierung, Kreis-Freigaben und Einladungsfunktionen.\n• Einwilligung: Wenn Sie Push-Benachrichtigungen erlauben oder gemeinsam genutzten Kreisen zustimmen.\n• Berechtigte Interessen: Gewährleistung von Sicherheit und Zuverlässigkeit der Anwendung sowie Missbrauchsprävention.';

  @override
  String get privacySharingTitle => '4. Teilen & Blockieren';

  @override
  String get privacySharingBody =>
      'Date Dawn ermöglicht die direkte Interaktion zwischen Personen: Sie können jemandem einen Countdown einladen, und beide können Notizen in einem gemeinsam genutzten Countdown hinterlassen. Diese Inhalte sind nur für die Personen sichtbar, die diesem Countdown zugeordnet sind — niemals öffentlich und niemals für andere Personen.\n\nSie können eine andere Person jederzeit blockieren: öffnen Sie einen Countdown, den Sie mit ihr teilen, und halten Sie ihren Namen lange gedrückt (oder klicken Sie auf dem Desktop mit der rechten Maustaste). Beim Blockieren werden Sie gegenseitig aus gemeinsamen Countdowns entfernt, Einladungen zwischen Ihnen werden aufgehoben und die andere Person kann Sie nicht erneut einladen. Die Person wird nicht informiert. Die Liste der von Ihnen blockierten Personen ist privat; Sie können jede Person in Einstellungen — Blockierte Personen wieder freischalten.';

  @override
  String get privacyStorageTitle => '5. Datenspeicherung & Sicherheit';

  @override
  String get privacyStorageBody =>
      'Ihre Daten werden sicher gespeichert und verarbeitet, unter Verwendung der Infrastruktur von Firebase (Google Cloud Platform), die hohen branchenüblichen Sicherheitsstandards entspricht. Die zwischen Ihrem Gerät und unseren Servern übertragenen Daten werden während der Übertragung mit TLS verschlüsselt.';

  @override
  String get privacyRightsTitle =>
      '6. Ihre Rechte (Auskunft, Berichtigung & Löschung)';

  @override
  String privacyRightsBody(String supportEmail) {
    return 'Nach DSGVO und PIPEDA haben Sie das Recht:\n• Auskunft: Eine Kopie der personenbezogenen Daten anzufordern, die wir über Sie gespeichert haben.\n• Berichtigung: Ihre Profilinformationen in den Einstellungen aktualisieren oder korrigieren.\n• Löschung (Recht auf Vergessenwerden): Die vollständige Löschung Ihres Kontos sowie aller zugehörigen Countdowns und Benachrichtigungen jederzeit durch eine Nachricht an $supportEmail anfordern.';
  }

  @override
  String get termsAcceptanceTitle => '1. Annahme der Nutzungsbedingungen';

  @override
  String get termsAcceptanceBody =>
      'Durch den Zugriff auf oder die Nutzung von Date Dawn erklären Sie sich mit diesen Nutzungsbedingungen einverstanden. Wenn Sie diesen Bedingungen nicht zustimmen, nutzen Sie die Anwendung bitte nicht.';

  @override
  String get termsUseTitle => '2. Nutzung des Dienstes';

  @override
  String get termsUseBody =>
      'Date Dawn wird für persönliche, nicht kommerzielle Countdown- und gemeinsame Momentverfolgung bereitgestellt. Sie verpflichten sich, den Dienst nicht missbräuchlich zu nutzen, keine bösartigen Inhalte hochzuladen, andere Nutzer nicht über gemeinsame Kreise oder Einladungen zu belästigen oder Sicherheitskontrollen zu umgehen.';

  @override
  String get termsOwnershipTitle => '3. Nutzerinhalte & Eigentumsrechte';

  @override
  String get termsOwnershipBody =>
      'Sie behalten alle Eigentumsrechte an den Countdown-Events, Titeln und Inhalten, die Sie erstellen. Sie erteilen Date Dawn eine eingeschränkte Lizenz, Ihre Inhalte ausschließlich zur Speicherung und Synchronisierung zwischen Ihren authentifizierten Geräten und gemeinsam genutzten Kreismitgliedern zu verwenden.';

  @override
  String get termsTerminationTitle => '4. Kündigung & Kontolöschung';

  @override
  String get termsTerminationBody =>
      'Sie können Date Dawn jederzeit nicht mehr nutzen und die Löschung Ihres Kontos per E-Mail an den Support beantragen. Wir behalten uns das Recht vor, Konten auszusetzen oder zu kündigen, die gegen diese Bedingungen verstoßen oder die Infrastruktur missbrauchen.';

  @override
  String get termsLiabilityTitle => '5. Haftungsbeschränkung';

  @override
  String get termsLiabilityBody =>
      'Date Dawn wird „wie besehen“ ohne jegliche Gewährleistung bereitgestellt. Wir haften nicht für indirekte, zufällige oder Folgeschäden, die aus Ihrer Nutzung der Anwendung entstehen.';

  @override
  String get privacyPolicyTitle => 'Datenschutzrichtlinie';

  @override
  String get termsOfServiceTitle => 'Nutzungsbedingungen';

  @override
  String get supportHeading => 'Wir lesen jede Nachricht';

  @override
  String supportIntro(String responseTime) {
    return 'Date Dawn ist eine kleine, unabhängige App. E-Mail ist der schnellste Weg zu der Person, die sie entwickelt — es gibt keine zwischengeschaltete Support-Abteilung. Wir antworten normalerweise $responseTime.';
  }

  @override
  String get supportResponseTime => 'innerhalb von 2 Werktagen';

  @override
  String get supportCommonQuestions => 'Häufige Fragen';

  @override
  String get supportFaqGoogleQuestion =>
      'Ich habe mich mit Google angemeldet und meine Countdowns fehlen.';

  @override
  String get supportFaqGoogleAnswer =>
      'Verwenden Sie dieselbe Anmeldemethode, die Sie bei der Erstellung Ihres Kontos genutzt haben. Google und E-Mail/Passwort werden nicht automatisch miteinander verknüpft. Wenn Sie die Methode wechseln oder vermuten, dass Daten in zwei Konten liegen, kontaktieren Sie uns, bevor Sie ein weiteres Konto erstellen.';

  @override
  String get supportFaqSharingQuestion =>
      'Eine Person, mit der ich den Countdown geteilt habe, kann ihn nicht sehen.';

  @override
  String get supportFaqSharingAnswer =>
      'Beim Teilen eines Countdowns mit einem Kreis wird eine Einladung gesendet — Personen werden nicht automatisch hinzugefügt. Sie müssen Einladungen in der App öffnen und die Einladung annehmen. Ein Paar-Kreis ist die Ausnahme: Diese Freigabe erfolgt sofort.';

  @override
  String get supportFaqDeclinedQuestion =>
      'Ich habe versehentlich eine Einladung abgelehnt.';

  @override
  String get supportFaqDeclinedAnswer =>
      'Bitten Sie die einladende Person, Sie erneut einzuladen — dies ist im Countdown über das Aktualisierungssymbol neben Ihrem Namen möglich. In der Zwischenzeit geht nichts verloren.';

  @override
  String get supportFaqDeleteQuestion =>
      'Wie lösche ich mein Konto und meine Daten?';

  @override
  String get supportFaqDeleteAnswer =>
      'Schreiben Sie uns von der E-Mail-Adresse, mit der Sie sich registriert haben, und bitten Sie um Löschung. Jeder Countdown, jede Einladung und jede Benachrichtigung, die mit dem Konto verknüpft ist, wird entfernt; wir bestätigen Ihnen den Abschluss.';

  @override
  String get supportFaqBlockQuestion => 'Wie kann ich jemanden blockieren?';

  @override
  String get supportFaqBlockAnswer =>
      'öffnen Sie einen Countdown, den Sie mit dieser Person teilen, halten Sie ihren Namen in der Personenliste lange gedrückt (oder klicken Sie auf einem Computer mit der rechten Maustaste). Die Person wird aus Ihren gemeinsam genutzten Countdowns entfernt und kann Sie nicht erneut einladen. Zum Rückgängigmachen öffnen Sie Einstellungen — Blockierte Personen.';

  @override
  String get supportFaqAdsQuestion =>
      'Verkaufen Sie meine Daten oder zeigen Sie Werbung?';

  @override
  String get supportFaqAdsAnswer =>
      'Nein. Es gibt keine Werbung, keine Analyseprofile und kein Tracking durch Drittanbieter. Ihre Countdowns sind ausschließlich Ihre Angelegenheit und werden in Ihrem Konto gespeichert, damit sie niemand anderes lesen kann.';

  @override
  String get supportLegal => 'Rechtliches';

  @override
  String get supportNotice =>
      'Eine Rückerstattung, eine Abrechnungsfrage oder ein Absturzbericht gehören alle an dieselbe Adresse. Wenn die App nicht richtig funktioniert, sind Angaben zu Ihrem Gerät und zu Ihrem Vorgehen unmittelbar davor am hilfreichsten.';

  @override
  String get supportEmailLabel => 'Support per E-Mail';

  @override
  String supportEmailCopied(String email) {
    return '$email wurde kopiert';
  }

  @override
  String get openMail => 'E-Mail-App öffnen';

  @override
  String get linkCopiedClipboard => 'Link in die Zwischenablage kopiert.';

  @override
  String get verifyEmailTitle => 'E-Mail-Adresse bestätigen';

  @override
  String verifyEmailInstructions(String email) {
    return 'Wir haben einen Bestätigungslink an $email gesendet. Bitte bestätigen Sie ihn, um fortzufahren.';
  }

  @override
  String get yourEmailAddress => 'Ihre E-Mail-Adresse';

  @override
  String resetLinkSent(String email) {
    return 'Zurücksetzungslink wurde an $email gesendet. Verwenden Sie die neueste E-Mail.';
  }

  @override
  String get verificationEmailSent => 'Bestätigungs-E-Mail gesendet.';

  @override
  String get verificationNotComplete =>
      'Noch nicht bestätigt. Prüfen Sie Ihren Posteingang.';

  @override
  String get verifiedSignInToContinue =>
      'Ihre E-Mail-Adresse wurde bestätigt. Melden Sie sich gegebenenfalls an, um fortzufahren.';

  @override
  String get checkSpamFolder =>
      'E-Mail nicht gefunden? Prüfen Sie Ihren Spam- oder Junk-Ordner.';

  @override
  String get confirmEmailVerified => 'Ich habe meine E-Mail-Adresse bestätigt';

  @override
  String get sendingEmail => 'Wird gesendet?';

  @override
  String get resendEmail => 'E-Mail erneut senden';

  @override
  String get waitBeforeResending =>
      'Bitte warten Sie 60 Sekunden, bevor Sie eine weitere E-Mail anfordern.';

  @override
  String get resetCodeMissing =>
      'In diesem Zurücksetzungslink fehlt der Sicherheitscode.';

  @override
  String get passwordUpdatedSignIn =>
      'Passwort aktualisiert. Melden Sie sich erneut an.';

  @override
  String get resetLinkInvalidTitle =>
      'Dieser Zurücksetzungslink kann nicht verwendet werden';

  @override
  String get resetLinkInvalidBody =>
      'Der Link ist möglicherweise abgelaufen oder wurde bereits verwendet. Kehren Sie zur Anmeldung zurück und fordern Sie eine neue E-Mail zum Zurücksetzen des Passworts an.';

  @override
  String get backToSignIn => 'Zurück zur Anmeldung';

  @override
  String get chooseNewPassword => 'Neues Passwort wählen';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get passwordMinLength => 'Verwenden Sie mindestens 6 Zeichen.';

  @override
  String get passwordsDoNotMatch => 'Die Passwörter stimmen nicht überein.';

  @override
  String get updatePassword => 'Passwort aktualisieren';

  @override
  String get editCountdownAction => 'Bearbeiten';

  @override
  String get duplicateYearLater => 'Ein Jahr später duplizieren';

  @override
  String get countdownDuplicated =>
      'Dupliziert — öffnen Sie den Countdown, um das Datum anzupassen.';

  @override
  String get onlyOwnerCanDelete =>
      'Nur die Eigentümerin oder der Eigentümer kann diesen Countdown löschen.';

  @override
  String get countdownDeleteFailed =>
      'Löschen fehlgeschlagen. Versuchen Sie es erneut.';

  @override
  String get countdownDeleteWarning =>
      'Das Löschen des Countdowns kann nicht rückgängig gemacht werden.';

  @override
  String blockPersonQuestion(String personName) {
    return '$personName blockieren?';
  }

  @override
  String get blockExplanation =>
      'Sie sehen einander nicht mehr. Die Person wird aus allen von Ihnen gemeinsam genutzten Countdowns entfernt, Einladungen zwischen Ihnen werden aufgehoben und die Person kann Sie nicht erneut einladen. Sie wird nicht informiert.';

  @override
  String get undoBlockInSettings =>
      'Sie können dies jederzeit unter Einstellungen — Blockierte Personen rückgängig machen.';

  @override
  String get blocking => 'Wird blockiert?';

  @override
  String get blockAction => 'Blockieren';

  @override
  String personBlocked(String personName) {
    return '$personName ist blockiert.';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String personUnblocked(String personName) {
    return 'Die Blockierung von $personName wurde aufgehoben.';
  }

  @override
  String get blockAccessNotRestored =>
      'Der Countdown-Zugriff wurde nicht wiederhergestellt.';

  @override
  String get undoBlockFailed =>
      'Die Blockierung konnte nicht aufgehoben werden. Bitte versuchen Sie es erneut.';

  @override
  String get blockSaveFailed =>
      'Ihre Blockierung konnte nicht gespeichert werden. Melden Sie sich erneut an und versuchen Sie es noch einmal.';

  @override
  String get noConnectionRetry =>
      'Keine Verbindung. Prüfen Sie Ihr Netzwerk und versuchen Sie es erneut.';

  @override
  String blockPersonFailed(String personName) {
    return '$personName konnte nicht blockiert werden. Bitte versuchen Sie es erneut.';
  }

  @override
  String get blockedPeopleTitle => 'Blockierte Personen';

  @override
  String get nobodyBlocked => 'Niemand ist blockiert';

  @override
  String get howToBlockPerson =>
      'Um jemanden zu blockieren, öffnen Sie einen Countdown, den Sie mit dieser Person teilen, öffnen Sie das Menü — in deren Zeile und tippen Sie auf „Blockieren“.';

  @override
  String get blockedPeopleDescription =>
      'Diese Personen können Sie nicht einladen, und Sie teilen keine Countdowns mit ihnen. Ihnen wird nicht mitgeteilt, dass sie blockiert wurden.';

  @override
  String get unblock => 'Blockierung aufheben';

  @override
  String get blockedListLoadFailed =>
      'Blockierte Personen konnten nicht geladen werden.';

  @override
  String get blockedListPermissionError =>
      'Sie können die Liste der blockierten Personen nicht laden. Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountWarning =>
      'Diese Aktion ist endgültig. Alle deine Ereignisse, Kreise und Daten werden für immer gelöscht.';

  @override
  String get deleteAccountConfirmationPrompt =>
      'Gib deine genaue Konto-E-Mail-Adresse ein, um fortzufahren.';

  @override
  String get deleteAccountConfirmationLabel => 'Konto-E-Mail-Adresse';

  @override
  String get permanentlyDeleteAccount => 'Konto endgültig löschen';

  @override
  String get deleteAccountProfileConsequence =>
      'Dein Profil wird dauerhaft gelöscht.';

  @override
  String get deleteAccountAccessConsequence =>
      'Du verlierst den Zugriff auf alle deine Ereignisse und Kreise.';

  @override
  String get deleteAccountIrreversibleConsequence =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteAccountPermanentlyAction => 'Konto endgültig löschen';

  @override
  String get accountDeleted => 'Konto erfolgreich gelöscht';

  @override
  String get serverTimedOutTryAgain =>
      'Zeitüberschreitung beim Server. Bitte versuche es später erneut.';

  @override
  String get accountDeletionFailed =>
      'Das Konto konnte nicht gelöscht werden. Bitte versuche es erneut.';

  @override
  String get accountDeletedCleanupWarning =>
      'Das Konto wurde gelöscht, aber einige lokale Einstellungen konnten nicht entfernt werden. Starte die App neu, bevor du ein anderes Konto verwendest.';
}
