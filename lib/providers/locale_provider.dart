import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/locale_settings.dart';

class LocalePreferenceController extends Notifier<LocalePreference> {
  LocalePreferenceController({this.initialPreference});

  final LocalePreference? initialPreference;

  @override
  LocalePreference build() =>
      initialPreference ??
      LocalePreference(
        activeLocale: supportedLocaleForCode(
                PlatformDispatcher.instance.locale.languageCode) ??
            const Locale('en'),
        selectedLocale: null,
      );

  Future<void> setLocale(Locale? locale) async {
    final selected =
        locale == null ? null : supportedLocaleForCode(locale.languageCode);
    if (locale != null && selected == null) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported app language');
    }

    final preferences = await SharedPreferences.getInstance();
    if (selected == null) {
      await preferences.remove(localePreferenceKey);
    } else {
      await preferences.setString(localePreferenceKey, selected.languageCode);
    }

    final deviceLocale = PlatformDispatcher.instance.locale;
    state = LocalePreference(
      activeLocale: selected ??
          supportedLocaleForCode(deviceLocale.languageCode) ??
          const Locale('en'),
      selectedLocale: selected,
    );
  }

  void updateSystemLocale(Locale? deviceLocale) {
    if (state.selectedLocale != null) return;
    final device = deviceLocale ?? PlatformDispatcher.instance.locale;
    state = LocalePreference(
      activeLocale:
          supportedLocaleForCode(device.languageCode) ?? const Locale('en'),
      selectedLocale: null,
    );
  }
}

final localePreferenceProvider =
    NotifierProvider<LocalePreferenceController, LocalePreference>(
  LocalePreferenceController.new,
);

final localeProvider = Provider<Locale>(
  (ref) => ref.watch(localePreferenceProvider).activeLocale,
);

final selectedLocaleProvider = Provider<Locale?>(
  (ref) => ref.watch(localePreferenceProvider).selectedLocale,
);
