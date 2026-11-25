import 'package:flutter/foundation.dart';

/// Weeks start on Saturday (common in Bangladesh). Becomes a setting later;
/// everything reads this constant so that change stays local.
const int kWeekStartDay = DateTime.saturday;

/// A half-open range of local time: [start] inclusive, [end] exclusive.
/// Half-open ranges tile without gaps or overlaps, which keeps "this month"
/// and "last month" totals from double-counting the boundary instant.
@immutable
final class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  /// Number of calendar days covered.
  int get dayCount => calendarDaysBetween(start, end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start – $end)';
}

/// Midnight at the start of [t]'s local day.
DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// Whole calendar days from [a] to [b], ignoring time of day and any DST
/// shift (computed on UTC dates).
int calendarDaysBetween(DateTime a, DateTime b) {
  final ua = DateTime.utc(a.year, a.month, a.day);
  final ub = DateTime.utc(b.year, b.month, b.day);
  return ub.difference(ua).inDays;
}

DateRange dayRange(DateTime t) =>
    DateRange(dateOnly(t), DateTime(t.year, t.month, t.day + 1));

/// The week containing [t], starting on [startDay] (default Saturday).
DateRange weekRange(DateTime t, {int startDay = kWeekStartDay}) {
  final offset = (t.weekday - startDay) % 7;
  final start = DateTime(t.year, t.month, t.day - offset);
  return DateRange(start, DateTime(start.year, start.month, start.day + 7));
}

/// The calendar month containing [t].
DateRange monthRange(DateTime t) =>
    DateRange(DateTime(t.year, t.month), DateTime(t.year, t.month + 1));

/// The month before the one containing [t].
DateRange previousMonthRange(DateTime t) =>
    monthRange(DateTime(t.year, t.month - 1));

/// Days remaining in [t]'s month, counting today (last day of month → 1).
int daysLeftInMonth(DateTime t) => calendarDaysBetween(t, monthRange(t).end);

/// The same point in last month for fair comparisons ("by this day last
/// month"): Mar 31 → Feb 28/29, never spilling into March.
DateTime sameDayLastMonth(DateTime t) {
  final prev = previousMonthRange(t);
  final lastDay = prev.dayCount;
  final day = t.day > lastDay ? lastDay : t.day;
  return DateTime(
    prev.start.year,
    prev.start.month,
    day,
    t.hour,
    t.minute,
    t.second,
  );
}
