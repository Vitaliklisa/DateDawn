import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

const localePreferenceKey = 'app_locale';
const supportedAppLocales = <Locale>[
  Locale('en'),
  Locale('fr'),
  Locale('es'),
  Locale('uk'),
  Locale('de'),
  Locale('zh', 'TW'),
];

class LocalePreference {
  const LocalePreference({
    required this.activeLocale,
    required this.selectedLocale,
  });

  final Locale activeLocale;
  final Locale? selectedLocale;
}

Locale? supportedLocaleForCode(String? languageCode) {
  if (languageCode == null) return null;
  for (final locale in supportedAppLocales) {
    if (locale.languageCode == languageCode.toLowerCase()) return locale;
  }
  return null;
}

LocalePreference resolveLocalePreference({
  required String? savedLanguageCode,
  required Locale deviceLocale,
}) {
  final savedLocale = supportedLocaleForCode(savedLanguageCode);
  if (savedLocale != null) {
    return LocalePreference(
      activeLocale: savedLocale,
      selectedLocale: savedLocale,
    );
  }

  return LocalePreference(
    activeLocale:
        supportedLocaleForCode(deviceLocale.languageCode) ?? const Locale('en'),
    selectedLocale: null,
  );
}

Future<LocalePreference> loadLocalePreference({
  SharedPreferences? preferences,
  Locale? deviceLocale,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  return resolveLocalePreference(
    savedLanguageCode: prefs.getString(localePreferenceKey),
    deviceLocale: deviceLocale ?? PlatformDispatcher.instance.locale,
  );
}
