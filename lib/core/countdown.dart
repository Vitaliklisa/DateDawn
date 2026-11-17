import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import 'time_format.dart';

/// How much time is left until a target moment, broken into calendar units.
///
/// Direct port of `src/lib/countdown.ts` from the web app: years and months are
/// calendar-aware (a "month" is the same day-of-month next month), while days,
/// hours, minutes and seconds are plain arithmetic on top of that.
class Remaining {
  const Remaining({
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.totalMs,
    required this.isPast,
  });

  final int years;
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final int totalMs;
  final bool isPast;

  static const Remaining zero = Remaining(
    years: 0,
    months: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0,
    totalMs: 0,
    isPast: true,
  );

  /// `true` once the event is close enough that the ticking unit is hours.
  bool get isImminent => !isPast && years == 0 && months == 0 && days == 0;
}

/// Counts from [now] to [target] in calendar units.
Remaining remainingUntil(DateTime target, [DateTime? nowOverride]) {
  final now = nowOverride ?? DateTime.now();
  final totalMs = target.millisecondsSinceEpoch - now.millisecondsSinceEpoch;

  if (totalMs <= 0) {
    return Remaining(
      years: 0,
      months: 0,
      days: 0,
      hours: 0,
      minutes: 0,
      seconds: 0,
      totalMs: totalMs < 0 ? totalMs : 0,
      isPast: true,
    );
  }

  // Walk forward month by month, then day, hour, minute — mirroring the
  // addYears/addMonths/addDays chain in the web implementation, which is what
  // makes "3 months" mean three calendar months rather than 90 days.
  var cursor = now;
  final years = _wholeYearsBetween(cursor, target);
  cursor = _addYears(cursor, years);

  final months = _wholeMonthsBetween(cursor, target);
  cursor = _addMonths(cursor, months);

  final days = target.difference(cursor).inDays;
  cursor = cursor.add(Duration(days: days));

  final hours = target.difference(cursor).inHours;
  cursor = cursor.add(Duration(hours: hours));

  final minutes = target.difference(cursor).inMinutes;
  cursor = cursor.add(Duration(minutes: minutes));

  final seconds = target.difference(cursor).inSeconds;

  return Remaining(
    years: years,
    months: months,
    days: days,
    hours: hours,
    minutes: minutes,
    seconds: seconds,
    totalMs: totalMs,
    isPast: false,
  );
}

int _wholeYearsBetween(DateTime from, DateTime to) {
  var years = to.year - from.year;
  final candidate = _addYears(from, years);
  if (candidate.isAfter(to)) years -= 1;
  return years < 0 ? 0 : years;
}

int _wholeMonthsBetween(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + (to.month - from.month);
  final candidate = _addMonths(from, months);
  if (candidate.isAfter(to)) months -= 1;
  return months < 0 ? 0 : months;
}

/// Adds calendar years, clamping Feb 29 to Feb 28 in non-leap years.
DateTime _addYears(DateTime from, int years) {
  final targetYear = from.year + years;
  final lastDay = DateTime(targetYear, from.month + 1, 0).day;
  return DateTime(
    targetYear,
    from.month,
    from.day > lastDay ? lastDay : from.day,
    from.hour,
    from.minute,
    from.second,
  );
}

/// Adds calendar months, clamping to the last valid day of the target month.
DateTime _addMonths(DateTime from, int months) {
  final zeroBased = from.month - 1 + months;
  final year = from.year + (zeroBased ~/ 12);
  final month = (zeroBased % 12) + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(
    year,
    month,
    from.day > lastDay ? lastDay : from.day,
    from.hour,
    from.minute,
    from.second,
  );
}

/// Two-digit zero padding, matching `pad2` in the web app.
String pad2(int n) => n < 0 ? '00' : n.toString().padLeft(2, '0');

/// A compact human phrase — "2 years, 3 months, 4 days and 5 hours".
String describeRemaining(
  Remaining r, {
  bool compact = false,
  AppLocalizations? l10n,
}) {
  if (r.isPast) return l10n?.momentHasPassed ?? 'The moment has passed';

  final parts = <String>[];
  if (r.years > 0) parts.add(_remainingUnit(l10n, 'years', r.years));
  if (r.months > 0) parts.add(_remainingUnit(l10n, 'months', r.months));
  if (r.days > 0) parts.add(_remainingUnit(l10n, 'days', r.days));
  if (r.hours > 0) parts.add(_remainingUnit(l10n, 'hours', r.hours));

  if (parts.isEmpty) {
    if (r.minutes > 0) return _remainingUnit(l10n, 'minutes', r.minutes);
    return _remainingUnit(l10n, 'seconds', r.seconds);
  }

  if (compact) return parts.take(2).join(' · ');

  if (parts.length == 1) return parts.first;
  final last = parts.removeLast();
  return l10n?.remainingAnd(parts.join(', '), last) ??
      '${parts.join(', ')} and $last';
}

String _remainingUnit(AppLocalizations? l10n, String unit, int count) {
  if (l10n == null) return '$count ${_englishUnit(unit, count)}';
  return switch (unit) {
    'years' => l10n.remainingYears(count),
    'months' => l10n.remainingMonths(count),
    'days' => l10n.remainingDays(count),
    'hours' => l10n.remainingHours(count),
    'minutes' => l10n.remainingMinutes(count),
    _ => l10n.remainingSeconds(count),
  };
}

String _englishUnit(String unit, int count) =>
    count == 1 ? unit.substring(0, unit.length - 1) : unit;

/// "Wed, March 14, 2026 · 6:00 PM" — the format used across the detail header.
///
/// [format] defaults to 12-hour so an existing call site keeps the wording it
/// had; screens that honour the user's preference pass it in explicitly.
String formatMomentFull(
  DateTime when, {
  TimeFormat? format,
  MaterialLocalizations? localizations,
}) {
  final timeFormat = format ?? TimeFormat.twelveHour;
  if (localizations != null) {
    final date = localizations.formatFullDate(when);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(when),
      alwaysUse24HourFormat: timeFormat.uses24HourClock,
    );
    return '$date · $time';
  }
  return DateFormat('EEE, MMMM d, yyyy · ${timeFormat.timePattern}')
      .format(when);
}

/// "Mar 14, 2026 · 6:00 PM" — the compact form used in event rows.
String formatMomentShort(
  DateTime when, {
  TimeFormat? format,
  MaterialLocalizations? localizations,
}) {
  final timeFormat = format ?? TimeFormat.twelveHour;
  if (localizations != null) {
    final date = localizations.formatMediumDate(when);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(when),
      alwaysUse24HourFormat: timeFormat.uses24HourClock,
    );
    return '$date · $time';
  }
  return DateFormat('MMM d, yyyy · ${timeFormat.timePattern}').format(when);
}

/// A time with no date, for "at 6:00 PM" style copy.
String formatClock(
  DateTime when, {
  TimeFormat? format,
  MaterialLocalizations? localizations,
}) {
  final timeFormat = format ?? TimeFormat.twelveHour;
  if (localizations != null) {
    return localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(when),
      alwaysUse24HourFormat: timeFormat.uses24HourClock,
    );
  }
  return DateFormat(timeFormat.timePattern).format(when);
}
