// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Date Dawn';

  @override
  String get language => 'Idioma';

  @override
  String get followSystemLanguage => 'Usar el idioma del sistema';

  @override
  String get languageChanged => 'Idioma cambiado.';

  @override
  String get languageSaveFailed =>
      'No se pudo guardar la preferencia de idioma.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get settings => 'Ajustes';

  @override
  String get dateDawnUser => 'Usuario de Date Dawn';

  @override
  String get guestAccount => 'Cuenta de invitado';

  @override
  String get notSignedIn => 'No has iniciado sesión';

  @override
  String get syncAndShareDescription =>
      'Inicia sesión para sincronizar tus cuentas atrás en todos tus dispositivos y compartirlas.';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get appearance => 'APARIENCIA';

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get lightTheme => 'Claro';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get time => 'HORA';

  @override
  String get timeFormatDescription =>
      'Elige cómo se muestran las horas. Las cuentas atrás siguen siendo momentos exactos; solo cambia su formato.';

  @override
  String get twelveHourTime => '12 horas (a. m./p. m.)';

  @override
  String get twentyFourHourTime => '24 horas';

  @override
  String get about => 'ACERCA DE';

  @override
  String get version => 'Versión';

  @override
  String get sync => 'Sincronización';

  @override
  String get safety => 'SEGURIDAD';

  @override
  String get blockedPeople => 'Personas bloqueadas';

  @override
  String get legal => 'LEGAL';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfService => 'Términos del servicio';

  @override
  String get helpAndSupport => 'Ayuda y soporte';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signedOut => 'Sesión cerrada.';

  @override
  String countdownsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# cuentas atrás',
      one: '# cuenta atrás',
    );
    return '$_temp0';
  }

  @override
  String get welcomeToDateDawn => 'Te damos la bienvenida a Date Dawn';

  @override
  String get createYourAccount => 'Crea tu cuenta';

  @override
  String get countdownsSyncDescription =>
      'Tus cuentas atrás se sincronizan en todos los dispositivos donde inicies sesión.';

  @override
  String get welcomeDescription =>
      'Cuenta atrás para los momentos importantes, en móvil, tableta y web.';

  @override
  String get name => 'Nombre';

  @override
  String get nameHint => 'Alex Rivera';

  @override
  String get nameRequired => 'Dinos cómo te llamamos.';

  @override
  String get email => 'Correo electrónico';

  @override
  String get emailHint => 'tu@ejemplo.com';

  @override
  String get emailRequired => 'Introduce tu correo electrónico.';

  @override
  String get emailInvalid => 'Ese correo electrónico no parece válido.';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordRequired => 'Introduce tu contraseña.';

  @override
  String get passwordTooShort => 'Usa al menos 6 caracteres.';

  @override
  String get forgotPassword => '¿Olvidaste la contraseña?';

  @override
  String get forgotPasswordPrompt =>
      'Primero introduce tu correo y luego pulsa «¿Olvidaste la contraseña?».';

  @override
  String get signInConnectionError =>
      'No se pudo acceder al servicio de inicio de sesión. Comprueba tu conexión.';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get or => 'O';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? ';

  @override
  String get newHere => '¿Eres nuevo? ';

  @override
  String get createOne => 'Crea una';

  @override
  String get troubleSigningIn =>
      '¿Problemas para iniciar sesión? Obtener ayuda';

  @override
  String get accountCreated => 'Cuenta creada.';

  @override
  String get welcomeBack => 'Te damos la bienvenida de nuevo.';

  @override
  String get signInFailed => 'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get signedInWithGoogle => 'Sesión iniciada con Google.';

  @override
  String get home => 'Inicio';

  @override
  String get invitations => 'Invitaciones';

  @override
  String get circles => 'Círculos';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get support => 'Soporte';
}
