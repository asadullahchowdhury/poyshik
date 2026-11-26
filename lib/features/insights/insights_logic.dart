import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates/periods.dart';
import '../../core/money/money.dart';
import '../home/summary_repository.dart';

enum PeriodKind { week, month }

/// Which period Insights shows: the current week/month ([offset] 0) or one
/// before it ([offset] −1, −2, …).
typedef InsightsPeriod = ({PeriodKind kind, int offset});

DateRange periodRange(InsightsPeriod p, DateTime now) {
  return switch (p.kind) {
    PeriodKind.month => monthRange(DateTime(now.year, now.month + p.offset)),
    PeriodKind.week => weekRange(
      DateTime(now.year, now.month, now.day + 7 * p.offset),
    ),
  };
}

class InsightsPeriodNotifier extends Notifier<InsightsPeriod> {
  @override
  InsightsPeriod build() => (kind: PeriodKind.month, offset: 0);

  void setKind(PeriodKind kind) => state = (kind: kind, offset: 0);
  void previous() => state = (kind: state.kind, offset: state.offset - 1);
  void next() {
    if (state.offset < 0) state = (kind: state.kind, offset: state.offset + 1);
  }
}

final insightsPeriodProvider =
    NotifierProvider<InsightsPeriodNotifier, InsightsPeriod>(
      InsightsPeriodNotifier.new,
    );

/// One total per calendar day of [range], including days with nothing.
List<(DateTime, Money)> dailyTotals(
  DateRange range,
  List<(DateTime, Money)> entries,
) {
  final totals = <DateTime, Money>{};
  for (final (at, amount) in entries) {
    final day = dateOnly(at);
    totals[day] = (totals[day] ?? Money.zero) + amount;
  }
  return [
    for (var i = 0; i < range.dayCount; i++)
      () {
        final day = DateTime(
          range.start.year,
          range.start.month,
          range.start.day + i,
        );
        return (day, totals[day] ?? Money.zero);
      }(),
  ];
}

/// A plain-language observation. The UI turns each into a sentence.
sealed class Insight {
  const Insight();
}

final class TopCategoryShare extends Insight {
  const TopCategoryShare(this.categoryName, this.percent);
  final String categoryName;
  final int percent;
}

final class BiggestDay extends Insight {
  const BiggestDay(this.day, this.amount);
  final DateTime day;
  final Money amount;
}

final class DailyAverage extends Insight {
  const DailyAverage(this.amount);
  final Money amount;
}

final class ChangeVsPrevious extends Insight {
  const ChangeVsPrevious(this.percent);

  /// Positive = spent more than the previous period.
  final int percent;
}

/// Picks the most useful observations for a period (at most 3).
List<Insight> buildInsights({
  required DateRange range,
  required DateTime now,
  required Money spent,
  required Money previousSpent,
  required List<CategoryTotal> categories,
  required List<(DateTime, Money)> daily,
}) {
  if (!spent.isPositive) return const [];
  final out = <Insight>[];

  if (categories.isNotEmpty) {
    final top = categories.first;
    final share = (top.total.minor * 100 / spent.minor).round();
    if (share >= 20) out.add(TopCategoryShare(top.category.name, share));
  }

  final change = percentChange(spent, previousSpent);
  if (change != null && change.abs() >= 5) out.add(ChangeVsPrevious(change));

  // Days so far: the whole range for past periods, up to today otherwise.
  final elapsed = range.contains(now)
      ? calendarDaysBetween(range.start, now) + 1
      : range.dayCount;
  if (elapsed > 1) out.add(DailyAverage(spent.divide(elapsed)));

  final biggest = daily.fold<(DateTime, Money)?>(
    null,
    (best, d) => best == null || d.$2 > best.$2 ? d : best,
  );
  if (biggest != null && biggest.$2.isPositive && daily.length > 1) {
    out.add(BiggestDay(biggest.$1, biggest.$2));
  }

  return out.take(3).toList();
}
