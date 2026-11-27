import '../../core/dates/periods.dart';
import '../../core/money/money.dart';

/// Where this month's spending is heading if the current pace holds.
typedef MonthForecast = ({
  /// Projected spending by the last day of the month.
  Money total,

  /// Typical spending per day so far (one-off big days softened).
  Money pace,

  /// Projected overspend against [budget]; zero when on track.
  Money over,

  /// Roughly when spending crosses the budget, if it will this month.
  DateTime? crossesOn,
});

/// Days of data needed before a projection is worth showing.
const forecastMinDays = 5;

/// Projects month-end spending from [entries] (this month's expenses).
///
/// The pace is the average of *completed* days, with any single day capped
/// at three times the median day: rent or a phone purchase happens once, so
/// it counts in what's spent but isn't repeated in the projection. Today is
/// partial, so it adds whatever of a normal day is still to come.
/// [scheduled] is spending already known for later this month (recurring
/// bills not yet logged); it is added on top.
///
/// Returns null until [forecastMinDays] days of the month have passed, or
/// when nothing has been spent.
MonthForecast? forecastMonth({
  required List<(DateTime, Money)> entries,
  required DateTime now,
  Money? budget,
  Money scheduled = Money.zero,
}) {
  final month = monthRange(now);
  final elapsed = calendarDaysBetween(month.start, now); // completed days
  if (elapsed < forecastMinDays) return null;

  final perDay = List<int>.filled(elapsed + 1, 0);
  var spent = 0;
  for (final (at, amount) in entries) {
    if (!month.contains(at) || at.isAfter(now)) continue;
    spent += amount.minor;
    final day = calendarDaysBetween(month.start, at);
    if (day >= 0 && day < perDay.length) perDay[day] += amount.minor;
  }
  if (spent == 0) return null;

  final completed = perDay.sublist(0, elapsed);
  final sorted = [...completed]..sort();
  final median = sorted[sorted.length ~/ 2];
  final cap = median == 0 ? null : median * 3;
  final routine = completed.fold<int>(
    0,
    (sum, d) => sum + (cap == null ? d : (d > cap ? cap : d)),
  );
  final pace = routine ~/ elapsed;

  final today = perDay[elapsed];
  final restOfToday = pace > today ? pace - today : 0;
  final daysAfterToday = calendarDaysBetween(now, month.end) - 1;
  final total = spent + restOfToday + pace * daysAfterToday + scheduled.minor;

  var over = 0;
  DateTime? crossesOn;
  if (budget != null && budget.isPositive && total > budget.minor) {
    over = total - budget.minor;
    if (spent >= budget.minor) {
      crossesOn = dateOnly(now);
    } else if (pace > 0) {
      final daysUntil = ((budget.minor - spent) / pace).ceil();
      final day = dateOnly(now).add(Duration(days: daysUntil - 1));
      crossesOn = day.isBefore(month.end) ? day : null;
    }
  }
  // A projection, so whole taka: paisa would be false precision.
  int taka(int minor) => (minor / 100).round() * 100;
  return (
    total: Money(taka(total)),
    pace: Money(taka(pace)),
    over: Money(taka(over)),
    crossesOn: crossesOn,
  );
}
