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
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageUkrainian => 'Українська';

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
}
