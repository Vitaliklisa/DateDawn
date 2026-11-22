// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Date Dawn';

  @override
  String get language => 'Langue';

  @override
  String get followSystemLanguage => 'Suivre la langue du système';

  @override
  String get languageChanged => 'Langue modifiée.';

  @override
  String get languageSaveFailed =>
      'Impossible d’enregistrer votre préférence de langue.';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageUkrainian => 'Ukrainien';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languageChinese => 'Chinois traditionnel (Taïwan)';

  @override
  String get settings => 'Réglages';

  @override
  String get dateDawnUser => 'Utilisateur Date Dawn';

  @override
  String get guestAccount => 'Compte invité';

  @override
  String get notSignedIn => 'Vous n’êtes pas connecté';

  @override
  String get syncAndShareDescription =>
      'Connectez-vous pour synchroniser vos comptes à rebours sur tous vos appareils et les partager.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get appearance => 'APPARENCE';

  @override
  String get darkTheme => 'Sombre';

  @override
  String get lightTheme => 'Clair';

  @override
  String get systemTheme => 'Système';

  @override
  String get time => 'HEURE';

  @override
  String get timeFormatDescription =>
      'Choisissez l’affichage de l’heure. Les comptes à rebours restent des instants précis ; seul leur affichage change.';

  @override
  String get twelveHourTime => '12 heures (AM/PM)';

  @override
  String get twentyFourHourTime => '24 heures';

  @override
  String get about => 'À PROPOS';

  @override
  String get version => 'Version';

  @override
  String get sync => 'Synchronisation';

  @override
  String get safety => 'SÉCURITÉ';

  @override
  String get blockedPeople => 'Personnes bloquées';

  @override
  String get legal => 'JURIDIQUE';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d’utilisation';

  @override
  String get helpAndSupport => 'Aide et assistance';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signedOut => 'Déconnexion effectuée.';

  @override
  String countdownsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comptes à rebours',
      one: '$count compte à rebours',
    );
    return '$_temp0';
  }

  @override
  String get welcomeToDateDawn => 'Bienvenue sur Date Dawn';

  @override
  String get createYourAccount => 'Créez votre compte';

  @override
  String get countdownsSyncDescription =>
      'Vos comptes à rebours se synchronisent sur tous les appareils utilisés.';

  @override
  String get welcomeDescription =>
      'Compte à rebours jusqu’aux moments importants, sur téléphone, tablette et web.';

  @override
  String get name => 'Nom';

  @override
  String get nameHint => 'Alex Rivera';

  @override
  String get nameRequired => 'Comment souhaitez-vous que l’on vous appelle ?';

  @override
  String get email => 'E-mail';

  @override
  String get emailHint => 'vous@exemple.com';

  @override
  String get emailRequired => 'Saisissez votre adresse e-mail.';

  @override
  String get emailInvalid => 'Cette adresse e-mail semble incorrecte.';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordRequired => 'Saisissez votre mot de passe.';

  @override
  String get passwordTooShort => 'Utilisez au moins 6 caractères.';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordPrompt =>
      'Saisissez d’abord votre e-mail, puis appuyez sur « Mot de passe oublié ». ';

  @override
  String get signInConnectionError =>
      'Service de connexion inaccessible. Vérifiez votre connexion Internet.';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get or => 'OU';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? ';

  @override
  String get newHere => 'Nouveau ici ? ';

  @override
  String get createOne => 'En créer un';

  @override
  String get troubleSigningIn => 'Problème de connexion ? Obtenir de l’aide';

  @override
  String get accountCreated => 'Compte créé.';

  @override
  String get welcomeBack => 'Bon retour.';

  @override
  String get signInFailed => 'Connexion impossible. Veuillez réessayer.';

  @override
  String get signedInWithGoogle => 'Connecté avec Google.';

  @override
  String get home => 'Accueil';

  @override
  String get invitations => 'Invitations';

  @override
  String get circles => 'Cercles';

  @override
  String get notifications => 'Notifications';

  @override
  String get support => 'Assistance';

  @override
  String get homeEmptyTitle => 'Nommez une date.';

  @override
  String get homeEmptyDescription =>
      'Choisissez un moment à venir — un mariage, un lancement, un retour chez vous. Date Dawn compte les années, les mois, les jours et les heures qu’il reste, puis célèbre le moment quand il arrive.';

  @override
  String get homeLoadError =>
      'Impossible d’atteindre vos comptes à rebours. Tirez vers le bas pour réessayer.';

  @override
  String get getStarted => 'Commencer';

  @override
  String get homeSyncTitle => 'Gardez-les partout';

  @override
  String get homeSyncDescription =>
      'Connectez-vous pour synchroniser vos comptes à rebours sur téléphone, tablette et web — et pour les partager avec les personnes qui comptent aussi le temps avec vous.';

  @override
  String get otherCountdowns => 'AUTRES COMPTES À REBOURS';

  @override
  String get arrived => 'ARRIVÉ';

  @override
  String get countingDown => 'COMPTE À REBOURS';

  @override
  String get options => 'Options';

  @override
  String get open => 'Ouvrir';

  @override
  String get openCountdown => 'Ouvrir le compte à rebours';

  @override
  String get newCountdown => 'Nouveau compte à rebours';

  @override
  String get editCountdown => 'Modifier le compte à rebours';

  @override
  String get countdownTitleLabel => 'Titre';

  @override
  String get countdownDescriptionLabel => 'Description';

  @override
  String get whenLabel => 'Quand';

  @override
  String get titleExampleHint => 'Mariage, lancement, réunion';

  @override
  String get descriptionExampleHint => 'Une courte note à propos du jour';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Heure';

  @override
  String get presetWeek => '+1 semaine';

  @override
  String get presetMonth => '+1 mois';

  @override
  String get presetYear => '+1 an';

  @override
  String get presetFiveYears => '+5 ans';

  @override
  String get createCountdown => 'Créer un compte à rebours';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get deleteCountdown => 'Supprimer le compte à rebours';

  @override
  String get countdownActions => 'Actions du compte à rebours';

  @override
  String get deleteCountdownQuestion => 'Supprimer ce compte à rebours ?';

  @override
  String get countdownCannotUndo =>
      'La suppression du compte à rebours est définitive.';

  @override
  String get giveCountdownTitle => 'Donnez un titre à ce compte à rebours.';

  @override
  String get pickFutureMoment => 'Choisissez un moment encore à venir.';

  @override
  String get signInToSaveCountdown =>
      'Connectez-vous pour enregistrer les comptes à rebours.';

  @override
  String get countdownCreated => 'Compte à rebours créé.';

  @override
  String get changesSaved => 'Modifications enregistrées.';

  @override
  String get countdownDeleted => 'Compte à rebours supprimé.';

  @override
  String get partnerLabel => 'votre partenaire';

  @override
  String partnerNotAdded(String partnerName) {
    return 'Compte à rebours créé, mais $partnerName n’a pas été ajouté. Invitez-le manuellement depuis le compte à rebours.';
  }

  @override
  String partnerAdded(String partnerName) {
    return 'Compte à rebours créé. $partnerName a été ajouté.';
  }

  @override
  String get noPartnerAdded =>
      'Compte à rebours créé, mais aucun partenaire n’a été ajouté. Invitez-le manuellement.';

  @override
  String get chooseFutureDateHint =>
      'Choisissez une date future pour voir le compte à rebours.';

  @override
  String countingDownRemaining(String remaining) {
    return 'Compte à rebours en cours $remaining';
  }

  @override
  String get cannotEditCountdown =>
      'Vous pouvez voir ce compte à rebours, mais pas le modifier.';

  @override
  String get shareWith => 'Partager avec';

  @override
  String get circleShareDescription =>
      'Un cercle de couple se partage instantanément. Les autres cercles reçoivent une invitation.';

  @override
  String get collaborators => 'Collaborateurs';

  @override
  String get collaboratorsCanFollow =>
      'Toute personne que vous invitez peut suivre ce compte à rebours sur ses propres appareils.';

  @override
  String get peopleFollowing => 'Personnes qui suivent ce compte à rebours.';

  @override
  String get noCollaboratorsYet => 'Personne d’autre pour le moment.';

  @override
  String get nameEmailHint => 'nom@exemple.com';

  @override
  String get recentContactsCouldNotLoad =>
      'Les contacts récents n’ont pas pu être chargés. Vérifiez votre connexion ou les règles Firestore.';

  @override
  String invitationSentTo(String email) {
    return 'Invitation envoyée à $email.';
  }

  @override
  String sharedWithCircle(String circleName) {
    return 'Partagé avec $circleName';
  }

  @override
  String get inviteAgain => 'Inviter à nouveau';

  @override
  String get removePersonQuestion => 'Retirer cette personne ?';

  @override
  String collaboratorLosesAccess(String email) {
    return '$email perdra l’accès à ce compte à rebours et ne le verra plus dans sa liste.';
  }

  @override
  String get changeRole => 'Modifier le rôle';

  @override
  String changeRoleFor(String personName) {
    return 'Modifier le rôle de $personName';
  }

  @override
  String roleChangeDescription(String role) {
    return 'Cela change ce qu’il peut faire sur ce compte à rebours à partir de maintenant. Il a actuellement un accès $role.';
  }

  @override
  String rolesNotAssignable(String roles, String topRole) {
    return '$roles ne peuvent pas être attribués par vous — vous êtes $topRole.';
  }

  @override
  String get circlesDescriptionTitle =>
      'Groupes avec lesquels vous comptez le temps';

  @override
  String get circlesDescription =>
      'Invitez quelqu’un à un cercle une fois, puis partagez n’importe quel compte à rebours avec tout le groupe en un seul geste. Un cercle de couple est partagé automatiquement — tout ce qu’un de vous crée, l’autre le voit.';

  @override
  String get circlesLoadError =>
      'Impossible de charger vos cercles. Tirez vers le bas pour réessayer.';

  @override
  String get noCircles => 'Aucun cercle pour le moment';

  @override
  String get noCirclesDescription =>
      'Créez-en un pour les personnes avec lesquelles vous comptez le temps — un partenaire, votre famille ou les amis avec qui vous partez en voyage chaque année.';

  @override
  String get newCircle => 'Nouveau cercle';

  @override
  String get sharesAutomatically => 'Partage automatique';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '$count personne',
    );
    return '$_temp0';
  }

  @override
  String get inviteSomeone => 'Inviter quelqu’un';

  @override
  String get you => 'Vous';

  @override
  String get leaveCircle => 'Quitter le cercle';

  @override
  String get deleteCircle => 'Supprimer le cercle';

  @override
  String get removeFromCircle => 'Retirer du cercle';

  @override
  String removeMemberQuestion(String personName) {
    return 'Retirer $personName ?';
  }

  @override
  String get removeMemberExplanation =>
      'Ils cesseront de voir les comptes à rebours partagés avec ce cercle. Rien de ce qu’ils ont créé n’est supprimé.';

  @override
  String leaveCircleQuestion(String circleName) {
    return 'Quitter “$circleName” ?';
  }

  @override
  String get leaveCircleExplanation =>
      'Les comptes à rebours partagés avec ce cercle n’apparaîtront plus pour vous. Vous pouvez être invité à nouveau.';

  @override
  String deleteCircleQuestion(String circleName) {
    return 'Supprimer “$circleName” ?';
  }

  @override
  String get deleteCircleExplanation =>
      'Le groupe disparaît. Les comptes à rebours partagés avec lui sont conservés et restent à vous — ils ne sont simplement plus partagés avec ces personnes.';

  @override
  String get circleNameHint => 'Famille, Tokyo 2027, Nous';

  @override
  String get coupleCircleTitle => 'C’est nous — un couple';

  @override
  String get coupleCircleDescription =>
      'Les comptes à rebours sont partagés avec votre partenaire automatiquement, sans invitation à accepter.';

  @override
  String get circleCreated => 'Cercle créé.';

  @override
  String get coupleCircleCreated => 'Créé. Invitez votre partenaire ensuite.';

  @override
  String get inviteYourPartner => 'Inviter votre partenaire';

  @override
  String inviteToCircle(String circleName) {
    return 'Inviter à “$circleName”';
  }

  @override
  String get coupleInviteExplanation =>
      'S’ils ont déjà un compte, ils seront ajoutés automatiquement. Sinon, ils seront ajoutés lorsqu’ils se connecteront. Les futurs comptes à rebours partagés avec ce cercle apparaîtront automatiquement.';

  @override
  String get circleInviteExplanation =>
      'Ils recevront une invitation à accepter ou refuser. Une fois qu’ils auront rejoint, vous pourrez partager des comptes à rebours avec ce cercle en un seul geste.';

  @override
  String get inviteEmailHint => 'eux@exemple.com';

  @override
  String get sendInvitation => 'Envoyer une invitation';

  @override
  String get partnerAddedAutomatically =>
      'Votre partenaire sera ajouté automatiquement.';

  @override
  String get signInToUseCircles => 'Connectez-vous pour utiliser les cercles';

  @override
  String get circlesRequireAccounts =>
      'Les cercles invitent des personnes par e-mail, donc elles ont besoin d’un compte pour être invitées.';

  @override
  String get waitingOnYou => 'En attente de votre réponse';

  @override
  String get invitationsEmptyDescription =>
      'Rien n’est partagé avec vous tant que vous n’acceptez pas. Refuser indique à la personne qui vous a invité qu’elle n’a pas à se demander.';

  @override
  String get signInToSeeInvitations =>
      'Connectez-vous pour voir les invitations';

  @override
  String get invitationsEmailAccount =>
      'Les invitations sont adressées à votre e-mail, donc connectez-vous avec l’adresse à laquelle quelqu’un vous a invité.';

  @override
  String get invitationsCouldNotLoad =>
      'Les invitations n’ont pas pu être chargées. Vérifiez votre connexion ou les règles Firestore.';

  @override
  String get nothingWaiting => 'Rien en attente';

  @override
  String get invitationInboxEmpty =>
      'Les invitations que les gens vous envoient apparaîtront ici. Les invitations de compte à rebours et de cercle standard nécessitent votre réponse ; les cercles de couple se rejoignent automatiquement.';

  @override
  String get retryAddingYou => 'Réessayer de vous ajouter';

  @override
  String get decline => 'Refuser';

  @override
  String joinInviteQuestion(String eventTitle) {
    return 'Rejoindre “$eventTitle” ?';
  }

  @override
  String get joinInviteExplanation =>
      'Il apparaîtra dans votre liste et vous obtiendrez son compte à rebours sur cet appareil.';

  @override
  String get join => 'Rejoindre';

  @override
  String alreadyMemberOf(String name) {
    return 'Vous êtes déjà membre de “$name”.';
  }

  @override
  String youJoined(String name) {
    return 'Vous avez rejoint “$name”.';
  }

  @override
  String youWereAddedTo(String name) {
    return 'Vous avez été ajouté à “$name”.';
  }

  @override
  String get invitationDeclined => 'Invitation refusée.';

  @override
  String get countdownInvitation => 'Invitation à un compte à rebours';

  @override
  String get aCountdown => 'Un compte à rebours';

  @override
  String invitedToFollowCountdown(String role) {
    return 'Vous avez été invité à suivre ce compte à rebours. L’accepter l’ajoute à votre liste en tant que $role.';
  }

  @override
  String get accept => 'Accepter';

  @override
  String get partnerInvitation => 'Invitation de partenaire';

  @override
  String get circleInvitation => 'Invitation à un cercle';

  @override
  String partnerCircleAddTitle(String personName) {
    return 'Vous êtes en train d’être ajouté au cercle de $personName';
  }

  @override
  String get partnerCircleAddExplanation =>
      'Vous serez ajouté automatiquement. Les événements de compte à rebours partagés avec ce cercle apparaîtront dans votre liste.';

  @override
  String circleJoinExplanation(String circleName) {
    return 'Rejoindre “$circleName” signifie que les comptes à rebours qu’ils partagent avec ce cercle apparaîtront dans votre liste.';
  }

  @override
  String get becomePartners => 'Devenir partenaires';

  @override
  String get joinCircle => 'Rejoindre le cercle';

  @override
  String get automaticJoinFailed =>
      'L’adhésion automatique n’a pas pu être terminée.';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get markedAllRead => 'Tout marqué comme lu.';

  @override
  String get moreOptions => 'Plus d’options';

  @override
  String get noReadMessagesToDelete => 'Aucun message lu à supprimer.';

  @override
  String get deleteReadMessages => 'Supprimer les messages lus';

  @override
  String get deletedReadMessages => 'Messages lus supprimés.';

  @override
  String get notificationsSignInFirst => 'Connectez-vous d’abord';

  @override
  String get notificationsAccountOnly =>
      'Les notifications sont liées à votre compte.';

  @override
  String get couldNotLoad => 'Impossible de charger';

  @override
  String get checkConnectionRetry => 'Vérifiez votre connexion et réessayez.';

  @override
  String get nothingYet => 'Rien pour le moment';

  @override
  String get notificationsEmptyDescription =>
      'Quand quelque chose se produit avec vos comptes à rebours ou vos invitations, cela apparaîtra ici.';

  @override
  String get liveNotificationsCouldNotLoad =>
      'Les notifications en direct n’ont pas pu être chargées.';

  @override
  String get inbox => 'BOÎTE DE RÉCEPTION';

  @override
  String get invitationResponses => 'RÉPONSES AUX INVITATIONS';

  @override
  String get invitationResponsesCouldNotLoad =>
      'Les réponses aux invitations n’ont pas pu être chargées.';

  @override
  String get countdownUnavailable =>
      'Ce compte à rebours n’est plus disponible.';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get sharedWith => 'PARTAGÉ AVEC';

  @override
  String get notes => 'NOTES';

  @override
  String get notesEmpty =>
      'Rien pour le moment. Laissez un message pour tout le monde qui compte le temps avec vous.';

  @override
  String get addNote => 'Ajouter une note';

  @override
  String get years => 'Années';

  @override
  String get months => 'Mois';

  @override
  String get days => 'Jours';

  @override
  String get hours => 'Heures';

  @override
  String remainingMinutes(int count) {
    return '$count min';
  }

  @override
  String remainingSeconds(int count) {
    return '$count s restantes';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get keep => 'Conserver';

  @override
  String get stay => 'Rester';

  @override
  String get leave => 'Quitter';

  @override
  String get remove => 'Retirer';

  @override
  String get delete => 'Supprimer';

  @override
  String get create => 'Créer';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get share => 'Partager';

  @override
  String get passed => 'Passé';

  @override
  String get upcoming => 'À venir';

  @override
  String get accepted => 'Acceptée';

  @override
  String get declined => 'Refusée';

  @override
  String get removed => 'Retirée';

  @override
  String get reopened => 'Rouverte';

  @override
  String get waiting => 'En attente';

  @override
  String get itHasArrived => 'Il est arrivé.';

  @override
  String remainingToGo(String remaining) {
    return '$remaining à faire';
  }

  @override
  String get momentHasPassed => 'Le moment est passé';

  @override
  String remainingAnd(String first, String last) {
    return '$first et $last';
  }

  @override
  String get dayHasCome => 'LE JOUR EST ARRIVÉ';

  @override
  String eventArrivedWithDescription(String title, String description) {
    return '$title est là — $description';
  }

  @override
  String eventArrivedTitleOnly(String title) {
    return '$title est là — profitez de chaque minute.';
  }

  @override
  String personRemovedFromCircle(String personName, String circleName) {
    return '$personName a été retiré de “$circleName”.';
  }

  @override
  String youLeftCircle(String circleName) {
    return 'Vous avez quitté “$circleName”.';
  }

  @override
  String circleDeleted(String circleName) {
    return '“$circleName” supprimé.';
  }

  @override
  String get someone => 'Quelqu’un';

  @override
  String invitedYouToCircle(String personName, String circleName) {
    return '$personName vous a invité à “$circleName”';
  }

  @override
  String get roleAdmin => 'Administrateur';

  @override
  String get roleEditor => 'Éditeur';

  @override
  String get roleViewer => 'Lecteur';

  @override
  String get roleAdminDescription =>
      'Peut gérer le compte à rebours et ses participants.';

  @override
  String get roleEditorDescription =>
      'Peut modifier le compte à rebours et inviter d’autres personnes.';

  @override
  String get roleViewerDescription =>
      'Peut voir le compte à rebours et laisser des notes.';

  @override
  String remainingYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ans',
      one: '$count an',
    );
    return '$_temp0';
  }

  @override
  String remainingMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois',
      one: '$count mois',
    );
    return '$_temp0';
  }

  @override
  String remainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return '$_temp0';
  }

  @override
  String remainingHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '$count heure',
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
      other: '$count secondes',
      one: '$count seconde',
    );
    return '$_temp0';
  }

  @override
  String get moreActions => 'Plus d’actions';

  @override
  String get block => 'Bloquer';

  @override
  String roleChanged(String personName, String role) {
    return '$personName est maintenant $role.';
  }

  @override
  String personRemoved(String personName) {
    return '$personName a été retiré.';
  }

  @override
  String get signInToSaveIt => 'Connectez-vous pour l’enregistrer';

  @override
  String get countdownsFollowYou =>
      'Les comptes à rebours vivent dans votre compte, donc ils vous suivent sur tous vos appareils et peuvent être partagés avec d’autres personnes.';

  @override
  String get savePermissionError =>
      'Firestore a refusé l’enregistrement. Si cela continue, les règles de sécurité déployées sont plus anciennes que l’application — exécutez `firebase deploy --only firestore:rules`.';

  @override
  String get saveNetworkError =>
      'Impossible d’atteindre Firestore. Vérifiez votre connexion et réessayez.';

  @override
  String get saveFailed => 'Impossible d’enregistrer. Veuillez réessayer.';

  @override
  String get momentPassed => 'Le moment est passé';

  @override
  String get and => 'et';

  @override
  String get back => 'Retour';

  @override
  String get policyLastUpdated =>
      'Dernière mise à jour : février 2026 · Conforme au RGPD de l’UE et à la LPRPDE du Canada';

  @override
  String get privacyIntroTitle =>
      '1. Introduction et responsable du traitement';

  @override
  String privacyIntroBody(String supportEmail) {
    return 'Date Dawn (« nous », « notre » ou « nos ») respecte votre vie privée et s’engage à protéger vos données personnelles. Cette politique de confidentialité explique comment nous collectons, utilisons et protégeons vos informations lorsque vous utilisez nos applications mobiles et web, dans le plein respect du Règlement général sur la protection des données (RGPD) de l’UE et de la Loi sur la protection des renseignements personnels et les documents électroniques (LPRPDE) du Canada.\n\nContact du responsable du traitement : $supportEmail';
  }

  @override
  String get privacyCollectTitle => '2. Informations que nous collectons';

  @override
  String get privacyCollectBody =>
      '• Données du compte : adresse e-mail et nom d’affichage fournis lors de l’authentification (Firebase Auth).\n• Contenu utilisateur : comptes à rebours, titres, dates, descriptions et adhésions à des cercles que vous créez ou partagez explicitement.\n• Données de l’appareil et des notifications : jetons de notification push pour envoyer des rappels de comptes à rebours et des alertes d’invitation.\n\nNous ne collectons PAS l’historique de navigation, les identifiants publicitaires ni les données de localisation, et nous ne vendons aucune information personnelle à des tiers.';

  @override
  String get privacyBasisTitle =>
      '3. Base légale pour le traitement (RGPD de l’UE)';

  @override
  String get privacyBasisBody =>
      'Nous traitons vos données selon les bases légales suivantes :\n• Exécution d’un contrat : fourniture de la synchronisation des comptes à rebours, du partage de cercles et des fonctionnalités d’invitation.\n• Consentement : lorsque vous accordez des autorisations de notification push ou vous inscrivez à des cercles partagés.\n• Intérêt légitime : garantir la sécurité, la fiabilité de l’application et prévenir les abus.';

  @override
  String get privacySharingTitle => '4. Partage et blocage';

  @override
  String get privacySharingBody =>
      'Date Dawn permet les interactions un à un : vous pouvez inviter quelqu’un à un compte à rebours, et vous pouvez tous les deux laisser des notes sur un compte que vous partagez. Ce contenu est visible uniquement pour les personnes concernées par ce compte à rebours — jamais public, jamais visible pour quelqu’un d’autre.\n\nVous pouvez bloquer une autre personne à tout moment : ouvrez un compte à rebours que vous partagez avec elle et appuyez longuement sur son nom (ou cliquez avec le bouton secondaire sur un ordinateur). Le blocage vous retire mutuellement des comptes à rebours, annule les invitations entre vous et l’empêche de vous inviter de nouveau. La personne n’est pas avertie. La liste des personnes que vous avez bloquées est privée et vous pouvez en débloquer n’importe qui depuis Paramètres → Personnes bloquées.';

  @override
  String get privacyStorageTitle => '5. Stockage des données et sécurité';

  @override
  String get privacyStorageBody =>
      'Vos données sont stockées et traitées en toute sécurité à l’aide de l’infrastructure Firebase (Google Cloud Platform) qui respecte des normes de sécurité élevées de l’industrie. Les données transmises entre votre appareil et nos serveurs sont chiffrées en transit via TLS.';

  @override
  String get privacyRightsTitle =>
      '6. Vos droits (accès, correction et effacement)';

  @override
  String privacyRightsBody(String supportEmail) {
    return 'Selon le RGPD et la LPRPDE, vous avez le droit de :\n• Accès : demander une copie des données personnelles que nous détenons sur vous.\n• Rectification : mettre à jour ou corriger vos informations de profil dans Paramètres.\n• Effacement (droit à l’oubli) : demander la suppression complète de votre compte et de tous les comptes à rebours et notifications associés à tout moment en contactant $supportEmail.';
  }

  @override
  String get termsAcceptanceTitle => '1. Acceptation des conditions';

  @override
  String get termsAcceptanceBody =>
      'En accédant ou en utilisant Date Dawn, vous acceptez d’être lié par les présentes Conditions d’utilisation. Si vous n’acceptez pas ces conditions, veuillez ne pas utiliser l’application.';

  @override
  String get termsUseTitle => '2. Utilisation du service';

  @override
  String get termsUseBody =>
      'Date Dawn est fourni pour le suivi personnel et non commercial des comptes à rebours et des moments partagés. Vous acceptez de ne pas utiliser le service de manière abusive, de ne pas téléverser de contenu malveillant, de ne pas harceler d’autres utilisateurs via des cercles partagés ou des invitations, ni d’essayer de contourner les contrôles de sécurité.';

  @override
  String get termsOwnershipTitle => '3. Contenu utilisateur et propriété';

  @override
  String get termsOwnershipBody =>
      'Vous gardez tous les droits de propriété sur les événements de compte à rebours, les titres et le contenu que vous créez. Vous accordez à Date Dawn une licence limitée uniquement pour stocker et synchroniser votre contenu sur vos appareils authentifiés et les membres du cercle partagé.';

  @override
  String get termsTerminationTitle => '4. Résiliation et suppression du compte';

  @override
  String get termsTerminationBody =>
      'Vous pouvez arrêter d’utiliser Date Dawn à tout moment et demander la suppression du compte en envoyant un e-mail au support. Nous nous réservons le droit de suspendre ou de supprimer les comptes qui violent ces conditions ou abusent de l’infrastructure de la plateforme.';

  @override
  String get termsLiabilityTitle => '5. Limitation de responsabilité';

  @override
  String get termsLiabilityBody =>
      'Date Dawn est fourni « tel quel » sans aucune garantie de quelque nature que ce soit. Nous ne serons pas responsables des dommages indirects, accessoires ou consécutifs découlant de votre utilisation de l’application.';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get termsOfServiceTitle => 'Conditions d’utilisation';

  @override
  String get supportHeading => 'Nous lisons chaque message';

  @override
  String supportIntro(String responseTime) {
    return 'Date Dawn est une petite application indépendante. L’e-mail est le moyen le plus rapide d’atteindre la personne qui la développe — il n’y a pas de service d’assistance entre les deux. Nous répondons généralement dans $responseTime.';
  }

  @override
  String get supportResponseTime => 'dans les 2 jours ouvrables';

  @override
  String get supportCommonQuestions => 'Questions fréquentes';

  @override
  String get supportFaqGoogleQuestion =>
      'Je me suis connecté avec Google et mes comptes à rebours ont disparu.';

  @override
  String get supportFaqGoogleAnswer =>
      'Utilisez la même méthode que celle que vous avez utilisée pour créer votre compte. Google et le mot de passe/e-mail ne sont pas liés automatiquement. Si vous devez changer de méthode ou pensez avoir des données dans deux comptes, contactez-nous avant de créer un autre compte.';

  @override
  String get supportFaqSharingQuestion =>
      'Quelqu’un avec qui j’ai partagé ne voit pas le compte à rebours.';

  @override
  String get supportFaqSharingAnswer =>
      'Partager un compte à rebours avec un cercle envoie une invitation — cela ne rajoute pas les personnes automatiquement. Ils doivent ouvrir Invitations dans l’application et l’accepter. Un cercle de couple est la seule exception : il se partage instantanément.';

  @override
  String get supportFaqDeclinedQuestion =>
      'J’ai refusé une invitation par erreur.';

  @override
  String get supportFaqDeclinedAnswer =>
      'Demandez à la personne qui vous a invité de vous réinviter — elle peut le faire depuis le compte à rebours en appuyant sur l’icône d’actualisation à côté de votre nom. Rien n’est perdu entre-temps.';

  @override
  String get supportFaqDeleteQuestion =>
      'Comment supprimer mon compte et mes données ?';

  @override
  String get supportFaqDeleteAnswer =>
      'Envoyez-nous un e-mail depuis l’adresse avec laquelle vous vous êtes inscrit et demandez la suppression. Tous les comptes à rebours, invitations et notifications liés au compte sont supprimés, et nous confirmons quand c’est fait.';

  @override
  String get supportFaqBlockQuestion => 'Comment bloquer quelqu’un ?';

  @override
  String get supportFaqBlockAnswer =>
      'Ouvrez un compte à rebours que vous partagez avec lui et appuyez longuement sur son nom dans la liste des personnes (clic secondaire sur un ordinateur). Il est retiré de vos comptes à rebours partagés et ne peut plus vous inviter à nouveau. Pour annuler, allez dans Paramètres → Personnes bloquées.';

  @override
  String get supportFaqAdsQuestion =>
      'Vendez-vous mes données ou affichez-vous des publicités ?';

  @override
  String get supportFaqAdsAnswer =>
      'Non. Il n’y a ni publicités, ni profils analytiques, ni suivi tiers. Ce que vous comptez n’appartient à personne d’autre que vous, donc il est stocké sous votre propre compte pour que personne d’autre ne puisse le lire.';

  @override
  String get supportLegal => 'Juridique';

  @override
  String get supportNotice =>
      'Un remboursement, une question de facturation ou un signalement de bug appartiennent tous à la même adresse. Si l’application se comporte mal, nous dire votre appareil et ce que vous faisiez au moment du problème est la chose la plus utile que vous puissiez inclure.';

  @override
  String get supportEmailLabel => 'Contacter le support par e-mail';

  @override
  String supportEmailCopied(String email) {
    return '$email copié';
  }

  @override
  String get openMail => 'Ouvrir le mail';

  @override
  String get linkCopiedClipboard => 'Lien copié dans votre presse-papiers.';

  @override
  String get verifyEmailTitle => 'Vérifiez votre e-mail';

  @override
  String verifyEmailInstructions(String email) {
    return 'Nous avons envoyé un lien de vérification à $email. Veuillez le vérifier pour continuer.';
  }

  @override
  String get yourEmailAddress => 'votre adresse e-mail';

  @override
  String resetLinkSent(String email) {
    return 'Lien de réinitialisation envoyé à $email. Utilisez le plus récent e-mail.';
  }

  @override
  String get verificationEmailSent => 'E-mail de vérification envoyé.';

  @override
  String get verificationNotComplete =>
      'Pas encore vérifié. Vérifiez votre boîte de réception.';

  @override
  String get verifiedSignInToContinue =>
      'Votre e-mail est vérifié. Connectez-vous pour continuer si nécessaire.';

  @override
  String get checkSpamFolder =>
      'Vous ne trouvez pas l’e-mail ? Veuillez vérifier votre dossier Spam ou Courrier indésirable.';

  @override
  String get confirmEmailVerified => 'J’ai vérifié mon e-mail';

  @override
  String get sendingEmail => 'Envoi?';

  @override
  String get resendEmail => 'Renvoyer l’e-mail';

  @override
  String get waitBeforeResending =>
      'Veuillez attendre 60 secondes avant de demander un autre e-mail.';

  @override
  String get resetCodeMissing =>
      'Ce lien de réinitialisation n’a pas son code de sécurité.';

  @override
  String get passwordUpdatedSignIn =>
      'Mot de passe mis à jour. Connectez-vous à nouveau.';

  @override
  String get resetLinkInvalidTitle =>
      'Ce lien de réinitialisation ne peut pas être utilisé';

  @override
  String get resetLinkInvalidBody =>
      'Le lien a peut-être expiré ou a déjà été utilisé. Revenez à l’écran de connexion et demandez un nouvel e-mail de réinitialisation de mot de passe.';

  @override
  String get backToSignIn => 'Retour à la connexion';

  @override
  String get chooseNewPassword => 'Choisissez un nouveau mot de passe';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get passwordMinLength => 'Utilisez au moins 6 caractères.';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get updatePassword => 'Mettre à jour le mot de passe';

  @override
  String get editCountdownAction => 'Modifier';

  @override
  String get duplicateYearLater => 'Dupliquer dans un an';

  @override
  String get countdownDuplicated =>
      'Dupliqué — ouvrez-le pour ajuster la date.';

  @override
  String get onlyOwnerCanDelete =>
      'Seul le propriétaire peut supprimer ce compte à rebours.';

  @override
  String get countdownDeleteFailed => 'Impossible de supprimer. Réessayez.';

  @override
  String get countdownDeleteWarning =>
      'Le compte à rebours ne peut pas être annulé.';

  @override
  String blockPersonQuestion(String personName) {
    return 'Bloquer $personName ?';
  }

  @override
  String get blockExplanation =>
      'Vous cesserez de vous voir. Ils seront retirés de tous les comptes à rebours que vous partagez, les invitations entre vous seront annulées et ils ne pourront plus vous inviter à nouveau. Ils ne sont pas avertis.';

  @override
  String get undoBlockInSettings =>
      'Vous pouvez annuler cela à tout moment dans Paramètres → Personnes bloquées.';

  @override
  String get blocking => 'Blocage?';

  @override
  String get blockAction => 'Bloquer';

  @override
  String personBlocked(String personName) {
    return '$personName est bloqué.';
  }

  @override
  String get undo => 'Annuler';

  @override
  String personUnblocked(String personName) {
    return '$personName a été débloqué.';
  }

  @override
  String get blockAccessNotRestored =>
      'L’accès au compte à rebours n’a pas été restauré.';

  @override
  String get undoBlockFailed =>
      'Impossible d’annuler le blocage. Veuillez réessayer.';

  @override
  String get blockSaveFailed =>
      'Votre blocage n’a pas pu être enregistré. Connectez-vous à nouveau puis réessayez.';

  @override
  String get noConnectionRetry =>
      'Aucune connexion. Vérifiez votre réseau et réessayez.';

  @override
  String blockPersonFailed(String personName) {
    return 'Impossible de bloquer $personName. Veuillez réessayer.';
  }

  @override
  String get blockedPeopleTitle => 'Personnes bloquées';

  @override
  String get nobodyBlocked => 'Personne n’est bloqué';

  @override
  String get howToBlockPerson =>
      'Pour bloquer quelqu’un, ouvrez un compte à rebours que vous partagez avec lui, ouvrez le menu ⋮ dans sa ligne, puis appuyez sur Bloquer.';

  @override
  String get blockedPeopleDescription =>
      'Ces personnes ne peuvent pas vous inviter et vous ne partagez aucun compte à rebours avec elles. Elles ne sont pas informées qu’elles sont bloquées.';

  @override
  String get unblock => 'Débloquer';

  @override
  String get blockedListLoadFailed =>
      'Impossible de charger votre liste de blocage';

  @override
  String get blockedListPermissionError =>
      'Votre compte n’est pas autorisé à lire cette liste. Si cela continue, mettez à jour l’application.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountWarning =>
      'Cette action est irréversible. Tous vos événements, cercles et données seront supprimés définitivement.';

  @override
  String get deleteAccountConfirmationPrompt =>
      'Saisissez exactement l’adresse e-mail de votre compte pour continuer.';

  @override
  String get deleteAccountConfirmationLabel => 'E-mail du compte';

  @override
  String get permanentlyDeleteAccount => 'Supprimer définitivement le compte';

  @override
  String get deleteAccountProfileConsequence =>
      'Votre profil sera supprimé définitivement.';

  @override
  String get deleteAccountAccessConsequence =>
      'Vous perdrez l’accès à tous vos événements et cercles.';

  @override
  String get deleteAccountIrreversibleConsequence =>
      'Cette action est irréversible.';

  @override
  String get deleteAccountPermanentlyAction =>
      'Supprimer définitivement le compte';

  @override
  String get accountDeleted => 'Compte supprimé avec succès';

  @override
  String get serverTimedOutTryAgain =>
      'Le délai d’attente du serveur a expiré. Veuillez réessayer plus tard.';

  @override
  String get accountDeletionFailed =>
      'La suppression du compte n’a pas abouti. Veuillez réessayer.';

  @override
  String get accountDeletedCleanupWarning =>
      'Le compte a été supprimé, mais certains réglages locaux n’ont pas pu être effacés. Redémarrez l’application avant d’utiliser un autre compte.';
}
