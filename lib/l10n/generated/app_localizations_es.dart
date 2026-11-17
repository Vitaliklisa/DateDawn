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
  String get languageUkrainian => 'Українська';

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
      other: '$count cuentas atrás',
      one: '$count cuenta atrás',
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

  @override
  String get homeEmptyTitle => 'Ponle fecha a un d?a.';

  @override
  String get homeEmptyDescription =>
      'Elige un momento futuro: una boda, un lanzamiento, un viaje de vuelta a casa. Date Dawn cuenta los a?os, meses, d?as y horas que faltan y lo celebra cuando llega.';

  @override
  String get homeLoadError =>
      'No se pudieron cargar tus cuentas atr?s. Desliza hacia abajo para volver a intentarlo.';

  @override
  String get getStarted => 'Empezar';

  @override
  String get homeSyncTitle => 'Tenlas siempre contigo';

  @override
  String get homeSyncDescription =>
      'Inicia sesi?n para sincronizar tus cuentas atr?s en el tel?fono, la tableta y la web, y compartirlas con quienes tambi?n esperan ese momento.';

  @override
  String get otherCountdowns => 'OTRAS CUENTAS ATR?S';

  @override
  String get arrived => 'LLEG?';

  @override
  String get countingDown => 'EN CUENTA ATR?S';

  @override
  String get options => 'Opciones';

  @override
  String get open => 'Abrir';

  @override
  String get openCountdown => 'Abrir cuenta atr?s';

  @override
  String get newCountdown => 'Nueva cuenta atr?s';

  @override
  String get editCountdown => 'Editar cuenta atr?s';

  @override
  String get countdownTitleLabel => 'T?tulo';

  @override
  String get countdownDescriptionLabel => 'Descripci?n';

  @override
  String get whenLabel => 'Cu?ndo';

  @override
  String get titleExampleHint => 'Boda, lanzamiento, reencuentro';

  @override
  String get descriptionExampleHint => 'Una breve nota sobre ese d?a';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get timeLabel => 'Hora';

  @override
  String get presetWeek => '+1 semana';

  @override
  String get presetMonth => '+1 mes';

  @override
  String get presetYear => '+1 a?o';

  @override
  String get presetFiveYears => '+5 a?os';

  @override
  String get createCountdown => 'Crear cuenta atr?s';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get deleteCountdown => 'Eliminar cuenta atr?s';

  @override
  String get countdownActions => 'Acciones de la cuenta atr?s';

  @override
  String get deleteCountdownQuestion => '?Eliminar esta cuenta atr?s?';

  @override
  String get countdownCannotUndo => 'No se puede deshacer esta acci?n.';

  @override
  String get giveCountdownTitle => 'Ponle un t?tulo a esta cuenta atr?s.';

  @override
  String get pickFutureMoment => 'Elige un momento que a?n est? por llegar.';

  @override
  String get signInToSaveCountdown =>
      'Inicia sesi?n para guardar cuentas atr?s.';

  @override
  String get countdownCreated => 'Cuenta atr?s creada.';

  @override
  String get changesSaved => 'Cambios guardados.';

  @override
  String get countdownDeleted => 'Cuenta atr?s eliminada.';

  @override
  String get partnerLabel => 'tu pareja';

  @override
  String partnerNotAdded(String partnerName) {
    return 'Cuenta atr?s creada, pero no se a?adi? a $partnerName. Inv?tale manualmente desde la cuenta atr?s.';
  }

  @override
  String partnerAdded(String partnerName) {
    return 'Cuenta atr?s creada. Se a?adi? a $partnerName.';
  }

  @override
  String get noPartnerAdded =>
      'Cuenta atr?s creada, pero no se a?adi? a tu pareja. Env?a la invitaci?n manualmente.';

  @override
  String get chooseFutureDateHint =>
      'Elige una fecha futura para ver la cuenta atr?s.';

  @override
  String countingDownRemaining(String remaining) {
    return 'Cuenta atr?s: $remaining';
  }

  @override
  String get cannotEditCountdown =>
      'Puedes ver esta cuenta atr?s, pero no modificarla.';

  @override
  String get shareWith => 'Compartir con';

  @override
  String get circleShareDescription =>
      'Las cuentas atr?s de un c?rculo de pareja se comparten al instante. En los dem?s c?rculos, se env?a una invitaci?n.';

  @override
  String get collaborators => 'Colaboradores';

  @override
  String get collaboratorsCanFollow =>
      'Quienes invites podr?n seguir esta cuenta atr?s desde sus propios dispositivos.';

  @override
  String get peopleFollowing => 'Personas que siguen esta cuenta atr?s.';

  @override
  String get noCollaboratorsYet => 'Todav?a no hay nadie m?s.';

  @override
  String get nameEmailHint => 'nombre@example.com';

  @override
  String get recentContactsCouldNotLoad =>
      'No se pudieron cargar los contactos recientes. Comprueba tu conexi?n o las reglas de Firestore.';

  @override
  String invitationSentTo(String email) {
    return 'Invitaci?n enviada a $email.';
  }

  @override
  String sharedWithCircle(String circleName) {
    return 'Compartido con $circleName';
  }

  @override
  String get inviteAgain => 'Volver a invitar';

  @override
  String get removePersonQuestion => '?Eliminar a esta persona?';

  @override
  String collaboratorLosesAccess(String email) {
    return '$email perder? el acceso a esta cuenta atr?s y dejar? de verla en su lista.';
  }

  @override
  String get changeRole => 'Cambiar rol';

  @override
  String changeRoleFor(String personName) {
    return 'Cambiar el rol de $personName';
  }

  @override
  String roleChangeDescription(String role) {
    return 'Esto cambiar? lo que puede hacer en esta cuenta atr?s a partir de ahora. Actualmente tiene acceso de tipo $role.';
  }

  @override
  String rolesNotAssignable(String roles, String topRole) {
    return 'No puedes asignar $roles ? tienes el rol $topRole.';
  }

  @override
  String get circlesDescriptionTitle =>
      'Grupos con los que compartes cuentas atr?s';

  @override
  String get circlesDescription =>
      'Invita a alguien a un c?rculo una sola vez y luego comparte cualquier cuenta atr?s con todo el grupo con un solo toque. Las cuentas atr?s de un c?rculo de pareja se comparten autom?ticamente: lo que cree uno, lo ver? el otro.';

  @override
  String get circlesLoadError =>
      'No se pudieron cargar tus c?rculos. Desliza hacia abajo para volver a intentarlo.';

  @override
  String get noCircles => 'Todav?a no hay c?rculos';

  @override
  String get noCirclesDescription =>
      'Crea uno para las personas con quienes compartes la espera: tu pareja, tu familia o las amistades con quienes viajas cada a?o.';

  @override
  String get newCircle => 'Nuevo c?rculo';

  @override
  String get sharesAutomatically => 'Se comparte autom?ticamente';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String get inviteSomeone => 'Invitar a alguien';

  @override
  String get you => 'T?';

  @override
  String get leaveCircle => 'Salir del c?rculo';

  @override
  String get deleteCircle => 'Eliminar c?rculo';

  @override
  String get removeFromCircle => 'Eliminar del c?rculo';

  @override
  String removeMemberQuestion(String personName) {
    return '?Eliminar a $personName?';
  }

  @override
  String get removeMemberExplanation =>
      'Dejar? de ver las cuentas atr?s compartidas con este c?rculo. No se eliminar? nada de lo que haya creado.';

  @override
  String leaveCircleQuestion(String circleName) {
    return '?Salir de ?$circleName??';
  }

  @override
  String get leaveCircleExplanation =>
      'Las cuentas atr?s compartidas con este c?rculo dejar?n de aparecerte. Podr?n volver a invitarte.';

  @override
  String deleteCircleQuestion(String circleName) {
    return '?Eliminar ?$circleName??';
  }

  @override
  String get deleteCircleExplanation =>
      'El grupo desaparecer?. Las cuentas atr?s compartidas con ?l se conservar?n y seguir?n siendo tuyas, pero ya no se compartir?n con estas personas.';

  @override
  String get circleNameHint => 'Familia, Tokio 2027, Nosotros';

  @override
  String get coupleCircleTitle => 'Un c?rculo para nosotros, como pareja';

  @override
  String get coupleCircleDescription =>
      'Las cuentas atr?s se comparten autom?ticamente con tu pareja, sin que tenga que aceptar una invitaci?n.';

  @override
  String get circleCreated => 'C?rculo creado.';

  @override
  String get coupleCircleCreated => 'Creado. Ahora invita a tu pareja.';

  @override
  String get inviteYourPartner => 'Invitar a tu pareja';

  @override
  String inviteToCircle(String circleName) {
    return 'Invitar a ?$circleName?';
  }

  @override
  String get coupleInviteExplanation =>
      'Si ya tiene una cuenta, se a?adir? autom?ticamente. De lo contrario, se a?adir? cuando inicie sesi?n. Las futuras cuentas atr?s compartidas con este c?rculo aparecer?n autom?ticamente.';

  @override
  String get circleInviteExplanation =>
      'Recibir? una invitaci?n que podr? aceptar o rechazar. Cuando se una, podr?s compartir cuentas atr?s con este c?rculo con un solo toque.';

  @override
  String get inviteEmailHint => 'persona@example.com';

  @override
  String get sendInvitation => 'Enviar invitaci?n';

  @override
  String get partnerAddedAutomatically =>
      'Tu pareja se a?adir? autom?ticamente.';

  @override
  String get signInToUseCircles => 'Inicia sesi?n para usar los c?rculos';

  @override
  String get circlesRequireAccounts =>
      'Como se invita a las personas a los c?rculos por correo electr?nico, necesitan tener una cuenta para recibir una invitaci?n.';

  @override
  String get waitingOnYou => 'Esperando tu respuesta';

  @override
  String get invitationsEmptyDescription =>
      'No se compartir? nada contigo hasta que aceptes. Si rechazas una invitaci?n, se avisar? a quien te la envi? para que no se quede esperando sin saber qu? pas?.';

  @override
  String get signInToSeeInvitations =>
      'Inicia sesi?n para ver las invitaciones';

  @override
  String get invitationsEmailAccount =>
      'Las invitaciones se env?an a tu correo electr?nico, as? que inicia sesi?n con la direcci?n a la que te invitaron.';

  @override
  String get invitationsCouldNotLoad =>
      'No se pudieron cargar las invitaciones. Comprueba tu conexi?n o las reglas de Firestore.';

  @override
  String get nothingWaiting => 'No hay nada pendiente';

  @override
  String get invitationInboxEmpty =>
      'Las invitaciones que te env?en aparecer?n aqu?. Las invitaciones a cuentas atr?s y a c?rculos est?ndar requieren una respuesta; a los c?rculos de pareja te unes autom?ticamente.';

  @override
  String get retryAddingYou => 'Volver a intentar a?adirme';

  @override
  String get decline => 'Rechazar';

  @override
  String joinInviteQuestion(String eventTitle) {
    return '?Unirte a ?$eventTitle??';
  }

  @override
  String get joinInviteExplanation =>
      'Aparecer? en tu lista y podr?s ver la cuenta atr?s en este dispositivo.';

  @override
  String get join => 'Unirse';

  @override
  String alreadyMemberOf(String name) {
    return 'Ya formas parte de ?$name?.';
  }

  @override
  String youJoined(String name) {
    return 'Te uniste a ?$name?.';
  }

  @override
  String youWereAddedTo(String name) {
    return 'Te a?adieron a ?$name?.';
  }

  @override
  String get invitationDeclined => 'Invitaci?n rechazada.';

  @override
  String get countdownInvitation => 'Invitaci?n a una cuenta atr?s';

  @override
  String get aCountdown => 'Una cuenta atr?s';

  @override
  String invitedToFollowCountdown(String role) {
    return 'Te invitaron a seguir esta cuenta atr?s. Si aceptas, se a?adir? a tu lista con el rol $role.';
  }

  @override
  String get accept => 'Aceptar';

  @override
  String get partnerInvitation => 'Invitaci?n de pareja';

  @override
  String get circleInvitation => 'Invitaci?n a un c?rculo';

  @override
  String partnerCircleAddTitle(String personName) {
    return 'Te est?n a?adiendo al c?rculo de $personName';
  }

  @override
  String get partnerCircleAddExplanation =>
      'Te a?adir?n autom?ticamente. Las cuentas atr?s compartidas con este c?rculo aparecer?n en tu lista.';

  @override
  String circleJoinExplanation(String circleName) {
    return 'Al unirte a ?$circleName?, las cuentas atr?s que compartan con este c?rculo aparecer?n en tu lista.';
  }

  @override
  String get becomePartners => 'Convertirse en pareja';

  @override
  String get joinCircle => 'Unirse al c?rculo';

  @override
  String get automaticJoinFailed =>
      'No se pudo completar la incorporaci?n autom?tica.';

  @override
  String get notNow => 'Ahora no';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get markAllRead => 'Marcar todo como le?do';

  @override
  String get markedAllRead => 'Todo marcado como le?do.';

  @override
  String get moreOptions => 'M?s opciones';

  @override
  String get noReadMessagesToDelete => 'No hay mensajes le?dos para eliminar.';

  @override
  String get deleteReadMessages => 'Eliminar mensajes le?dos';

  @override
  String get deletedReadMessages => 'Mensajes le?dos eliminados.';

  @override
  String get notificationsSignInFirst => 'Inicia sesi?n primero';

  @override
  String get notificationsAccountOnly =>
      'Las notificaciones est?n vinculadas a tu cuenta.';

  @override
  String get couldNotLoad => 'No se pudo cargar';

  @override
  String get checkConnectionRetry =>
      'Comprueba tu conexi?n e int?ntalo de nuevo.';

  @override
  String get nothingYet => 'Todav?a no hay nada';

  @override
  String get notificationsEmptyDescription =>
      'Cuando ocurra algo con tus cuentas atr?s o invitaciones, aparecer? aqu?.';

  @override
  String get liveNotificationsCouldNotLoad =>
      'No se pudieron cargar las notificaciones en tiempo real.';

  @override
  String get inbox => 'BANDEJA DE ENTRADA';

  @override
  String get invitationResponses => 'RESPUESTAS A INVITACIONES';

  @override
  String get invitationResponsesCouldNotLoad =>
      'No se pudieron cargar las respuestas a las invitaciones.';

  @override
  String get countdownUnavailable => 'Esta cuenta atr?s ya no est? disponible.';

  @override
  String get viewDetails => 'Ver detalles';

  @override
  String get sharedWith => 'COMPARTIDO CON';

  @override
  String get notes => 'NOTAS';

  @override
  String get notesEmpty =>
      'Todav?a no hay nada. Deja un comentario para quienes comparten la cuenta atr?s contigo.';

  @override
  String get addNote => 'A?adir una nota';

  @override
  String get years => 'A?os';

  @override
  String get months => 'Meses';

  @override
  String get days => 'D?as';

  @override
  String get hours => 'Horas';

  @override
  String remainingMinutes(int count) {
    return '$count min';
  }

  @override
  String remainingSeconds(int count) {
    return 'Quedan $count s';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get keep => 'Conservar';

  @override
  String get stay => 'Quedarse';

  @override
  String get leave => 'Salir';

  @override
  String get remove => 'Eliminar';

  @override
  String get delete => 'Eliminar';

  @override
  String get create => 'Crear';

  @override
  String get tryAgain => 'Volver a intentarlo';

  @override
  String get share => 'Compartir';

  @override
  String get passed => 'Pas?';

  @override
  String get upcoming => 'Pr?ximo';

  @override
  String get accepted => 'Aceptada';

  @override
  String get declined => 'Rechazada';

  @override
  String get removed => 'Eliminado';

  @override
  String get reopened => 'Reabierta';

  @override
  String get waiting => 'Pendiente';

  @override
  String get itHasArrived => 'Ya lleg?.';

  @override
  String remainingToGo(String remaining) {
    return 'Faltan $remaining';
  }

  @override
  String get momentHasPassed => 'El momento ya pas?';

  @override
  String remainingAnd(String first, String last) {
    return '$first y $last';
  }

  @override
  String get dayHasCome => 'HA LLEGADO EL D?A';

  @override
  String eventArrivedWithDescription(String title, String description) {
    return '$title ya lleg?: $description';
  }

  @override
  String eventArrivedTitleOnly(String title) {
    return '$title ya lleg?: disfruta cada minuto.';
  }

  @override
  String personRemovedFromCircle(String personName, String circleName) {
    return 'Se elimin? a $personName de ?$circleName?.';
  }

  @override
  String youLeftCircle(String circleName) {
    return 'Saliste de ?$circleName?.';
  }

  @override
  String circleDeleted(String circleName) {
    return 'Se elimin? ?$circleName?.';
  }

  @override
  String get someone => 'Alguien';

  @override
  String invitedYouToCircle(String personName, String circleName) {
    return '$personName te invit? a ?$circleName?';
  }

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleEditor => 'Editor';

  @override
  String get roleViewer => 'Lector';

  @override
  String get roleAdminDescription =>
      'Puede administrar la cuenta atr?s y a sus participantes.';

  @override
  String get roleEditorDescription =>
      'Puede editar la cuenta atr?s e invitar a otras personas.';

  @override
  String get roleViewerDescription =>
      'Puede ver la cuenta atr?s y dejar notas.';

  @override
  String remainingYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count a?os',
      one: '$count a?o',
    );
    return '$_temp0';
  }

  @override
  String remainingMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '$count mes',
    );
    return '$_temp0';
  }

  @override
  String remainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count d?as',
      one: '$count d?a',
    );
    return '$_temp0';
  }

  @override
  String remainingHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '$count hora',
    );
    return '$_temp0';
  }

  @override
  String remainingMinuteUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '$count minuto',
    );
    return '$_temp0';
  }

  @override
  String remainingSecondUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segundos',
      one: '$count segundo',
    );
    return '$_temp0';
  }

  @override
  String get moreActions => 'M?s acciones';

  @override
  String get block => 'Bloquear';

  @override
  String roleChanged(String personName, String role) {
    return '$personName ahora tiene el rol $role.';
  }

  @override
  String personRemoved(String personName) {
    return 'Se elimin? a $personName.';
  }

  @override
  String get signInToSaveIt => 'Inicia sesi?n para guardarlo';

  @override
  String get countdownsFollowYou =>
      'Tus cuentas atr?s se guardan en tu cuenta, as? que est?n disponibles en todos tus dispositivos y puedes compartirlas con otras personas.';

  @override
  String get savePermissionError =>
      'Firestore rechaz? el guardado. Si sigue ocurriendo, las reglas de seguridad implementadas son anteriores a la aplicaci?n ? ejecuta `firebase deploy --only firestore:rules`.';

  @override
  String get saveNetworkError =>
      'No se pudo conectar con Firestore. Comprueba tu conexi?n e int?ntalo de nuevo.';

  @override
  String get saveFailed => 'No se pudo guardar. Int?ntalo de nuevo.';

  @override
  String get momentPassed => 'El momento ya pas?';

  @override
  String get and => 'y';

  @override
  String get back => 'Atr?s';

  @override
  String get policyLastUpdated =>
      '?ltima actualizaci?n: febrero de 2026 ? Cumple con el RGPD de la UE y la PIPEDA de Canad?';

  @override
  String get privacyIntroTitle =>
      '1. Introducci?n y responsable del tratamiento';

  @override
  String privacyIntroBody(String supportEmail) {
    return 'Date Dawn (?nosotros?, ?nuestro? o ?nos?) respeta tu privacidad y se compromete a proteger tus datos personales. Esta Pol?tica de privacidad explica c?mo recopilamos, usamos y protegemos tu informaci?n cuando utilizas nuestras aplicaciones m?viles y web, en pleno cumplimiento del Reglamento General de Protecci?n de Datos (RGPD) de la Uni?n Europea y de la Ley de Protecci?n de la Informaci?n Personal y los Documentos Electr?nicos (PIPEDA) de Canad?.\n\nContacto del responsable del tratamiento: $supportEmail';
  }

  @override
  String get privacyCollectTitle => '2. Informaci?n que recopilamos';

  @override
  String get privacyCollectBody =>
      '? Datos de la cuenta: direcci?n de correo electr?nico y nombre visible que proporcionas durante la autenticaci?n (Firebase Auth).\n? Contenido del usuario: cuentas atr?s, t?tulos, fechas, descripciones y pertenencia a c?rculos que creas o compartes expresamente.\n? Datos del dispositivo y las notificaciones: tokens de notificaciones push para enviarte recordatorios de cuentas atr?s y avisos de invitaciones.\n\nNO recopilamos el historial de navegaci?n, identificadores publicitarios ni datos de ubicaci?n, ni vendemos informaci?n personal a terceros.';

  @override
  String get privacyBasisTitle =>
      '3. Base jur?dica del tratamiento (RGPD de la UE)';

  @override
  String get privacyBasisBody =>
      'Tratamos tus datos conforme a las siguientes bases jur?dicas:\n? Necesidad contractual: prestar las funciones de sincronizaci?n de cuentas atr?s, compartir c?rculos y enviar invitaciones.\n? Consentimiento: cuando autorizas las notificaciones push o aceptas participar en c?rculos compartidos.\n? Intereses leg?timos: garantizar la seguridad y fiabilidad de la aplicaci?n y prevenir abusos.';

  @override
  String get privacySharingTitle => '4. Compartir y bloquear';

  @override
  String get privacySharingBody =>
      'Date Dawn permite que las personas interact?en entre s?: puedes invitar a alguien a una cuenta atr?s y ambos pueden dejar notas en una que compartan. Ese contenido solo est? visible para las personas incluidas en esa cuenta atr?s; nunca es p?blico ni se muestra a nadie m?s.\n\nPuedes bloquear a otra persona en cualquier momento: abre una cuenta atr?s que compartas con ella y mant?n pulsado su nombre (o haz clic secundario en el ordenador). Al bloquearla, ambos dejar?n de aparecer en las cuentas atr?s del otro, se cancelar?n las invitaciones entre ustedes y esa persona ya no podr? volver a invitarte. No se le avisar?. La lista de personas que has bloqueado es privada y puedes desbloquear a cualquiera desde Ajustes ? Personas bloqueadas.';

  @override
  String get privacyStorageTitle =>
      '5. Almacenamiento y seguridad de los datos';

  @override
  String get privacyStorageBody =>
      'Tus datos se almacenan y procesan de forma segura mediante la infraestructura de Firebase (Google Cloud Platform), que cumple altos est?ndares de seguridad del sector. Los datos que se transmiten entre tu dispositivo y nuestros servidores se cifran en tr?nsito mediante TLS.';

  @override
  String get privacyRightsTitle =>
      '6. Tus derechos (acceso, rectificaci?n y supresi?n)';

  @override
  String privacyRightsBody(String supportEmail) {
    return 'En virtud del RGPD y la PIPEDA, tienes derecho a:\n? Acceso: solicitar una copia de los datos personales que tenemos sobre ti.\n? Rectificaci?n: actualizar o corregir la informaci?n de tu perfil en Ajustes.\n? Supresi?n (derecho al olvido): solicitar en cualquier momento la eliminaci?n completa de tu cuenta y de todas las cuentas atr?s y notificaciones asociadas escribiendo a $supportEmail.';
  }

  @override
  String get termsAcceptanceTitle => '1. Aceptaci?n de los t?rminos';

  @override
  String get termsAcceptanceBody =>
      'Al acceder a Date Dawn o utilizarlo, aceptas someterte a estos T?rminos del servicio. Si no est?s de acuerdo con estos t?rminos, no utilices la aplicaci?n.';

  @override
  String get termsUseTitle => '2. Uso del servicio';

  @override
  String get termsUseBody =>
      'Date Dawn se ofrece para el seguimiento personal y no comercial de cuentas atr?s y momentos compartidos. Aceptas no hacer un uso indebido del servicio, subir contenido malicioso, acosar a otras personas mediante c?rculos compartidos o invitaciones, ni intentar eludir los controles de seguridad.';

  @override
  String get termsOwnershipTitle => '3. Contenido del usuario y titularidad';

  @override
  String get termsOwnershipBody =>
      'Conservas todos los derechos de titularidad sobre los eventos de cuenta atr?s, t?tulos y contenido que crees. Concedes a Date Dawn una licencia limitada, ?nicamente para almacenar y sincronizar tu contenido en tus dispositivos autenticados y con los miembros de los c?rculos con quienes lo compartas.';

  @override
  String get termsTerminationTitle =>
      '4. Cancelaci?n y eliminaci?n de la cuenta';

  @override
  String get termsTerminationBody =>
      'Puedes dejar de usar Date Dawn en cualquier momento y solicitar que se elimine tu cuenta escribiendo al soporte. Nos reservamos el derecho de suspender o cancelar las cuentas que infrinjan estos t?rminos o hagan un uso abusivo de la infraestructura de la plataforma.';

  @override
  String get termsLiabilityTitle => '5. Limitaci?n de responsabilidad';

  @override
  String get termsLiabilityBody =>
      'Date Dawn se proporciona ?tal cual?, sin garant?as de ning?n tipo. No seremos responsables de ning?n da?o indirecto, incidental o consecuente derivado del uso de la aplicaci?n.';

  @override
  String get privacyPolicyTitle => 'Pol?tica de privacidad';

  @override
  String get termsOfServiceTitle => 'T?rminos del servicio';

  @override
  String get supportHeading => 'Leemos todos los mensajes';

  @override
  String supportIntro(String responseTime) {
    return 'Date Dawn es una aplicaci?n independiente y peque?a. El correo electr?nico es la forma m?s r?pida de contactar con quien la desarrolla: no hay un servicio de atenci?n intermediario. Normalmente respondemos $responseTime.';
  }

  @override
  String get supportResponseTime => 'en un plazo de 2 d?as laborables';

  @override
  String get supportCommonQuestions => 'Preguntas frecuentes';

  @override
  String get supportFaqGoogleQuestion =>
      'Inici? sesi?n con Google y no aparecen mis cuentas atr?s.';

  @override
  String get supportFaqGoogleAnswer =>
      'Usa el mismo m?todo que utilizaste al crear tu cuenta. Google y el correo electr?nico con contrase?a no se vinculan autom?ticamente. Si necesitas cambiar de m?todo o crees que tienes datos en dos cuentas, ponte en contacto con nosotros antes de crear otra cuenta.';

  @override
  String get supportFaqSharingQuestion =>
      'La persona con quien compart? la cuenta atr?s no puede verla.';

  @override
  String get supportFaqSharingAnswer =>
      'Compartir una cuenta atr?s con un c?rculo env?a una invitaci?n; no a?ade personas autom?ticamente. La otra persona debe abrir Invitaciones en la aplicaci?n y aceptarla. Los c?rculos de pareja son la excepci?n: se comparten al instante.';

  @override
  String get supportFaqDeclinedQuestion => 'Rechac? una invitaci?n por error.';

  @override
  String get supportFaqDeclinedAnswer =>
      'P?dele a quien te invit? que vuelva a invitarte: puede hacerlo desde la cuenta atr?s tocando el icono de actualizaci?n junto a tu nombre. Mientras tanto, no se pierde nada.';

  @override
  String get supportFaqDeleteQuestion => '?C?mo elimino mi cuenta y mis datos?';

  @override
  String get supportFaqDeleteAnswer =>
      'Escr?benos desde la direcci?n con la que te registraste y solicita la eliminaci?n. Se eliminar?n todas las cuentas atr?s, invitaciones y notificaciones vinculadas a la cuenta, y te confirmaremos cuando se haya completado.';

  @override
  String get supportFaqBlockQuestion => '?C?mo bloqueo a alguien?';

  @override
  String get supportFaqBlockAnswer =>
      'Abre una cuenta atr?s que compartas con esa persona y mant?n pulsado su nombre en la lista de personas (o haz clic secundario en el ordenador). Se eliminar? de las cuentas atr?s que compartan y no podr? volver a invitarte. Para deshacerlo, ve a Ajustes ? Personas bloqueadas.';

  @override
  String get supportFaqAdsQuestion => '?Venden mis datos o muestran anuncios?';

  @override
  String get supportFaqAdsAnswer =>
      'No. No hay anuncios, perfiles anal?ticos ni seguimiento de terceros. Lo que esperas con ilusi?n solo te incumbe a ti, as? que se guarda en tu propia cuenta para que nadie m?s lo lea.';

  @override
  String get supportLegal => 'Informaci?n legal';

  @override
  String get supportNotice =>
      'Las solicitudes de reembolso, las preguntas sobre pagos y los informes de fallos se atienden en la misma direcci?n. Si la aplicaci?n no funciona bien, lo m?s ?til que puedes incluir es el modelo de tu dispositivo y lo que estabas haciendo cuando ocurri?.';

  @override
  String get supportEmailLabel => 'Contactar con soporte';

  @override
  String supportEmailCopied(String email) {
    return 'Se copi? $email';
  }

  @override
  String get openMail => 'Abrir correo';

  @override
  String get linkCopiedClipboard => 'Enlace copiado al portapapeles.';

  @override
  String get verifyEmailTitle => 'Verifica tu correo electr?nico';

  @override
  String verifyEmailInstructions(String email) {
    return 'Enviamos un enlace de verificaci?n a $email. Verifica tu direcci?n para continuar.';
  }

  @override
  String get yourEmailAddress => 'tu direcci?n de correo electr?nico';

  @override
  String resetLinkSent(String email) {
    return 'Enviamos un enlace para restablecer la contrase?a a $email. Abre el correo m?s reciente.';
  }

  @override
  String get verificationEmailSent => 'Correo de verificaci?n enviado.';

  @override
  String get verificationNotComplete =>
      'A?n no se ha verificado. Revisa tu bandeja de entrada.';

  @override
  String get verifiedSignInToContinue =>
      'Tu correo est? verificado. Si es necesario, inicia sesi?n para continuar.';

  @override
  String get checkSpamFolder =>
      '?No encuentras el correo? Revisa la carpeta de correo no deseado o spam.';

  @override
  String get confirmEmailVerified => 'He verificado mi correo electr?nico';

  @override
  String get sendingEmail => 'Enviando?';

  @override
  String get resendEmail => 'Volver a enviar el correo';

  @override
  String get waitBeforeResending =>
      'Espera 60 segundos antes de solicitar otro correo.';

  @override
  String get resetCodeMissing =>
      'A este enlace para restablecer la contrase?a le falta el c?digo de seguridad.';

  @override
  String get passwordUpdatedSignIn =>
      'Contrase?a actualizada. Inicia sesi?n de nuevo.';

  @override
  String get resetLinkInvalidTitle => 'No se puede usar este enlace';

  @override
  String get resetLinkInvalidBody =>
      'Es posible que el enlace haya caducado o ya se haya usado. Vuelve a la pantalla de inicio de sesi?n y solicita un nuevo correo para restablecer la contrase?a.';

  @override
  String get backToSignIn => 'Volver a iniciar sesi?n';

  @override
  String get chooseNewPassword => 'Elige una contrase?a nueva';

  @override
  String get newPassword => 'Contrase?a nueva';

  @override
  String get confirmNewPassword => 'Confirma la contrase?a nueva';

  @override
  String get passwordMinLength => 'Usa al menos 6 caracteres.';

  @override
  String get passwordsDoNotMatch => 'Las contrase?as no coinciden.';

  @override
  String get updatePassword => 'Actualizar contrase?a';

  @override
  String get editCountdownAction => 'Editar';

  @override
  String get duplicateYearLater => 'Duplicar para el a?o siguiente';

  @override
  String get countdownDuplicated => 'Duplicada ? ?brela para ajustar la fecha.';

  @override
  String get onlyOwnerCanDelete =>
      'Solo quien cre? esta cuenta atr?s puede eliminarla.';

  @override
  String get countdownDeleteFailed =>
      'No se pudo eliminar. Int?ntalo de nuevo.';

  @override
  String get countdownDeleteWarning => 'No se puede deshacer esta acci?n.';

  @override
  String blockPersonQuestion(String personName) {
    return '?Bloquear a $personName?';
  }

  @override
  String get blockExplanation =>
      'Dejar?n de verse. Se eliminar?n mutuamente de todas las cuentas atr?s que compartan, se cancelar?n las invitaciones entre ustedes y esa persona ya no podr? volver a invitarte. No se le avisar?.';

  @override
  String get undoBlockInSettings =>
      'Puedes deshacerlo cuando quieras desde Ajustes ? Personas bloqueadas.';

  @override
  String get blocking => 'Bloqueando?';

  @override
  String get blockAction => 'Bloquear';

  @override
  String personBlocked(String personName) {
    return 'Se bloque? a $personName.';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String personUnblocked(String personName) {
    return 'Se desbloque? a $personName.';
  }

  @override
  String get blockAccessNotRestored =>
      'No se restaur? el acceso a las cuentas atr?s.';

  @override
  String get undoBlockFailed =>
      'No se pudo deshacer el bloqueo. Int?ntalo de nuevo.';

  @override
  String get blockSaveFailed =>
      'No se pudo guardar el bloqueo. Inicia sesi?n de nuevo e int?ntalo otra vez.';

  @override
  String get noConnectionRetry =>
      'No hay conexi?n. Comprueba tu red e int?ntalo de nuevo.';

  @override
  String blockPersonFailed(String personName) {
    return 'No se pudo bloquear a $personName. Int?ntalo de nuevo.';
  }

  @override
  String get blockedPeopleTitle => 'Personas bloqueadas';

  @override
  String get nobodyBlocked => 'No hay personas bloqueadas';

  @override
  String get howToBlockPerson =>
      'Para bloquear a alguien, abre una cuenta atr?s que compartas con esa persona, abre el men? ? de su fila y toca Bloquear.';

  @override
  String get blockedPeopleDescription =>
      'Estas personas no pueden invitarte y no compartes ninguna cuenta atr?s con ellas. No se les avisa de que est?n bloqueadas.';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get blockedListLoadFailed =>
      'No se pudo cargar tu lista de personas bloqueadas';

  @override
  String get blockedListPermissionError =>
      'Tu cuenta no tiene permiso para leer esta lista. Si el problema contin?a, actualiza la aplicaci?n.';
}
