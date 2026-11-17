import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ??
      lookupAppLocalizations(Localizations.localeOf(this));
}
