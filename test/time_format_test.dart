import 'dart:ui' show Locale;

import 'package:datedawn/core/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaultTimeFormatFor', () {
    // The regression this suite exists for.
    //
    // `defaultTimeFormatFor` runs inside `TimeFormatController.build`, during
    // the first widget build of the app. It used to call `DateFormat.jm(locale)`
    // unguarded, and `intl` only ships data for `en_US` until
    // `initializeDateFormatting` has run — which this app never does, because it
    // would pull every locale's data into the web bundle.
    //
    // So every locale except the literal `en_US` raised `LocaleDataException`
    // out of a provider `build`, the routed screen failed to build, and the app
    // painted the navigation shell over an empty canvas — the grey screen. On
    // web the tag comes from the *browser*, so `en_US` was the exception and the
    // throw was the rule.
    //
    // Nothing here may throw, for any locale a browser can report.
    test('never throws for a locale with no intl data', () {
      for (final tag in [
        'en',
        'en-US',
        'en-GB',
        'uk',
        'de',
        'de-DE',
        'fr-FR',
        'zh-CN',
        'ja',
        'ar',
      ]) {
        expect(
          () => defaultTimeFormatFor(Locale(tag)),
          returnsNormally,
          reason: 'Locale("$tag") must resolve without throwing',
        );
      }
    });

    test('reads a 24-hour region as 24-hour', () {
      expect(
          defaultTimeFormatFor(const Locale('uk')), TimeFormat.twentyFourHour);
      expect(defaultTimeFormatFor(const Locale('de-DE')),
          TimeFormat.twentyFourHour);
      expect(defaultTimeFormatFor(const Locale('fr-FR')),
          TimeFormat.twentyFourHour);
    });

    test('reads an English-speaking region as 12-hour', () {
      expect(defaultTimeFormatFor(const Locale('en')), TimeFormat.twelveHour);
      expect(
          defaultTimeFormatFor(const Locale('en-GB')), TimeFormat.twelveHour);
    });

    // The one tag `intl` answers without initialization, kept as a control: it
    // must still take the real `DateFormat` path rather than the fallback set.
    test('still reads en_US through intl', () {
      expect(
          defaultTimeFormatFor(const Locale('en_US')), TimeFormat.twelveHour);
    });
  });

  group('time format wire form', () {
    test('round-trips', () {
      for (final format in TimeFormat.values) {
        expect(timeFormatFromWire(timeFormatToWire(format)), format);
      }
    });

    test('an unknown or missing value is null, not a default', () {
      // Nullable on purpose: it lets the caller tell "never chose" from
      // "chose 12-hour", which is what decides whether the device default wins.
      expect(timeFormatFromWire(null), isNull);
      expect(timeFormatFromWire(''), isNull);
      expect(timeFormatFromWire('25h'), isNull);
    });
  });

  group('the time picker follows the app setting', () {
    // The bug this pins: `showTimePicker` reads
    // `MediaQuery.alwaysUse24HourFormat`, which defaults to the *platform's*
    // convention. The editor never overrode it, so a user who had chosen
    // 24-hour in Settings still got an AM/PM dial on a device set to 12-hour —
    // and the composer contradicted itself, showing `18:00` on the tile beneath
    // a dialog asking for `6:00 PM`.
    //
    // The editor passes `format.uses24HourClock` straight into the dialog's
    // `MediaQuery`, so this getter *is* the behaviour: pinning it here pins
    // what the picker does.
    test('a 24-hour preference asks the dial for 24-hour', () {
      expect(TimeFormat.twentyFourHour.uses24HourClock, isTrue);
    });

    test('a 12-hour preference asks the dial for AM/PM', () {
      expect(TimeFormat.twelveHour.uses24HourClock, isFalse);
    });

    test('every format maps to a definite flag, never null', () {
      for (final format in TimeFormat.values) {
        expect(format.uses24HourClock, isA<bool>());
      }
    });

    test('the 24-hour pattern has no AM/PM marker', () {
      // The tile under the dialog uses this pattern; if it carried `a` the two
      // halves could disagree even with the flag set.
      expect(TimeFormat.twentyFourHour.timePattern.contains('a'), isFalse);
      expect(TimeFormat.twelveHour.timePattern.contains('a'), isTrue);
    });
  });
}
