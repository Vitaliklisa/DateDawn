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
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageUkrainian => 'Українська';

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
}
