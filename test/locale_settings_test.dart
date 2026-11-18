import 'package:datedawn/core/locale_settings.dart';
import 'package:datedawn/l10n/generated/app_localizations.dart';
import 'package:datedawn/providers/app_providers.dart';
import 'package:datedawn/providers/locale_provider.dart';
import 'package:datedawn/screens/login_screen.dart';
import 'package:datedawn/screens/policy_screen.dart';
import 'package:datedawn/screens/settings_screen.dart';
import 'package:datedawn/widgets/countdown_face.dart';
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

    test('supports Ukrainian as a saved and device language', () {
      final savedLanguage = resolveLocalePreference(
        savedLanguageCode: 'uk',
        deviceLocale: const Locale('en'),
      );
      final deviceLanguage = resolveLocalePreference(
        savedLanguageCode: 'pt',
        deviceLocale: const Locale('uk', 'UA'),
      );

      expect(savedLanguage.activeLocale, const Locale('uk'));
      expect(savedLanguage.selectedLocale, const Locale('uk'));
      expect(deviceLanguage.activeLocale, const Locale('uk'));
      expect(deviceLanguage.selectedLocale, isNull);
    });

    test('supports German as a saved and device language', () {
      final savedLanguage = resolveLocalePreference(
        savedLanguageCode: 'de',
        deviceLocale: const Locale('en'),
      );
      final deviceLanguage = resolveLocalePreference(
        savedLanguageCode: 'pt',
        deviceLocale: const Locale('de', 'DE'),
      );

      expect(savedLanguage.activeLocale, const Locale('de'));
      expect(savedLanguage.selectedLocale, const Locale('de'));
      expect(deviceLanguage.activeLocale, const Locale('de'));
      expect(deviceLanguage.selectedLocale, isNull);
    });

    test('falls through unsupported saved language to device then English', () {
      final deviceLanguage = resolveLocalePreference(
        savedLanguageCode: 'pt',
        deviceLocale: const Locale('fr', 'CA'),
      );
      final englishFallback = resolveLocalePreference(
        savedLanguageCode: 'pt',
        deviceLocale: const Locale('pt'),
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
    for (final flag in ['🇺🇸', '🇫🇷', '🇪🇸', '🇺🇦', '🇩🇪']) {
      expect(find.text(flag), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('locale-option-fr')));
    await tester.pumpAndSettle();

    expect(find.text('Réglages'), findsOneWidget);
    expect(find.text('Langue'), findsOneWidget);
    expect(find.text('🇫🇷 Français'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(localePreferenceKey), 'fr');
  });

  testWidgets('mobile login keeps language selection out of the form',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeAuthStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Date Dawn'), findsOneWidget);
    expect(find.byKey(const ValueKey('language-selector')), findsNothing);
  });

  testWidgets('Ukrainian can be selected and updates settings strings',
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

    await tester.tap(find.byKey(const ValueKey('language-selector')));
    await tester.pumpAndSettle();
    expect(find.text('Українська'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('locale-option-uk')));
    await tester.pumpAndSettle();

    expect(find.text('Налаштування'), findsOneWidget);
    expect(find.text('Мова'), findsOneWidget);
    final localizations =
        AppLocalizations.of(tester.element(find.text('Налаштування')))!;
    expect(localizations.countdownsCount(2), '2 відліки');
    expect(localizations.countdownsCount(5), '5 відліків');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(localePreferenceKey), 'uk');
  });

  testWidgets('Ukrainian policy and countdown labels render localized',
      (tester) async {
    Widget localizedApp(Widget home) => MaterialApp(
          locale: const Locale('uk'),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home,
        );

    await tester.pumpWidget(localizedApp(const PolicyScreen(isPrivacy: true)));
    expect(find.text('Політика конфіденційності'), findsOneWidget);
    expect(find.text('1. Вступ і контролер даних'), findsOneWidget);
    expect(find.textContaining('Оновлено: лютий 2026'), findsOneWidget);

    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: CountdownFace(
                target: DateTime(2027, 1, 1),
                now: DateTime(2026, 1, 1),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('РОКИ'), findsOneWidget);
    expect(find.text('МІСЯЦІ'), findsOneWidget);
    expect(find.text('ДНІ'), findsOneWidget);
    expect(find.text('ГОДИНИ'), findsOneWidget);
  });

  testWidgets('Spanish and French policy and countdown labels are localized',
      (tester) async {
    final localeExpectations = [
      (
        locale: const Locale('es'),
        policyTitle: 'Política de privacidad',
        introTitle: '1. Introducción y responsable del tratamiento',
        countdownLabels: ['AÑOS', 'MESES', 'DÍAS', 'HORAS'],
      ),
      (
        locale: const Locale('fr'),
        policyTitle: 'Politique de confidentialité',
        introTitle: '1. Introduction et responsable du traitement',
        countdownLabels: ['ANNÉES', 'MOIS', 'JOURS', 'HEURES'],
      ),
    ];

    for (final expected in localeExpectations) {
      await tester.pumpWidget(
        MaterialApp(
          locale: expected.locale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const PolicyScreen(isPrivacy: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(expected.policyTitle), findsOneWidget);
      expect(find.text(expected.introTitle), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          locale: expected.locale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: CountdownFace(
                  target: DateTime(2027, 1, 1),
                  now: DateTime(2026, 1, 1),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      for (final label in expected.countdownLabels) {
        expect(find.text(label), findsOneWidget);
      }
    }
  });

  testWidgets('German can be selected and updates app screen translations',
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

    await tester.tap(find.byKey(const ValueKey('language-selector')));
    await tester.pumpAndSettle();
    expect(find.text('Deutsch'), findsOneWidget);
    final germanOption = find.byKey(const ValueKey('locale-option-de'));
    await tester.ensureVisible(germanOption);
    await tester.pumpAndSettle();
    await tester.tap(germanOption);
    await tester.pumpAndSettle();

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Sprache'), findsOneWidget);
    expect(find.text('🇩🇪 Deutsch'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(localePreferenceKey), 'de');

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        supportedLocales: supportedAppLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: PolicyScreen(isPrivacy: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Datenschutzrichtlinie'), findsOneWidget);
    expect(find.text('1. Einleitung & Verantwortlicher'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: supportedAppLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: CountdownFace(
                target: DateTime(2027, 1, 1),
                now: DateTime(2026, 1, 1),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('JAHRE'), findsOneWidget);
    expect(find.text('MONATE'), findsOneWidget);
    expect(find.text('TAGE'), findsOneWidget);
    expect(find.text('STUNDEN'), findsOneWidget);
  });
}
