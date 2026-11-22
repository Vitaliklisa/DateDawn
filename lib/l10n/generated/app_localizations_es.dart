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
  String get languageEnglish => 'Inglés';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageUkrainian => 'Ucraniano';

  @override
  String get languageGerman => 'Alemán';

  @override
  String get languageChinese => 'Chino tradicional (Taiwán)';

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
  String get homeEmptyTitle => 'Ponle fecha a un día.';

  @override
  String get homeEmptyDescription =>
      'Elige un momento futuro: una boda, un lanzamiento, un viaje de vuelta a casa. Date Dawn cuenta los años, meses, días y horas que faltan y lo celebra cuando llega.';

  @override
  String get homeLoadError =>
      'No se pudieron cargar tus cuentas atrás. Desliza hacia abajo para volver a intentarlo.';

  @override
  String get getStarted => 'Empezar';

  @override
  String get homeSyncTitle => 'Tenlas siempre contigo';

  @override
  String get homeSyncDescription =>
      'Inicia sesión para sincronizar tus cuentas atrás en el teléfono, la tableta y la web, y compartirlas con quienes también esperan ese momento.';

  @override
  String get otherCountdowns => 'OTRAS CUENTAS ATRÁS';

  @override
  String get arrived => 'LLEGÓ';

  @override
  String get countingDown => 'EN CUENTA ATRÁS';

  @override
  String get options => 'Opciones';

  @override
  String get open => 'Abrir';

  @override
  String get openCountdown => 'Abrir cuenta atrás';

  @override
  String get newCountdown => 'Nueva cuenta atrás';

  @override
  String get editCountdown => 'Editar cuenta atrás';

  @override
  String get countdownTitleLabel => 'Título';

  @override
  String get countdownDescriptionLabel => 'Descripción';

  @override
  String get whenLabel => 'Cuándo';

  @override
  String get titleExampleHint => 'Boda, lanzamiento, reencuentro';

  @override
  String get descriptionExampleHint => 'Una breve nota sobre ese día';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get timeLabel => 'Hora';

  @override
  String get presetWeek => '+1 semana';

  @override
  String get presetMonth => '+1 mes';

  @override
  String get presetYear => '+1 año';

  @override
  String get presetFiveYears => '+5 años';

  @override
  String get createCountdown => 'Crear cuenta atrás';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get deleteCountdown => 'Eliminar cuenta atrás';

  @override
  String get countdownActions => 'Acciones de la cuenta atrás';

  @override
  String get deleteCountdownQuestion => '¿Eliminar esta cuenta atrás?';

  @override
  String get countdownCannotUndo => 'No se puede deshacer esta acción.';

  @override
  String get giveCountdownTitle => 'Ponle un título a esta cuenta atrás.';

  @override
  String get pickFutureMoment => 'Elige un momento que aún está por llegar.';

  @override
  String get signInToSaveCountdown =>
      'Inicia sesión para guardar cuentas atrás.';

  @override
  String get countdownCreated => 'Cuenta atrás creada.';

  @override
  String get changesSaved => 'Cambios guardados.';

  @override
  String get countdownDeleted => 'Cuenta atrás eliminada.';

  @override
  String get partnerLabel => 'tu pareja';

  @override
  String partnerNotAdded(String partnerName) {
    return 'Cuenta atrás creada, pero no se añadió a $partnerName. Invítale manualmente desde la cuenta atrás.';
  }

  @override
  String partnerAdded(String partnerName) {
    return 'Cuenta atrás creada. Se añadió a $partnerName.';
  }

  @override
  String get noPartnerAdded =>
      'Cuenta atrás creada, pero no se añadió a tu pareja. Envía la invitación manualmente.';

  @override
  String get chooseFutureDateHint =>
      'Elige una fecha futura para ver la cuenta atrás.';

  @override
  String countingDownRemaining(String remaining) {
    return 'Cuenta atrás: $remaining';
  }

  @override
  String get cannotEditCountdown =>
      'Puedes ver esta cuenta atrás, pero no modificarla.';

  @override
  String get shareWith => 'Compartir con';

  @override
  String get circleShareDescription =>
      'Las cuentas atrás de un círculo de pareja se comparten al instante. En los demás círculos, se envía una invitación.';

  @override
  String get collaborators => 'Colaboradores';

  @override
  String get collaboratorsCanFollow =>
      'Quienes invites podrán seguir esta cuenta atrás desde sus propios dispositivos.';

  @override
  String get peopleFollowing => 'Personas que siguen esta cuenta atrás.';

  @override
  String get noCollaboratorsYet => 'Todavía no hay nadie más.';

  @override
  String get nameEmailHint => 'nombre@example.com';

  @override
  String get recentContactsCouldNotLoad =>
      'No se pudieron cargar los contactos recientes. Comprueba tu conexión o las reglas de Firestore.';

  @override
  String invitationSentTo(String email) {
    return 'Invitación enviada a $email.';
  }

  @override
  String sharedWithCircle(String circleName) {
    return 'Compartido con $circleName';
  }

  @override
  String get inviteAgain => 'Volver a invitar';

  @override
  String get removePersonQuestion => '¿Eliminar a esta persona?';

  @override
  String collaboratorLosesAccess(String email) {
    return '$email perderá el acceso a esta cuenta atrás y dejará de verla en su lista.';
  }

  @override
  String get changeRole => 'Cambiar rol';

  @override
  String changeRoleFor(String personName) {
    return 'Cambiar el rol de $personName';
  }

  @override
  String roleChangeDescription(String role) {
    return 'Esto cambiará lo que puede hacer en esta cuenta atrás a partir de ahora. Actualmente tiene acceso de tipo $role.';
  }

  @override
  String rolesNotAssignable(String roles, String topRole) {
    return 'No puedes asignar $roles — tienes el rol $topRole.';
  }

  @override
  String get circlesDescriptionTitle =>
      'Grupos con los que compartes cuentas atrás';

  @override
  String get circlesDescription =>
      'Invita a alguien a un círculo una sola vez y luego comparte cualquier cuenta atrás con todo el grupo con un solo toque. Las cuentas atrás de un círculo de pareja se comparten automáticamente: lo que cree uno, lo verá el otro.';

  @override
  String get circlesLoadError =>
      'No se pudieron cargar tus círculos. Desliza hacia abajo para volver a intentarlo.';

  @override
  String get noCircles => 'Todavía no hay círculos';

  @override
  String get noCirclesDescription =>
      'Crea uno para las personas con quienes compartes la espera: tu pareja, tu familia o las amistades con quienes viajas cada año.';

  @override
  String get newCircle => 'Nuevo círculo';

  @override
  String get sharesAutomatically => 'Se comparte automáticamente';

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
  String get you => 'Tú';

  @override
  String get leaveCircle => 'Salir del círculo';

  @override
  String get deleteCircle => 'Eliminar círculo';

  @override
  String get removeFromCircle => 'Eliminar del círculo';

  @override
  String removeMemberQuestion(String personName) {
    return '¿Eliminar a $personName?';
  }

  @override
  String get removeMemberExplanation =>
      'Dejará de ver las cuentas atrás compartidas con este círculo. No se eliminará nada de lo que haya creado.';

  @override
  String leaveCircleQuestion(String circleName) {
    return '¿Salir de «$circleName»?';
  }

  @override
  String get leaveCircleExplanation =>
      'Las cuentas atrás compartidas con este círculo dejarán de aparecerte. Podrán volver a invitarte.';

  @override
  String deleteCircleQuestion(String circleName) {
    return '¿Eliminar «$circleName»?';
  }

  @override
  String get deleteCircleExplanation =>
      'El grupo desaparecerá. Las cuentas atrás compartidas con él se conservarán y seguirán siendo tuyas, pero ya no se compartirán con estas personas.';

  @override
  String get circleNameHint => 'Familia, Tokio 2027, Nosotros';

  @override
  String get coupleCircleTitle => 'Un círculo para nosotros, como pareja';

  @override
  String get coupleCircleDescription =>
      'Las cuentas atrás se comparten automáticamente con tu pareja, sin que tenga que aceptar una invitación.';

  @override
  String get circleCreated => 'Círculo creado.';

  @override
  String get coupleCircleCreated => 'Creado. Ahora invita a tu pareja.';

  @override
  String get inviteYourPartner => 'Invitar a tu pareja';

  @override
  String inviteToCircle(String circleName) {
    return 'Invitar a «$circleName»';
  }

  @override
  String get coupleInviteExplanation =>
      'Si ya tiene una cuenta, se añadirá automáticamente. De lo contrario, se añadirá cuando inicie sesión. Las futuras cuentas atrás compartidas con este círculo aparecerán automáticamente.';

  @override
  String get circleInviteExplanation =>
      'Recibirá una invitación que podrá aceptar o rechazar. Cuando se una, podrás compartir cuentas atrás con este círculo con un solo toque.';

  @override
  String get inviteEmailHint => 'persona@example.com';

  @override
  String get sendInvitation => 'Enviar invitación';

  @override
  String get partnerAddedAutomatically =>
      'Tu pareja se añadirá automáticamente.';

  @override
  String get signInToUseCircles => 'Inicia sesión para usar los círculos';

  @override
  String get circlesRequireAccounts =>
      'Como se invita a las personas a los círculos por correo electrónico, necesitan tener una cuenta para recibir una invitación.';

  @override
  String get waitingOnYou => 'Esperando tu respuesta';

  @override
  String get invitationsEmptyDescription =>
      'No se compartirá nada contigo hasta que aceptes. Si rechazas una invitación, se avisará a quien te la envió para que no se quede esperando sin saber qué pasó.';

  @override
  String get signInToSeeInvitations =>
      'Inicia sesión para ver las invitaciones';

  @override
  String get invitationsEmailAccount =>
      'Las invitaciones se envían a tu correo electrónico, así que inicia sesión con la dirección a la que te invitaron.';

  @override
  String get invitationsCouldNotLoad =>
      'No se pudieron cargar las invitaciones. Comprueba tu conexión o las reglas de Firestore.';

  @override
  String get nothingWaiting => 'No hay nada pendiente';

  @override
  String get invitationInboxEmpty =>
      'Las invitaciones que te envíen aparecerán aquí. Las invitaciones a cuentas atrás y a círculos estándar requieren una respuesta; a los círculos de pareja te unes automáticamente.';

  @override
  String get retryAddingYou => 'Volver a intentar añadirme';

  @override
  String get decline => 'Rechazar';

  @override
  String joinInviteQuestion(String eventTitle) {
    return '¿Unirte a «$eventTitle»?';
  }

  @override
  String get joinInviteExplanation =>
      'Aparecerá en tu lista y podrás ver la cuenta atrás en este dispositivo.';

  @override
  String get join => 'Unirse';

  @override
  String alreadyMemberOf(String name) {
    return 'Ya formas parte de «$name».';
  }

  @override
  String youJoined(String name) {
    return 'Te uniste a «$name».';
  }

  @override
  String youWereAddedTo(String name) {
    return 'Te añadieron a «$name».';
  }

  @override
  String get invitationDeclined => 'Invitación rechazada.';

  @override
  String get countdownInvitation => 'Invitación a una cuenta atrás';

  @override
  String get aCountdown => 'Una cuenta atrás';

  @override
  String invitedToFollowCountdown(String role) {
    return 'Te invitaron a seguir esta cuenta atrás. Si aceptas, se añadirá a tu lista con el rol $role.';
  }

  @override
  String get accept => 'Aceptar';

  @override
  String get partnerInvitation => 'Invitación de pareja';

  @override
  String get circleInvitation => 'Invitación a un círculo';

  @override
  String partnerCircleAddTitle(String personName) {
    return 'Te están añadiendo al círculo de $personName';
  }

  @override
  String get partnerCircleAddExplanation =>
      'Te añadirán automáticamente. Las cuentas atrás compartidas con este círculo aparecerán en tu lista.';

  @override
  String circleJoinExplanation(String circleName) {
    return 'Al unirte a «$circleName», las cuentas atrás que compartan con este círculo aparecerán en tu lista.';
  }

  @override
  String get becomePartners => 'Convertirse en pareja';

  @override
  String get joinCircle => 'Unirse al círculo';

  @override
  String get automaticJoinFailed =>
      'No se pudo completar la incorporación automática.';

  @override
  String get notNow => 'Ahora no';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get markAllRead => 'Marcar todo como leído';

  @override
  String get markedAllRead => 'Todo marcado como leído.';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get noReadMessagesToDelete => 'No hay mensajes leídos para eliminar.';

  @override
  String get deleteReadMessages => 'Eliminar mensajes leídos';

  @override
  String get deletedReadMessages => 'Mensajes leídos eliminados.';

  @override
  String get notificationsSignInFirst => 'Inicia sesión primero';

  @override
  String get notificationsAccountOnly =>
      'Las notificaciones están vinculadas a tu cuenta.';

  @override
  String get couldNotLoad => 'No se pudo cargar';

  @override
  String get checkConnectionRetry =>
      'Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get nothingYet => 'Todavía no hay nada';

  @override
  String get notificationsEmptyDescription =>
      'Cuando ocurra algo con tus cuentas atrás o invitaciones, aparecerá aquí.';

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
  String get countdownUnavailable => 'Esta cuenta atrás ya no está disponible.';

  @override
  String get viewDetails => 'Ver detalles';

  @override
  String get sharedWith => 'COMPARTIDO CON';

  @override
  String get notes => 'NOTAS';

  @override
  String get notesEmpty =>
      'Todavía no hay nada. Deja un comentario para quienes comparten la cuenta atrás contigo.';

  @override
  String get addNote => 'Añadir una nota';

  @override
  String get years => 'Años';

  @override
  String get months => 'Meses';

  @override
  String get days => 'Días';

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
  String get passed => 'Pasó';

  @override
  String get upcoming => 'Próximo';

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
  String get itHasArrived => 'Ya llegó.';

  @override
  String remainingToGo(String remaining) {
    return 'Faltan $remaining';
  }

  @override
  String get momentHasPassed => 'El momento ya pasó';

  @override
  String remainingAnd(String first, String last) {
    return '$first y $last';
  }

  @override
  String get dayHasCome => 'HA LLEGADO EL DÍA';

  @override
  String eventArrivedWithDescription(String title, String description) {
    return '$title ya llegó: $description';
  }

  @override
  String eventArrivedTitleOnly(String title) {
    return '$title ya llegó: disfruta cada minuto.';
  }

  @override
  String personRemovedFromCircle(String personName, String circleName) {
    return 'Se eliminó a $personName de «$circleName».';
  }

  @override
  String youLeftCircle(String circleName) {
    return 'Saliste de «$circleName».';
  }

  @override
  String circleDeleted(String circleName) {
    return 'Se eliminó «$circleName».';
  }

  @override
  String get someone => 'Alguien';

  @override
  String invitedYouToCircle(String personName, String circleName) {
    return '$personName te invitó a «$circleName»';
  }

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleEditor => 'Editor';

  @override
  String get roleViewer => 'Lector';

  @override
  String get roleAdminDescription =>
      'Puede administrar la cuenta atrás y a sus participantes.';

  @override
  String get roleEditorDescription =>
      'Puede editar la cuenta atrás e invitar a otras personas.';

  @override
  String get roleViewerDescription =>
      'Puede ver la cuenta atrás y dejar notas.';

  @override
  String remainingYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count años',
      one: '$count año',
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
      other: '$count días',
      one: '$count día',
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
  String get moreActions => 'Más acciones';

  @override
  String get block => 'Bloquear';

  @override
  String roleChanged(String personName, String role) {
    return '$personName ahora tiene el rol $role.';
  }

  @override
  String personRemoved(String personName) {
    return 'Se eliminó a $personName.';
  }

  @override
  String get signInToSaveIt => 'Inicia sesión para guardarlo';

  @override
  String get countdownsFollowYou =>
      'Tus cuentas atrás se guardan en tu cuenta, así que están disponibles en todos tus dispositivos y puedes compartirlas con otras personas.';

  @override
  String get savePermissionError =>
      'Firestore rechazó el guardado. Si sigue ocurriendo, las reglas de seguridad implementadas son anteriores a la aplicación — ejecuta `firebase deploy --only firestore:rules`.';

  @override
  String get saveNetworkError =>
      'No se pudo conectar con Firestore. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get saveFailed => 'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get momentPassed => 'El momento ya pasó';

  @override
  String get and => 'y';

  @override
  String get back => 'Atrás';

  @override
  String get policyLastUpdated =>
      'Última actualización: febrero de 2026 · Cumple con el RGPD de la UE y la PIPEDA de Canadá';

  @override
  String get privacyIntroTitle =>
      '1. Introducción y responsable del tratamiento';

  @override
  String privacyIntroBody(String supportEmail) {
    return 'Date Dawn («nosotros», «nuestro» o «nos») respeta tu privacidad y se compromete a proteger tus datos personales. Esta Política de privacidad explica cómo recopilamos, usamos y protegemos tu información cuando utilizas nuestras aplicaciones móviles y web, en pleno cumplimiento del Reglamento General de Protección de Datos (RGPD) de la Unión Europea y de la Ley de Protección de la Información Personal y los Documentos Electrónicos (PIPEDA) de Canadá.\n\nContacto del responsable del tratamiento: $supportEmail';
  }

  @override
  String get privacyCollectTitle => '2. Información que recopilamos';

  @override
  String get privacyCollectBody =>
      '• Datos de la cuenta: dirección de correo electrónico y nombre visible que proporcionas durante la autenticación (Firebase Auth).\n• Contenido del usuario: cuentas atrás, títulos, fechas, descripciones y pertenencia a círculos que creas o compartes expresamente.\n• Datos del dispositivo y las notificaciones: tokens de notificaciones push para enviarte recordatorios de cuentas atrás y avisos de invitaciones.\n\nNO recopilamos el historial de navegación, identificadores publicitarios ni datos de ubicación, ni vendemos información personal a terceros.';

  @override
  String get privacyBasisTitle =>
      '3. Base jurídica del tratamiento (RGPD de la UE)';

  @override
  String get privacyBasisBody =>
      'Tratamos tus datos conforme a las siguientes bases jurídicas:\n• Necesidad contractual: prestar las funciones de sincronización de cuentas atrás, compartir círculos y enviar invitaciones.\n• Consentimiento: cuando autorizas las notificaciones push o aceptas participar en círculos compartidos.\n• Intereses legítimos: garantizar la seguridad y fiabilidad de la aplicación y prevenir abusos.';

  @override
  String get privacySharingTitle => '4. Compartir y bloquear';

  @override
  String get privacySharingBody =>
      'Date Dawn permite que las personas interactúen entre sí: puedes invitar a alguien a una cuenta atrás y ambos pueden dejar notas en una que compartan. Ese contenido solo está visible para las personas incluidas en esa cuenta atrás; nunca es público ni se muestra a nadie más.\n\nPuedes bloquear a otra persona en cualquier momento: abre una cuenta atrás que compartas con ella y mantén pulsado su nombre (o haz clic secundario en el ordenador). Al bloquearla, ambos dejarán de aparecer en las cuentas atrás del otro, se cancelarán las invitaciones entre ustedes y esa persona ya no podrá volver a invitarte. No se le avisará. La lista de personas que has bloqueado es privada y puedes desbloquear a cualquiera desde Ajustes → Personas bloqueadas.';

  @override
  String get privacyStorageTitle =>
      '5. Almacenamiento y seguridad de los datos';

  @override
  String get privacyStorageBody =>
      'Tus datos se almacenan y procesan de forma segura mediante la infraestructura de Firebase (Google Cloud Platform), que cumple altos estándares de seguridad del sector. Los datos que se transmiten entre tu dispositivo y nuestros servidores se cifran en tránsito mediante TLS.';

  @override
  String get privacyRightsTitle =>
      '6. Tus derechos (acceso, rectificación y supresión)';

  @override
  String privacyRightsBody(String supportEmail) {
    return 'En virtud del RGPD y la PIPEDA, tienes derecho a:\n• Acceso: solicitar una copia de los datos personales que tenemos sobre ti.\n• Rectificación: actualizar o corregir la información de tu perfil en Ajustes.\n• Supresión (derecho al olvido): solicitar en cualquier momento la eliminación completa de tu cuenta y de todas las cuentas atrás y notificaciones asociadas escribiendo a $supportEmail.';
  }

  @override
  String get termsAcceptanceTitle => '1. Aceptación de los términos';

  @override
  String get termsAcceptanceBody =>
      'Al acceder a Date Dawn o utilizarlo, aceptas someterte a estos Términos del servicio. Si no estás de acuerdo con estos términos, no utilices la aplicación.';

  @override
  String get termsUseTitle => '2. Uso del servicio';

  @override
  String get termsUseBody =>
      'Date Dawn se ofrece para el seguimiento personal y no comercial de cuentas atrás y momentos compartidos. Aceptas no hacer un uso indebido del servicio, subir contenido malicioso, acosar a otras personas mediante círculos compartidos o invitaciones, ni intentar eludir los controles de seguridad.';

  @override
  String get termsOwnershipTitle => '3. Contenido del usuario y titularidad';

  @override
  String get termsOwnershipBody =>
      'Conservas todos los derechos de titularidad sobre los eventos de cuenta atrás, títulos y contenido que crees. Concedes a Date Dawn una licencia limitada, únicamente para almacenar y sincronizar tu contenido en tus dispositivos autenticados y con los miembros de los círculos con quienes lo compartas.';

  @override
  String get termsTerminationTitle =>
      '4. Cancelación y eliminación de la cuenta';

  @override
  String get termsTerminationBody =>
      'Puedes dejar de usar Date Dawn en cualquier momento y solicitar que se elimine tu cuenta escribiendo al soporte. Nos reservamos el derecho de suspender o cancelar las cuentas que infrinjan estos términos o hagan un uso abusivo de la infraestructura de la plataforma.';

  @override
  String get termsLiabilityTitle => '5. Limitación de responsabilidad';

  @override
  String get termsLiabilityBody =>
      'Date Dawn se proporciona «tal cual», sin garantías de ningún tipo. No seremos responsables de ningún daño indirecto, incidental o consecuente derivado del uso de la aplicación.';

  @override
  String get privacyPolicyTitle => 'Política de privacidad';

  @override
  String get termsOfServiceTitle => 'Términos del servicio';

  @override
  String get supportHeading => 'Leemos todos los mensajes';

  @override
  String supportIntro(String responseTime) {
    return 'Date Dawn es una aplicación independiente y pequeña. El correo electrónico es la forma más rápida de contactar con quien la desarrolla: no hay un servicio de atención intermediario. Normalmente respondemos $responseTime.';
  }

  @override
  String get supportResponseTime => 'en un plazo de 2 días laborables';

  @override
  String get supportCommonQuestions => 'Preguntas frecuentes';

  @override
  String get supportFaqGoogleQuestion =>
      'Inició sesión con Google y no aparecen mis cuentas atrás.';

  @override
  String get supportFaqGoogleAnswer =>
      'Usa el mismo método que utilizaste al crear tu cuenta. Google y el correo electrónico con contraseña no se vinculan automáticamente. Si necesitas cambiar de método o crees que tienes datos en dos cuentas, ponte en contacto con nosotros antes de crear otra cuenta.';

  @override
  String get supportFaqSharingQuestion =>
      'La persona con quien compartí la cuenta atrás no puede verla.';

  @override
  String get supportFaqSharingAnswer =>
      'Compartir una cuenta atrás con un círculo envía una invitación; no añade personas automáticamente. La otra persona debe abrir Invitaciones en la aplicación y aceptarla. Los círculos de pareja son la excepción: se comparten al instante.';

  @override
  String get supportFaqDeclinedQuestion => 'Rechacé una invitación por error.';

  @override
  String get supportFaqDeclinedAnswer =>
      'Pídele a quien te invitó que vuelva a invitarte: puede hacerlo desde la cuenta atrás tocando el icono de actualización junto a tu nombre. Mientras tanto, no se pierde nada.';

  @override
  String get supportFaqDeleteQuestion => '¿Cómo elimino mi cuenta y mis datos?';

  @override
  String get supportFaqDeleteAnswer =>
      'Escríbenos desde la dirección con la que te registraste y solicita la eliminación. Se eliminarán todas las cuentas atrás, invitaciones y notificaciones vinculadas a la cuenta, y te confirmaremos cuando se haya completado.';

  @override
  String get supportFaqBlockQuestion => '¿Cómo bloqueo a alguien?';

  @override
  String get supportFaqBlockAnswer =>
      'Abre una cuenta atrás que compartas con esa persona y mantén pulsado su nombre en la lista de personas (o haz clic secundario en el ordenador). Se eliminará de las cuentas atrás que compartan y no podrá volver a invitarte. Para deshacerlo, ve a Ajustes → Personas bloqueadas.';

  @override
  String get supportFaqAdsQuestion => '¿Venden mis datos o muestran anuncios?';

  @override
  String get supportFaqAdsAnswer =>
      'No. No hay anuncios, perfiles analíticos ni seguimiento de terceros. Lo que esperas con ilusión solo te incumbe a ti, así que se guarda en tu propia cuenta para que nadie más lo lea.';

  @override
  String get supportLegal => 'Información legal';

  @override
  String get supportNotice =>
      'Las solicitudes de reembolso, las preguntas sobre pagos y los informes de fallos se atienden en la misma dirección. Si la aplicación no funciona bien, lo más útil que puedes incluir es el modelo de tu dispositivo y lo que estabas haciendo cuando ocurrió.';

  @override
  String get supportEmailLabel => 'Contactar con soporte';

  @override
  String supportEmailCopied(String email) {
    return 'Se copió $email';
  }

  @override
  String get openMail => 'Abrir correo';

  @override
  String get linkCopiedClipboard => 'Enlace copiado al portapapeles.';

  @override
  String get verifyEmailTitle => 'Verifica tu correo electrónico';

  @override
  String verifyEmailInstructions(String email) {
    return 'Enviamos un enlace de verificación a $email. Verifica tu dirección para continuar.';
  }

  @override
  String get yourEmailAddress => 'tu dirección de correo electrónico';

  @override
  String resetLinkSent(String email) {
    return 'Enviamos un enlace para restablecer la contraseña a $email. Abre el correo más reciente.';
  }

  @override
  String get verificationEmailSent => 'Correo de verificación enviado.';

  @override
  String get verificationNotComplete =>
      'Aún no se ha verificado. Revisa tu bandeja de entrada.';

  @override
  String get verifiedSignInToContinue =>
      'Tu correo está verificado. Si es necesario, inicia sesión para continuar.';

  @override
  String get checkSpamFolder =>
      '¿No encuentras el correo? Revisa la carpeta de correo no deseado o spam.';

  @override
  String get confirmEmailVerified => 'He verificado mi correo electrónico';

  @override
  String get sendingEmail => 'Enviando…';

  @override
  String get resendEmail => 'Volver a enviar el correo';

  @override
  String get waitBeforeResending =>
      'Espera 60 segundos antes de solicitar otro correo.';

  @override
  String get resetCodeMissing =>
      'A este enlace para restablecer la contraseña le falta el código de seguridad.';

  @override
  String get passwordUpdatedSignIn =>
      'Contraseña actualizada. Inicia sesión de nuevo.';

  @override
  String get resetLinkInvalidTitle => 'No se puede usar este enlace';

  @override
  String get resetLinkInvalidBody =>
      'Es posible que el enlace haya caducado o ya se haya usado. Vuelve a la pantalla de inicio de sesión y solicita un nuevo correo para restablecer la contraseña.';

  @override
  String get backToSignIn => 'Volver a iniciar sesión';

  @override
  String get chooseNewPassword => 'Elige una contraseña nueva';

  @override
  String get newPassword => 'Contraseña nueva';

  @override
  String get confirmNewPassword => 'Confirma la contraseña nueva';

  @override
  String get passwordMinLength => 'Usa al menos 6 caracteres.';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get updatePassword => 'Actualizar contraseña';

  @override
  String get editCountdownAction => 'Editar';

  @override
  String get duplicateYearLater => 'Duplicar para el año siguiente';

  @override
  String get countdownDuplicated => 'Duplicada. Ábrela para ajustar la fecha.';

  @override
  String get onlyOwnerCanDelete =>
      'Solo quien creó esta cuenta atrás puede eliminarla.';

  @override
  String get countdownDeleteFailed =>
      'No se pudo eliminar. Inténtalo de nuevo.';

  @override
  String get countdownDeleteWarning => 'No se puede deshacer esta acción.';

  @override
  String blockPersonQuestion(String personName) {
    return '¿Bloquear a $personName?';
  }

  @override
  String get blockExplanation =>
      'Dejarán de verse. Se eliminarán mutuamente de todas las cuentas atrás que compartan, se cancelarán las invitaciones entre ustedes y esa persona ya no podrá volver a invitarte. No se le avisará.';

  @override
  String get undoBlockInSettings =>
      'Puedes deshacerlo cuando quieras desde Ajustes → Personas bloqueadas.';

  @override
  String get blocking => 'Bloqueando…';

  @override
  String get blockAction => 'Bloquear';

  @override
  String personBlocked(String personName) {
    return 'Se bloqueó a $personName.';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String personUnblocked(String personName) {
    return 'Se desbloqueó a $personName.';
  }

  @override
  String get blockAccessNotRestored =>
      'No se restauró el acceso a las cuentas atrás.';

  @override
  String get undoBlockFailed =>
      'No se pudo deshacer el bloqueo. Inténtalo de nuevo.';

  @override
  String get blockSaveFailed =>
      'No se pudo guardar el bloqueo. Inicia sesión de nuevo e inténtalo otra vez.';

  @override
  String get noConnectionRetry =>
      'No hay conexión. Comprueba tu red e inténtalo de nuevo.';

  @override
  String blockPersonFailed(String personName) {
    return 'No se pudo bloquear a $personName. Inténtalo de nuevo.';
  }

  @override
  String get blockedPeopleTitle => 'Personas bloqueadas';

  @override
  String get nobodyBlocked => 'No hay personas bloqueadas';

  @override
  String get howToBlockPerson =>
      'Para bloquear a alguien, abre una cuenta atrás que compartas con esa persona, abre el menú ⋮ de su fila y toca Bloquear.';

  @override
  String get blockedPeopleDescription =>
      'Estas personas no pueden invitarte y no compartes ninguna cuenta atrás con ellas. No se les avisa de que están bloqueadas.';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get blockedListLoadFailed =>
      'No se pudo cargar tu lista de personas bloqueadas';

  @override
  String get blockedListPermissionError =>
      'Tu cuenta no tiene permiso para leer esta lista. Si el problema continúa, actualiza la aplicación.';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountWarning =>
      'Esta acción es permanente. Todos tus eventos, círculos y datos se eliminarán para siempre.';

  @override
  String get deleteAccountConfirmationPrompt =>
      'Escribe exactamente el correo electrónico de tu cuenta para continuar.';

  @override
  String get deleteAccountConfirmationLabel =>
      'Correo electrónico de la cuenta';

  @override
  String get permanentlyDeleteAccount => 'Eliminar cuenta permanentemente';

  @override
  String get deleteAccountProfileConsequence =>
      'Tu perfil se eliminará permanentemente.';

  @override
  String get deleteAccountAccessConsequence =>
      'Perderás el acceso a todos tus eventos y círculos.';

  @override
  String get deleteAccountIrreversibleConsequence =>
      'Esta acción no se puede deshacer.';

  @override
  String get deleteAccountPermanentlyAction =>
      'Eliminar cuenta permanentemente';

  @override
  String get accountDeleted => 'Cuenta eliminada correctamente';

  @override
  String get serverTimedOutTryAgain =>
      'El servidor agotó el tiempo de espera. Inténtalo de nuevo más tarde.';

  @override
  String get accountDeletionFailed =>
      'No se pudo completar la eliminación de la cuenta. Inténtalo de nuevo.';

  @override
  String get accountDeletedCleanupWarning =>
      'La cuenta se eliminó, pero no se pudieron borrar algunos ajustes locales. Reinicia la aplicación antes de usar otra cuenta.';
}
