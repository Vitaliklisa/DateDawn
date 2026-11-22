// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Date Dawn';

  @override
  String get language => 'Мова';

  @override
  String get followSystemLanguage => 'Мова системи';

  @override
  String get languageChanged => 'Мову змінено.';

  @override
  String get languageSaveFailed => 'Не вдалося зберегти налаштування мови.';

  @override
  String get languageEnglish => 'Англійська';

  @override
  String get languageFrench => 'Французька';

  @override
  String get languageSpanish => 'Іспанська';

  @override
  String get languageUkrainian => 'Українська';

  @override
  String get languageGerman => 'Німецька';

  @override
  String get languageChinese => 'Традиційна китайська (Тайвань)';

  @override
  String get settings => 'Налаштування';

  @override
  String get dateDawnUser => 'Користувач Date Dawn';

  @override
  String get guestAccount => 'Гостьовий обліковий запис';

  @override
  String get notSignedIn => 'Ви не ввійшли';

  @override
  String get syncAndShareDescription =>
      'Увійдіть, щоб синхронізувати відліки на всіх пристроях і ділитися ними з іншими.';

  @override
  String get signIn => 'Увійти';

  @override
  String get appearance => 'ВИГЛЯД';

  @override
  String get darkTheme => 'Темна';

  @override
  String get lightTheme => 'Світла';

  @override
  String get systemTheme => 'Системна';

  @override
  String get time => 'ЧАС';

  @override
  String get timeFormatDescription =>
      'Формат відображення часу. Відліки зберігають точні моменти — змінюється лише їхнє відображення.';

  @override
  String get twelveHourTime => '12-годинний (AM/PM)';

  @override
  String get twentyFourHourTime => '24-годинний';

  @override
  String get about => 'ПРО ЗАСТОСУНОК';

  @override
  String get version => 'Версія';

  @override
  String get sync => 'Синхронізація';

  @override
  String get safety => 'БЕЗПЕКА';

  @override
  String get blockedPeople => 'Заблоковані люди';

  @override
  String get legal => 'ЮРИДИЧНА ІНФОРМАЦІЯ';

  @override
  String get privacyPolicy => 'Політика конфіденційності';

  @override
  String get termsOfService => 'Умови використання';

  @override
  String get helpAndSupport => 'Допомога та підтримка';

  @override
  String get signOut => 'Вийти';

  @override
  String get signedOut => 'Ви вийшли.';

  @override
  String countdownsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count відліку',
      many: '$count відліків',
      few: '$count відліки',
      one: '$count відлік',
    );
    return '$_temp0';
  }

  @override
  String get welcomeToDateDawn => 'Ласкаво просимо до Date Dawn';

  @override
  String get createYourAccount => 'Створіть обліковий запис';

  @override
  String get countdownsSyncDescription =>
      'Ваші відліки синхронізуються на всіх пристроях, де ви ввійшли.';

  @override
  String get welcomeDescription =>
      'Відлічуйте час до важливих моментів — на телефоні, планшеті та в інтернеті.';

  @override
  String get name => 'Ім’я';

  @override
  String get nameHint => 'Олександр Коваленко';

  @override
  String get nameRequired => 'Напишіть, як до вас звертатися.';

  @override
  String get email => 'Електронна пошта';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Введіть адресу електронної пошти.';

  @override
  String get emailInvalid => 'Схоже, адреса електронної пошти неправильна.';

  @override
  String get password => 'Пароль';

  @override
  String get passwordRequired => 'Введіть пароль.';

  @override
  String get passwordTooShort => 'Використайте щонайменше 6 символів.';

  @override
  String get forgotPassword => 'Забули пароль?';

  @override
  String get forgotPasswordPrompt =>
      'Спочатку введіть електронну пошту, а потім натисніть «Забули пароль?».';

  @override
  String get signInConnectionError =>
      'Не вдалося підключитися до служби входу. Перевірте з’єднання.';

  @override
  String get createAccount => 'Створити обліковий запис';

  @override
  String get or => 'АБО';

  @override
  String get continueWithGoogle => 'Продовжити з Google';

  @override
  String get alreadyHaveAccount => 'Вже маєте обліковий запис? ';

  @override
  String get newHere => 'Вперше тут? ';

  @override
  String get createOne => 'Створити';

  @override
  String get troubleSigningIn => 'Не вдається увійти? Отримати допомогу';

  @override
  String get accountCreated => 'Обліковий запис створено.';

  @override
  String get welcomeBack => 'З поверненням.';

  @override
  String get signInFailed => 'Не вдалося ввійти. Спробуйте ще раз.';

  @override
  String get signedInWithGoogle => 'Ви ввійшли через Google.';

  @override
  String get home => 'Головна';

  @override
  String get invitations => 'Запрошення';

  @override
  String get circles => 'Кола';

  @override
  String get notifications => 'Сповіщення';

  @override
  String get support => 'Підтримка';

  @override
  String get homeEmptyTitle => 'Призначте важливий день.';

  @override
  String get homeEmptyDescription =>
      'Оберіть майбутню подію — весілля, запуск проєкту чи повернення додому. Date Dawn відлічуватиме роки, місяці, дні й години та привітає вас, коли цей момент настане.';

  @override
  String get homeLoadError =>
      'Не вдалося завантажити відліки. Потягніть униз, щоб спробувати ще раз.';

  @override
  String get getStarted => 'Почати';

  @override
  String get homeSyncTitle => 'Ваші відліки завжди поруч';

  @override
  String get homeSyncDescription =>
      'Увійдіть, щоб синхронізувати відліки на телефоні, планшеті й у вебверсії та ділитися ними з тими, хто чекає разом із вами.';

  @override
  String get otherCountdowns => 'ІНШІ ВІДЛІКИ';

  @override
  String get arrived => 'НАСТАВ';

  @override
  String get countingDown => 'ВІДЛІК';

  @override
  String get options => 'Параметри';

  @override
  String get open => 'Відкрити';

  @override
  String get openCountdown => 'Відкрити відлік';

  @override
  String get newCountdown => 'Новий відлік';

  @override
  String get editCountdown => 'Редагувати відлік';

  @override
  String get countdownTitleLabel => 'Назва';

  @override
  String get countdownDescriptionLabel => 'Опис';

  @override
  String get whenLabel => 'Коли';

  @override
  String get titleExampleHint => 'Весілля, запуск, зустріч';

  @override
  String get descriptionExampleHint => 'Коротка нотатка про цей день';

  @override
  String get dateLabel => 'Дата';

  @override
  String get timeLabel => 'Час';

  @override
  String get presetWeek => '+1 тиждень';

  @override
  String get presetMonth => '+1 місяць';

  @override
  String get presetYear => '+1 рік';

  @override
  String get presetFiveYears => '+5 років';

  @override
  String get createCountdown => 'Створити відлік';

  @override
  String get saveChanges => 'Зберегти зміни';

  @override
  String get deleteCountdown => 'Видалити відлік';

  @override
  String get countdownActions => 'Дії з відліком';

  @override
  String get deleteCountdownQuestion => 'Видалити цей відлік?';

  @override
  String get countdownCannotUndo => 'Відновити відлік буде неможливо.';

  @override
  String get giveCountdownTitle => 'Укажіть назву відліку.';

  @override
  String get pickFutureMoment => 'Оберіть майбутній момент.';

  @override
  String get signInToSaveCountdown => 'Увійдіть, щоб зберегти відліки.';

  @override
  String get countdownCreated => 'Відлік створено.';

  @override
  String get changesSaved => 'Зміни збережено.';

  @override
  String get countdownDeleted => 'Відлік видалено.';

  @override
  String get partnerLabel => 'ваш партнер';

  @override
  String partnerNotAdded(String partnerName) {
    return 'Відлік створено, але $partnerName не додано. Запросіть цю людину вручну з відліку.';
  }

  @override
  String partnerAdded(String partnerName) {
    return 'Відлік створено. Додано: $partnerName.';
  }

  @override
  String get noPartnerAdded =>
      'Відлік створено, але партнера не додано. Запросіть його вручну.';

  @override
  String get chooseFutureDateHint =>
      'Оберіть майбутню дату, щоб побачити відлік.';

  @override
  String countingDownRemaining(String remaining) {
    return 'До події залишилося: $remaining';
  }

  @override
  String get cannotEditCountdown =>
      'Ви можете переглядати цей відлік, але не можете його змінювати.';

  @override
  String get shareWith => 'Поділитися з';

  @override
  String get circleShareDescription =>
      'У парному колі відлік з’явиться одразу. В інших колах учасники отримають запрошення.';

  @override
  String get collaborators => 'Учасники';

  @override
  String get collaboratorsCanFollow =>
      'Запрошені зможуть стежити за відліком на своїх пристроях.';

  @override
  String get peopleFollowing => 'Люди, які стежать за цим відліком.';

  @override
  String get noCollaboratorsYet => 'Поки що більше нікого.';

  @override
  String get nameEmailHint => 'name@example.com';

  @override
  String get recentContactsCouldNotLoad =>
      'Не вдалося завантажити останні контакти. Перевірте з’єднання або правила Firestore.';

  @override
  String invitationSentTo(String email) {
    return 'Запрошення надіслано: $email.';
  }

  @override
  String sharedWithCircle(String circleName) {
    return 'Спільний доступ для кола «$circleName»';
  }

  @override
  String get inviteAgain => 'Запросити ще раз';

  @override
  String get removePersonQuestion => 'Видалити цю людину?';

  @override
  String collaboratorLosesAccess(String email) {
    return '$email втратить доступ до цього відліку, і він зникне зі списку цієї людини.';
  }

  @override
  String get changeRole => 'Змінити роль';

  @override
  String changeRoleFor(String personName) {
    return 'Змінити роль для $personName';
  }

  @override
  String roleChangeDescription(String role) {
    return 'Відтепер зміниться доступ цієї людини до відліку. Її поточна роль: $role.';
  }

  @override
  String rolesNotAssignable(String roles, String topRole) {
    return 'Ви не можете призначити ролі «$roles» — ваша роль: $topRole.';
  }

  @override
  String get circlesDescriptionTitle =>
      'Групи людей, з якими ви чекаєте на події';

  @override
  String get circlesDescription =>
      'Запросіть людей до кола один раз, а потім діліться відліками з усією групою в один дотик. Парне коло ділиться автоматично — усе, що створює один партнер, бачить інший.';

  @override
  String get circlesLoadError =>
      'Не вдалося завантажити кола. Потягніть униз, щоб спробувати ще раз.';

  @override
  String get noCircles => 'Кіл поки що немає';

  @override
  String get noCirclesDescription =>
      'Створіть коло для близьких — партнера, родини або друзів, з якими щороку подорожуєте.';

  @override
  String get newCircle => 'Нове коло';

  @override
  String get sharesAutomatically => 'Ділиться автоматично';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count людини',
      many: '$count людей',
      few: '$count людини',
      one: '$count людина',
    );
    return '$_temp0';
  }

  @override
  String get inviteSomeone => 'Запросити когось';

  @override
  String get you => 'Ви';

  @override
  String get leaveCircle => 'Покинути коло';

  @override
  String get deleteCircle => 'Видалити коло';

  @override
  String get removeFromCircle => 'Видалити з кола';

  @override
  String removeMemberQuestion(String personName) {
    return 'Видалити $personName?';
  }

  @override
  String get removeMemberExplanation =>
      'Ця людина більше не бачитиме відліки, якими поділилися з цим колом. Її власні відліки не буде видалено.';

  @override
  String leaveCircleQuestion(String circleName) {
    return 'Покинути коло «$circleName»?';
  }

  @override
  String get leaveCircleExplanation =>
      'Відліки, якими поділилися з цим колом, зникнуть із вашого списку. Вас можна запросити знову.';

  @override
  String deleteCircleQuestion(String circleName) {
    return 'Видалити коло «$circleName»?';
  }

  @override
  String get deleteCircleExplanation =>
      'Коло зникне. Відліки залишаться у своїх власників, але їх більше не буде відкрито для цих людей.';

  @override
  String get circleNameHint => 'Родина, Токіо 2027, Ми';

  @override
  String get coupleCircleTitle => 'Ми — пара';

  @override
  String get coupleCircleDescription =>
      'Відліки автоматично з’являтимуться у вашого партнера без запрошення.';

  @override
  String get circleCreated => 'Коло створено.';

  @override
  String get coupleCircleCreated => 'Створено. Тепер запросіть партнера.';

  @override
  String get inviteYourPartner => 'Запросити партнера';

  @override
  String inviteToCircle(String circleName) {
    return 'Запросити до кола «$circleName»';
  }

  @override
  String get coupleInviteExplanation =>
      'Якщо ця людина вже має обліковий запис, її буде додано автоматично. Інакше — після входу. Нові відліки, доступні цьому колу, з’являтимуться автоматично.';

  @override
  String get circleInviteExplanation =>
      'Людина отримає запрошення, яке можна прийняти або відхилити. Після приєднання ви зможете ділитися відліками в один дотик.';

  @override
  String get inviteEmailHint => 'them@example.com';

  @override
  String get sendInvitation => 'Надіслати запрошення';

  @override
  String get partnerAddedAutomatically => 'Партнера буде додано автоматично.';

  @override
  String get signInToUseCircles => 'Увійдіть, щоб користуватися колами';

  @override
  String get circlesRequireAccounts =>
      'Щоб запросити людей до кола електронною поштою, їм потрібен обліковий запис.';

  @override
  String get waitingOnYou => 'Очікують на вашу відповідь';

  @override
  String get invitationsEmptyDescription =>
      'Спільний доступ з’явиться після прийняття запрошення. Якщо відхилити його, запрошувач знатиме, що ви відповіли.';

  @override
  String get signInToSeeInvitations => 'Увійдіть, щоб переглянути запрошення';

  @override
  String get invitationsEmailAccount =>
      'Запрошення надсилають на вашу пошту, тому ввійдіть за адресою, на яку вас запросили.';

  @override
  String get invitationsCouldNotLoad =>
      'Не вдалося завантажити запрошення. Перевірте з’єднання або правила Firestore.';

  @override
  String get nothingWaiting => 'Немає нових запрошень';

  @override
  String get invitationInboxEmpty =>
      'Надіслані вам запрошення з’являтимуться тут. Запрошення до відліків і звичайних кіл потрібно приймати; до парного кола додають автоматично.';

  @override
  String get retryAddingYou => 'Спробувати додати знову';

  @override
  String get decline => 'Відхилити';

  @override
  String joinInviteQuestion(String eventTitle) {
    return 'Приєднатися до «$eventTitle»?';
  }

  @override
  String get joinInviteExplanation =>
      'Відлік з’явиться у вашому списку та на цьому пристрої.';

  @override
  String get join => 'Приєднатися';

  @override
  String alreadyMemberOf(String name) {
    return 'Ви вже учасник кола «$name».';
  }

  @override
  String youJoined(String name) {
    return 'Ви приєдналися до «$name».';
  }

  @override
  String youWereAddedTo(String name) {
    return 'Вас додано до «$name».';
  }

  @override
  String get invitationDeclined => 'Запрошення відхилено.';

  @override
  String get countdownInvitation => 'Запрошення до відліку';

  @override
  String get aCountdown => 'Відлік';

  @override
  String invitedToFollowCountdown(String role) {
    return 'Вас запросили стежити за цим відліком. Після прийняття він з’явиться у вашому списку з роллю «$role».';
  }

  @override
  String get accept => 'Прийняти';

  @override
  String get partnerInvitation => 'Запрошення від партнера';

  @override
  String get circleInvitation => 'Запрошення до кола';

  @override
  String partnerCircleAddTitle(String personName) {
    return 'Вас додають до кола $personName';
  }

  @override
  String get partnerCircleAddExplanation =>
      'Вас додадуть автоматично. Відліки, доступні цьому колу, з’являтимуться у вашому списку.';

  @override
  String circleJoinExplanation(String circleName) {
    return 'Після приєднання до кола «$circleName» відліки, якими в ньому поділилися, з’являться у вашому списку.';
  }

  @override
  String get becomePartners => 'Стати партнерами';

  @override
  String get joinCircle => 'Приєднатися до кола';

  @override
  String get automaticJoinFailed => 'Не вдалося автоматично приєднатися.';

  @override
  String get notNow => 'Не зараз';

  @override
  String get notificationsTitle => 'Сповіщення';

  @override
  String get markAllRead => 'Позначити все прочитаним';

  @override
  String get markedAllRead => 'Усе позначено прочитаним.';

  @override
  String get moreOptions => 'Інші параметри';

  @override
  String get noReadMessagesToDelete =>
      'Немає прочитаних повідомлень для видалення.';

  @override
  String get deleteReadMessages => 'Видалити прочитані повідомлення';

  @override
  String get deletedReadMessages => 'Прочитані повідомлення видалено.';

  @override
  String get notificationsSignInFirst => 'Спочатку увійдіть';

  @override
  String get notificationsAccountOnly =>
      'Сповіщення пов’язані з вашим обліковим записом.';

  @override
  String get couldNotLoad => 'Не вдалося завантажити';

  @override
  String get checkConnectionRetry => 'Перевірте з’єднання та спробуйте ще раз.';

  @override
  String get nothingYet => 'Поки що нічого';

  @override
  String get notificationsEmptyDescription =>
      'Тут з’являтимуться новини про ваші відліки та запрошення.';

  @override
  String get liveNotificationsCouldNotLoad =>
      'Не вдалося завантажити сповіщення.';

  @override
  String get inbox => 'ВХІДНІ';

  @override
  String get invitationResponses => 'ВІДПОВІДІ НА ЗАПРОШЕННЯ';

  @override
  String get invitationResponsesCouldNotLoad =>
      'Не вдалося завантажити відповіді на запрошення.';

  @override
  String get countdownUnavailable => 'Цей відлік більше недоступний.';

  @override
  String get viewDetails => 'Переглянути деталі';

  @override
  String get sharedWith => 'СПІЛЬНИЙ ДОСТУП';

  @override
  String get notes => 'НОТАТКИ';

  @override
  String get notesEmpty =>
      'Поки що нічого. Залиште думку для всіх, хто чекає разом із вами.';

  @override
  String get addNote => 'Додати нотатку';

  @override
  String get years => 'Роки';

  @override
  String get months => 'Місяці';

  @override
  String get days => 'Дні';

  @override
  String get hours => 'Години';

  @override
  String remainingMinutes(int count) {
    return '$count хв';
  }

  @override
  String remainingSeconds(int count) {
    return '$count с залишилося';
  }

  @override
  String get cancel => 'Скасувати';

  @override
  String get keep => 'Залишити';

  @override
  String get stay => 'Залишитися';

  @override
  String get leave => 'Покинути';

  @override
  String get remove => 'Видалити';

  @override
  String get delete => 'Видалити';

  @override
  String get create => 'Створити';

  @override
  String get tryAgain => 'Спробувати ще раз';

  @override
  String get share => 'Поділитися';

  @override
  String get passed => 'Минула';

  @override
  String get upcoming => 'Попереду';

  @override
  String get accepted => 'Прийнято';

  @override
  String get declined => 'Відхилено';

  @override
  String get removed => 'Видалено';

  @override
  String get reopened => 'Надіслано знову';

  @override
  String get waiting => 'Очікування';

  @override
  String get itHasArrived => 'Цей день настав.';

  @override
  String remainingToGo(String remaining) {
    return 'Залишилося: $remaining';
  }

  @override
  String get momentHasPassed => 'Цей момент уже минув';

  @override
  String remainingAnd(String first, String last) {
    return '$first і $last';
  }

  @override
  String get dayHasCome => 'ЦЕЙ ДЕНЬ НАСТАВ';

  @override
  String eventArrivedWithDescription(String title, String description) {
    return '$title — $description';
  }

  @override
  String eventArrivedTitleOnly(String title) {
    return '$title — насолоджуйтеся кожною миттю.';
  }

  @override
  String personRemovedFromCircle(String personName, String circleName) {
    return '$personName видалено з кола «$circleName».';
  }

  @override
  String youLeftCircle(String circleName) {
    return 'Ви покинули коло «$circleName».';
  }

  @override
  String circleDeleted(String circleName) {
    return 'Коло «$circleName» видалено.';
  }

  @override
  String get someone => 'Хтось';

  @override
  String invitedYouToCircle(String personName, String circleName) {
    return '$personName запросив вас до кола «$circleName»';
  }

  @override
  String get roleAdmin => 'Адміністратор';

  @override
  String get roleEditor => 'Редактор';

  @override
  String get roleViewer => 'Глядач';

  @override
  String get roleAdminDescription =>
      'Може керувати відліком і його учасниками.';

  @override
  String get roleEditorDescription =>
      'Може редагувати відлік і запрошувати інших.';

  @override
  String get roleViewerDescription =>
      'Може переглядати відлік і залишати нотатки.';

  @override
  String remainingYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count року',
      many: '$count років',
      few: '$count роки',
      one: '$count рік',
    );
    return '$_temp0';
  }

  @override
  String remainingMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count місяця',
      many: '$count місяців',
      few: '$count місяці',
      one: '$count місяць',
    );
    return '$_temp0';
  }

  @override
  String remainingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count днів',
      few: '$count дні',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String remainingHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count години',
      many: '$count годин',
      few: '$count години',
      one: '$count година',
    );
    return '$_temp0';
  }

  @override
  String remainingMinuteUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хвилини',
      many: '$count хвилин',
      few: '$count хвилини',
      one: '$count хвилина',
    );
    return '$_temp0';
  }

  @override
  String remainingSecondUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунди',
      many: '$count секунд',
      few: '$count секунди',
      one: '$count секунда',
    );
    return '$_temp0';
  }

  @override
  String get moreActions => 'Інші дії';

  @override
  String get block => 'Заблокувати';

  @override
  String roleChanged(String personName, String role) {
    return '$personName: нова роль — $role.';
  }

  @override
  String personRemoved(String personName) {
    return '$personName видалено.';
  }

  @override
  String get signInToSaveIt => 'Увійдіть, щоб зберегти відлік';

  @override
  String get countdownsFollowYou =>
      'Відліки зберігаються у вашому обліковому записі, тож вони доступні на всіх пристроях і ними можна ділитися.';

  @override
  String get savePermissionError =>
      'Firestore відхилив збереження. Якщо це повторюється, правила безпеки застаріли — виконайте `firebase deploy --only firestore:rules`.';

  @override
  String get saveNetworkError =>
      'Не вдалося підключитися до Firestore. Перевірте з’єднання та спробуйте ще раз.';

  @override
  String get saveFailed => 'Не вдалося зберегти. Спробуйте ще раз.';

  @override
  String get momentPassed => 'Цей момент уже настав';

  @override
  String get and => 'і';

  @override
  String get back => 'Назад';

  @override
  String get policyLastUpdated =>
      'Оновлено: лютий 2026 · Відповідає GDPR ЄС і PIPEDA Канади';

  @override
  String get privacyIntroTitle => '1. Вступ і контролер даних';

  @override
  String privacyIntroBody(String supportEmail) {
    return 'Date Dawn (далі — «ми», «наш» або «нас») поважає вашу конфіденційність і прагне захищати ваші персональні дані. Ця Політика конфіденційності пояснює, як ми збираємо, використовуємо та захищаємо інформацію під час користування нашими мобільними й вебзастосунками відповідно до Загального регламенту ЄС про захист даних (GDPR) і Закону Канади про захист персональної інформації та електронних документів (PIPEDA).\n\nКонтакт контролера даних: $supportEmail';
  }

  @override
  String get privacyCollectTitle => '2. Яку інформацію ми збираємо';

  @override
  String get privacyCollectBody =>
      '• Дані облікового запису: адреса електронної пошти та ім’я, указані під час автентифікації (Firebase Auth).\n• Вміст користувача: створені або поширені вами відліки, назви, дати, описи та членство в колах.\n• Дані пристрою та сповіщень: токени push-сповіщень для нагадувань про відліки й запрошення.\n\nМи НЕ збираємо історію переглядів, рекламні ідентифікатори чи дані про місцезнаходження, не продаємо персональну інформацію третім сторонам.';

  @override
  String get privacyBasisTitle => '3. Правові підстави обробки (GDPR ЄС)';

  @override
  String get privacyBasisBody =>
      'Ми обробляємо ваші дані на таких правових підставах:\n• Необхідність для виконання договору: синхронізація відліків, спільний доступ до кіл і запрошення.\n• Згода: коли ви дозволяєте push-сповіщення або приєднуєтеся до спільних кіл.\n• Законні інтереси: безпека й надійність застосунку та запобігання зловживанням.';

  @override
  String get privacySharingTitle => '4. Спільний доступ і блокування';

  @override
  String get privacySharingBody =>
      'У Date Dawn люди можуть взаємодіяти один з одним: запросити когось до відліку й залишати нотатки у спільному відліку. Цей вміст бачать лише учасники відліку — він не є публічним і не показується іншим.\n\nВи можете будь-коли заблокувати людину: відкрийте спільний відлік і затисніть її ім’я (або клацніть правою кнопкою на комп’ютері). Після блокування ви зникнете зі спільних відліків одне одного, запрошення між вами буде скасовано, а ця людина не зможе запросити вас знову. Ми не повідомляємо її про блокування. Список заблокованих бачите лише ви; розблокувати людину можна в Налаштуваннях → Заблоковані люди.';

  @override
  String get privacyStorageTitle => '5. Зберігання та безпека даних';

  @override
  String get privacyStorageBody =>
      'Ваші дані безпечно зберігаються й обробляються на інфраструктурі Firebase (Google Cloud Platform), яка відповідає високим галузевим стандартам безпеки. Дані, що передаються між пристроєм і нашими серверами, шифруються за допомогою TLS.';

  @override
  String get privacyRightsTitle =>
      '6. Ваші права (доступ, виправлення та видалення)';

  @override
  String privacyRightsBody(String supportEmail) {
    return 'Відповідно до GDPR і PIPEDA ви маєте право:\n• На доступ: запитати копію персональних даних, які ми зберігаємо.\n• На виправлення: оновити або виправити дані профілю в Налаштуваннях.\n• На видалення («право бути забутим»): будь-коли попросити повністю видалити обліковий запис і пов’язані з ним відліки та сповіщення, написавши на адресу $supportEmail.';
  }

  @override
  String get termsAcceptanceTitle => '1. Прийняття умов';

  @override
  String get termsAcceptanceBody =>
      'Користуючись Date Dawn або отримуючи доступ до нього, ви погоджуєтеся дотримуватися цих Умов використання. Якщо ви не згодні з ними, не користуйтеся застосунком.';

  @override
  String get termsUseTitle => '2. Використання сервісу';

  @override
  String get termsUseBody =>
      'Date Dawn призначений для особистого, некомерційного відліку часу до подій і спільного відстеження важливих моментів. Ви погоджуєтеся не зловживати сервісом, не завантажувати шкідливий вміст, не переслідувати інших через спільні кола чи запрошення та не обходити засоби безпеки.';

  @override
  String get termsOwnershipTitle => '3. Вміст користувача та права власності';

  @override
  String get termsOwnershipBody =>
      'Ви зберігаєте всі права власності на створені вами події-відліки, назви та вміст. Ви надаєте Date Dawn обмежений дозвіл лише на зберігання й синхронізацію вмісту між вашими пристроями, на яких ви ввійшли, та учасниками спільних кіл.';

  @override
  String get termsTerminationTitle =>
      '4. Припинення користування та видалення облікового запису';

  @override
  String get termsTerminationBody =>
      'Ви можете будь-коли припинити користуватися Date Dawn і попросити видалити обліковий запис, написавши в службу підтримки. Ми залишаємо за собою право призупинити або закрити облікові записи, які порушують ці умови чи зловживають інфраструктурою платформи.';

  @override
  String get termsLiabilityTitle => '5. Обмеження відповідальності';

  @override
  String get termsLiabilityBody =>
      'Date Dawn надається «як є» без будь-яких гарантій. Ми не несемо відповідальності за непрямі, випадкові чи побічні збитки, що виникають унаслідок використання застосунку.';

  @override
  String get privacyPolicyTitle => 'Політика конфіденційності';

  @override
  String get termsOfServiceTitle => 'Умови використання';

  @override
  String get supportHeading => 'Ми читаємо кожне повідомлення';

  @override
  String supportIntro(String responseTime) {
    return 'Date Dawn — невеликий незалежний застосунок. Найшвидше зв’язатися з його розробником можна електронною поштою — між вами немає служби підтримки. Зазвичай ми відповідаємо $responseTime.';
  }

  @override
  String get supportResponseTime => 'протягом 2 робочих днів';

  @override
  String get supportCommonQuestions => 'Поширені запитання';

  @override
  String get supportFaqGoogleQuestion =>
      'Я ввійшов через Google, але мої відліки зникли.';

  @override
  String get supportFaqGoogleAnswer =>
      'Скористайтеся тим самим способом, що й під час створення облікового запису. Google і електронна пошта з паролем автоматично не пов’язуються. Якщо потрібно змінити спосіб входу або ви маєте дані у двох облікових записах, зв’яжіться з нами, перш ніж створювати інший обліковий запис.';

  @override
  String get supportFaqSharingQuestion =>
      'Людина, з якою я поділився відліком, його не бачить.';

  @override
  String get supportFaqSharingAnswer =>
      'Поширення відліку через коло надсилає запрошення, але не додає людей автоматично. Вони мають відкрити в застосунку запрошення й прийняти його. Виняток — парне коло: спільний доступ у ньому вмикається одразу.';

  @override
  String get supportFaqDeclinedQuestion => 'Я випадково відхилив запрошення.';

  @override
  String get supportFaqDeclinedAnswer =>
      'Попросіть людину, яка вас запросила, надіслати запрошення ще раз — це можна зробити у відліку, натиснувши значок оновлення біля вашого імені. Тим часом нічого не зникне.';

  @override
  String get supportFaqDeleteQuestion =>
      'Як видалити обліковий запис і свої дані?';

  @override
  String get supportFaqDeleteAnswer =>
      'Напишіть нам з адреси, яку вказали під час реєстрації, і попросіть видалити обліковий запис. Усі пов’язані з ним відліки, запрошення та сповіщення буде видалено, а ми підтвердимо завершення.';

  @override
  String get supportFaqBlockQuestion => 'Як заблокувати людину?';

  @override
  String get supportFaqBlockAnswer =>
      'Відкрийте спільний відлік і затисніть ім’я людини у списку учасників (на комп’ютері клацніть правою кнопкою). Її буде видалено зі спільних відліків, і вона не зможе запросити вас знову. Щоб скасувати блокування, перейдіть у Налаштування → Заблоковані люди.';

  @override
  String get supportFaqAdsQuestion =>
      'Ви продаєте мої дані або показуєте рекламу?';

  @override
  String get supportFaqAdsAnswer =>
      'Ні. У застосунку немає реклами, профілів аналітики чи стороннього відстеження. Ваші відліки — особиста справа, тому вони зберігаються у вашому обліковому записі й недоступні іншим.';

  @override
  String get supportLegal => 'Юридична інформація';

  @override
  String get supportNotice =>
      'Питання щодо повернення коштів, оплати чи звіту про збій надсилайте на ту саму адресу. Якщо застосунок працює неправильно, найкорисніше вказати модель пристрою та що саме ви робили в той момент.';

  @override
  String get supportEmailLabel => 'Написати в підтримку';

  @override
  String supportEmailCopied(String email) {
    return 'Адресу $email скопійовано';
  }

  @override
  String get openMail => 'Відкрити пошту';

  @override
  String get linkCopiedClipboard => 'Посилання скопійовано в буфер обміну.';

  @override
  String get verifyEmailTitle => 'Підтвердьте електронну пошту';

  @override
  String verifyEmailInstructions(String email) {
    return 'Ми надіслали посилання для підтвердження на адресу $email. Підтвердьте її, щоб продовжити.';
  }

  @override
  String get yourEmailAddress => 'вашу електронну адресу';

  @override
  String resetLinkSent(String email) {
    return 'Посилання для скидання пароля надіслано на $email. Скористайтеся найновішим листом.';
  }

  @override
  String get verificationEmailSent => 'Лист для підтвердження надіслано.';

  @override
  String get verificationNotComplete =>
      'Ще не підтверджено. Перевірте вхідні листи.';

  @override
  String get verifiedSignInToContinue =>
      'Електронну пошту підтверджено. За потреби увійдіть, щоб продовжити.';

  @override
  String get checkSpamFolder =>
      'Не бачите листа? Перевірте папку «Спам» або «Небажана пошта».';

  @override
  String get confirmEmailVerified => 'Я підтвердив свою електронну пошту';

  @override
  String get sendingEmail => 'Надсилання…';

  @override
  String get resendEmail => 'Надіслати лист ще раз';

  @override
  String get waitBeforeResending =>
      'Зачекайте 60 секунд, перш ніж запитувати ще один лист.';

  @override
  String get resetCodeMissing =>
      'У посиланні для скидання пароля немає коду безпеки.';

  @override
  String get passwordUpdatedSignIn => 'Пароль оновлено. Увійдіть знову.';

  @override
  String get resetLinkInvalidTitle =>
      'Цим посиланням для скидання пароля скористатися не можна';

  @override
  String get resetLinkInvalidBody =>
      'Термін дії посилання міг закінчитися або ним уже скористалися. Поверніться до входу й запросіть новий лист для скидання пароля.';

  @override
  String get backToSignIn => 'Повернутися до входу';

  @override
  String get chooseNewPassword => 'Створіть новий пароль';

  @override
  String get newPassword => 'Новий пароль';

  @override
  String get confirmNewPassword => 'Підтвердьте новий пароль';

  @override
  String get passwordMinLength => 'Введіть щонайменше 6 символів.';

  @override
  String get passwordsDoNotMatch => 'Паролі не збігаються.';

  @override
  String get updatePassword => 'Оновити пароль';

  @override
  String get editCountdownAction => 'Редагувати';

  @override
  String get duplicateYearLater => 'Дублювати на рік пізніше';

  @override
  String get countdownDuplicated =>
      'Створено копію — відкрийте її, щоб змінити дату.';

  @override
  String get onlyOwnerCanDelete =>
      'Видалити цей відлік може лише його власник.';

  @override
  String get countdownDeleteFailed => 'Не вдалося видалити. Спробуйте ще раз.';

  @override
  String get countdownDeleteWarning => 'Цю дію не можна скасувати.';

  @override
  String blockPersonQuestion(String personName) {
    return 'Заблокувати $personName?';
  }

  @override
  String get blockExplanation =>
      'Ви більше не бачитимете одне одного. Людину буде видалено з усіх спільних відліків, запрошення між вами буде скасовано, і вона не зможе запросити вас знову. Ми не повідомлятимемо її про це.';

  @override
  String get undoBlockInSettings =>
      'Скасувати блокування можна будь-коли в Налаштуваннях → Заблоковані люди.';

  @override
  String get blocking => 'Блокування…';

  @override
  String get blockAction => 'Заблокувати';

  @override
  String personBlocked(String personName) {
    return '$personName заблоковано.';
  }

  @override
  String get undo => 'Скасувати';

  @override
  String personUnblocked(String personName) {
    return '$personName розблоковано.';
  }

  @override
  String get blockAccessNotRestored =>
      'Доступ до попередніх відліків не відновлено.';

  @override
  String get undoBlockFailed =>
      'Не вдалося скасувати блокування. Спробуйте ще раз.';

  @override
  String get blockSaveFailed =>
      'Не вдалося зберегти блокування. Увійдіть знову й повторіть спробу.';

  @override
  String get noConnectionRetry =>
      'Немає з’єднання. Перевірте мережу й спробуйте ще раз.';

  @override
  String blockPersonFailed(String personName) {
    return 'Не вдалося заблокувати $personName. Спробуйте ще раз.';
  }

  @override
  String get blockedPeopleTitle => 'Заблоковані люди';

  @override
  String get nobodyBlocked => 'Нікого не заблоковано';

  @override
  String get howToBlockPerson =>
      'Щоб заблокувати людину, відкрийте спільний відлік, натисніть меню ⋮ біля її імені та виберіть «Заблокувати».';

  @override
  String get blockedPeopleDescription =>
      'Ці люди не можуть вас запросити, і ви не маєте з ними спільних відліків. Ми не повідомляємо їх про блокування.';

  @override
  String get unblock => 'Розблокувати';

  @override
  String get blockedListLoadFailed =>
      'Не вдалося завантажити список заблокованих людей';

  @override
  String get blockedListPermissionError =>
      'Ваш обліковий запис не має доступу до цього списку. Якщо проблема не зникне, оновіть застосунок.';

  @override
  String get deleteAccount => 'Видалити обліковий запис';

  @override
  String get deleteAccountWarning =>
      'Цю дію неможливо скасувати. Усі ваші події, кола та дані буде видалено назавжди.';

  @override
  String get deleteAccountConfirmationPrompt =>
      'Введіть точну електронну адресу облікового запису, щоб продовжити.';

  @override
  String get deleteAccountConfirmationLabel =>
      'Електронна адреса облікового запису';

  @override
  String get permanentlyDeleteAccount => 'Видалити обліковий запис назавжди';

  @override
  String get deleteAccountProfileConsequence =>
      'Ваш профіль буде видалено назавжди.';

  @override
  String get deleteAccountAccessConsequence =>
      'Ви втратите доступ до всіх своїх подій і кіл.';

  @override
  String get deleteAccountIrreversibleConsequence =>
      'Цю дію неможливо скасувати.';

  @override
  String get deleteAccountPermanentlyAction =>
      'Видалити обліковий запис назавжди';

  @override
  String get accountDeleted => 'Обліковий запис успішно видалено';

  @override
  String get serverTimedOutTryAgain =>
      'Час очікування відповіді сервера минув. Спробуйте ще раз пізніше.';

  @override
  String get accountDeletionFailed =>
      'Не вдалося видалити обліковий запис. Спробуйте ще раз.';

  @override
  String get accountDeletedCleanupWarning =>
      'Обліковий запис видалено, але не вдалося очистити деякі локальні налаштування. Перезапустіть застосунок, перш ніж увійти в інший обліковий запис.';
}
