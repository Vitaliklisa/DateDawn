import 'dart:ui' show Locale;

import 'package:intl/intl.dart';

/// How clock times are written: `3:40 PM` or `15:40`.
///
/// This is a display preference only — every timestamp is stored as an absolute
/// instant and rendered in the device's local zone either way. Nothing about the
/// data changes when this flips, which is why it can be a free choice rather
/// than something baked in at creation time.
enum TimeFormat {
  /// 12-hour with an AM/PM marker. The default because the app's copy is
  /// written in US English and most readers of it expect `3:40 PM`.
  twelveHour,

  /// 24-hour, no marker. `15:40`.
  twentyFourHour;

  /// The pattern `intl` should use for a time-only string.
  ///
  /// `j` is intl's locale-aware "hour" skeleton: it renders as `h a` in a
  /// 12-hour locale and `H` in a 24-hour one. That is exactly the distinction
  /// being offered, so it is spelled out explicitly rather than left to the
  /// device locale, which the user cannot easily change from inside the app.
  String get timePattern =>
      this == TimeFormat.twentyFourHour ? 'HH:mm' : 'h:mm a';

  /// The pattern for a full moment: date plus a time in the chosen format.
  ///
  /// The date half stays in the locale's own order (`MMM d, y`), so a reader
  /// who prefers 24-hour time but writes dates as `March 3` still gets both.
  String get momentPattern => 'MMM d, y · $timePattern';

  /// The compact form, for list rows where space is tight.
  String get shortMomentPattern => 'MMM d, $timePattern';

  /// A human label for the settings control.
  String get label =>
      this == TimeFormat.twentyFourHour ? '24-hour' : '12-hour (AM/PM)';

  /// One line explaining the choice, with a live example.
  String get description => this == TimeFormat.twentyFourHour
      ? 'Used across the app. A 3:40 in the afternoon reads as 15:40.'
      : 'Used across the app. A 3:40 in the afternoon reads as 3:40 PM.';

  /// A worked example, so the setting can be understood without applying it.
  String get example => this == TimeFormat.twentyFourHour ? '15:40' : '3:40 PM';
}

/// The wire form stored in `users/{uid}.timeFormat`.
String timeFormatToWire(TimeFormat format) =>
    format == TimeFormat.twentyFourHour ? '24h' : '12h';

/// Parses a stored time format, or `null` when the value is missing or not one
/// this version understands.
///
/// Returns `null` rather than a default so a caller can tell "no preference on
/// record" apart from "chose 12-hour" — the same reason
/// `themeModeFromWire` is nullable.
TimeFormat? timeFormatFromWire(Object? value) {
  switch (value) {
    case '24h':
      return TimeFormat.twentyFourHour;
    case '12h':
      return TimeFormat.twelveHour;
    default:
      return null;
  }
}

/// Resolves the format to use when nothing has been chosen.
///
/// Follows the device's own locale rather than hard-coding a US default: an
/// Italian phone that has never opened Settings should see `15:40`, not
/// `3:40 PM`. A locale whose time pattern contains `H` is a 24-hour one.
TimeFormat defaultTimeFormatFor(Locale locale) {
  final pattern = DateFormat.jm(locale.toString()).pattern ?? '';
  return pattern.contains('H')
      ? TimeFormat.twentyFourHour
      : TimeFormat.twelveHour;
}
