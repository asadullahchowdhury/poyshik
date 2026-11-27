import '../../data/db/app_database.dart';

/// The [n]th occurrence of a schedule that starts at [start] (n = 0 is
/// [start] itself). Months and years keep the start's day of month and
/// clamp to the month's last day, so "the 31st" falls on 30 April and
/// 28/29 February, then returns to the 31st. The time of day is kept.
DateTime occurrence(
  DateTime start,
  RecurrenceFrequency frequency,
  int interval,
  int n,
) {
  final step = n * interval;
  DateTime at(int year, int month, int day) =>
      DateTime(year, month, day, start.hour, start.minute, start.second);
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return at(start.year, start.month, start.day + step);
    case RecurrenceFrequency.weekly:
      return at(start.year, start.month, start.day + 7 * step);
    case RecurrenceFrequency.monthly:
      final first = DateTime(start.year, start.month + step);
      return at(first.year, first.month, _clampDay(first, start.day));
    case RecurrenceFrequency.yearly:
      final first = DateTime(start.year + step, start.month);
      return at(first.year, first.month, _clampDay(first, start.day));
  }
}

int _clampDay(DateTime monthStart, int day) {
  final last = DateTime(monthStart.year, monthStart.month + 1, 0).day;
  return day > last ? last : day;
}

/// The first occurrence strictly after [after].
DateTime nextOccurrenceAfter(
  DateTime start,
  RecurrenceFrequency frequency,
  int interval,
  DateTime after,
) {
  // Jump close first (daily/weekly are exact; months/years estimate), then
  // step forward, so long-running daily rules stay cheap.
  var n = switch (frequency) {
    RecurrenceFrequency.daily => after.difference(start).inDays ~/ interval,
    RecurrenceFrequency.weekly =>
      after.difference(start).inDays ~/ (7 * interval),
    RecurrenceFrequency.monthly =>
      ((after.year - start.year) * 12 + after.month - start.month) ~/ interval,
    RecurrenceFrequency.yearly => (after.year - start.year) ~/ interval,
  };
  if (n < 0) n = 0;
  // Estimates can overshoot by one around clamped days or DST.
  while (n > 0 &&
      occurrence(start, frequency, interval, n - 1).isAfter(after)) {
    n--;
  }
  var next = occurrence(start, frequency, interval, n);
  while (!next.isAfter(after)) {
    n++;
    next = occurrence(start, frequency, interval, n);
  }
  return next;
}

/// Occurrences from [from] (inclusive) up to [until] (exclusive), for a rule
/// whose next unlogged occurrence is [from]. Stops at [end] if set.
Iterable<DateTime> occurrencesBetween(
  RecurringRule rule,
  DateTime until, {
  DateTime? from,
}) sync* {
  var at = from ?? rule.nextDue;
  while (at.isBefore(until) &&
      (rule.endDate == null || !at.isAfter(rule.endDate!))) {
    yield at;
    at = nextOccurrenceAfter(rule.startDate, rule.frequency, rule.interval, at);
  }
}
