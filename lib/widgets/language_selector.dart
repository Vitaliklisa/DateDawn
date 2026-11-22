import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale_settings.dart';
import '../l10n/app_localizations_context.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({this.iconOnly = false, super.key});

  final bool iconOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedLocale = ref.watch(selectedLocaleProvider);
    final label = selectedLocale == null
        ? l10n.followSystemLanguage
        : '${_localeFlag(selectedLocale)} ${_localeName(l10n, selectedLocale)}';

    if (iconOnly) {
      return IconButton(
        key: const ValueKey('language-selector'),
        tooltip: l10n.language,
        onPressed: () => _showChoices(context, ref, l10n),
        icon: const Icon(Icons.language_rounded),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ListTile(
        key: const ValueKey('language-selector'),
        leading: const Icon(Icons.language_rounded),
        title: Text(l10n.language),
        subtitle: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
        onTap: () => _showChoices(context, ref, l10n),
      ),
    );
  }

  Future<void> _showChoices(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final selectedLocale = ref.read(selectedLocaleProvider);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                l10n.language,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            for (final locale in supportedAppLocales)
              ListTile(
                key: ValueKey('locale-option-${locale.languageCode}'),
                leading: ExcludeSemantics(
                  child: Text(
                    _localeFlag(locale),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(_localeName(l10n, locale)),
                trailing: selectedLocale == locale
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => _selectLocale(
                  context,
                  sheetContext,
                  ref,
                  locale,
                  l10n,
                ),
              ),
            ListTile(
              key: const ValueKey('locale-option-system'),
              leading: const Icon(Icons.language_rounded),
              title: Text(l10n.followSystemLanguage),
              trailing: selectedLocale == null
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => _selectLocale(
                context,
                sheetContext,
                ref,
                null,
                l10n,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLocale(
    BuildContext context,
    BuildContext sheetContext,
    WidgetRef ref,
    Locale? locale,
    AppLocalizations l10n,
  ) async {
    Navigator.of(sheetContext).pop();
    try {
      await ref.read(localePreferenceProvider.notifier).setLocale(locale);
    } catch (error, stackTrace) {
      debugPrint('[datedawn] Could not save the selected language: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.languageSaveFailed)),
      );
    }
  }

  String _localeName(AppLocalizations l10n, Locale locale) {
    return switch (locale.languageCode) {
      'fr' => l10n.languageFrench,
      'es' => l10n.languageSpanish,
      'uk' => l10n.languageUkrainian,
      'de' => l10n.languageGerman,
      'zh' => l10n.languageChinese,
      _ => l10n.languageEnglish,
    };
  }

  String _localeFlag(Locale locale) {
    return switch (locale.languageCode) {
      'fr' => '🇫🇷',
      'es' => '🇪🇸',
      'uk' => '🇺🇦',
      'de' => '🇩🇪',
      'zh' => '🇹🇼',
      _ => '🇬🇧',
    };
  }
}
