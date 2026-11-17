import 'package:datedawn/core/locale_settings.dart';
import 'package:datedawn/l10n/generated/app_localizations.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/providers/locale_provider.dart';
import 'package:datedawn/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SettingsTestApp extends ConsumerWidget {
  const _SettingsTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      key: ValueKey(locale),
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SettingsScreen(),
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('locale fallback', () {
    test('uses a supported saved language before the device language', () {
      final result = resolveLocalePreference(
        savedLanguageCode: 'es',
        deviceLocale: const Locale('fr'),
      );

      expect(result.activeLocale, const Locale('es'));
      expect(result.selectedLocale, const Locale('es'));
    });

    test('falls through unsupported saved language to device then English', () {
      final deviceLanguage = resolveLocalePreference(
        savedLanguageCode: 'de',
        deviceLocale: const Locale('fr', 'CA'),
      );
      final englishFallback = resolveLocalePreference(
        savedLanguageCode: 'de',
        deviceLocale: const Locale('de'),
      );

      expect(deviceLanguage.activeLocale, const Locale('fr'));
      expect(deviceLanguage.selectedLocale, isNull);
      expect(englishFallback.activeLocale, const Locale('en'));
      expect(englishFallback.selectedLocale, isNull);
    });
  });

  test('choosing follow-system removes the stored locale code', () async {
    SharedPreferences.setMockInitialValues({localePreferenceKey: 'es'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        localePreferenceProvider.overrideWith(
          () => LocalePreferenceController(
            initialPreference: const LocalePreference(
              activeLocale: Locale('es'),
              selectedLocale: Locale('es'),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(localePreferenceProvider.notifier).setLocale(null);

    expect(preferences.containsKey(localePreferenceKey), isFalse);
    expect(container.read(selectedLocaleProvider), isNull);
    expect(
      supportedLocaleForCode(
        container.read(localeProvider).languageCode,
      ),
      isNotNull,
    );
  });

  testWidgets('settings language selection updates strings and persists',
      (tester) async {
    final initialPreference = resolveLocalePreference(
      savedLanguageCode: null,
      deviceLocale: const Locale('en'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localePreferenceProvider.overrideWith(
            () => LocalePreferenceController(
              initialPreference: initialPreference,
            ),
          ),
          currentUserProvider.overrideWith((ref) => null),
          eventsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const _SettingsTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('locale-option-fr')));
    await tester.pumpAndSettle();

    expect(find.text('Réglages'), findsOneWidget);
    expect(find.text('Langue'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(localePreferenceKey), 'fr');
  });
}
