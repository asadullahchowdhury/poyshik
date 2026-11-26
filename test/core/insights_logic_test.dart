import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/dates/periods.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/data/db/app_database.dart';
import 'package:poyshik/features/insights/insights_logic.dart';

Category _cat(String name) => Category(
  id: name,
  name: name,
  kind: CategoryKind.expense,
  icon: 'more',
  colorIndex: 0,
  sortOrder: 0,
  isArchived: false,
  systemKey: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  final now = DateTime(2026, 11, 26, 12);

  group('periodRange', () {
    test('month offsets roll across years', () {
      expect(
        periodRange((kind: PeriodKind.month, offset: 0), now).start,
        DateTime(2026, 11),
      );
      expect(
        periodRange((kind: PeriodKind.month, offset: -11), now).start,
        DateTime(2025, 12),
      );
    });

    test('week offsets move by 7 days from a Saturday start', () {
      final r = periodRange((kind: PeriodKind.week, offset: -1), now);
      expect(r.start, DateTime(2026, 11, 14));
      expect(r.end, DateTime(2026, 11, 21));
    });
  });

  test('dailyTotals fills every day, summing entries per local day', () {
    final week = weekRange(now); // Sat 21 – Fri 27
    final daily = dailyTotals(week, [
      (DateTime(2026, 11, 22, 9), const Money(100)),
      (DateTime(2026, 11, 22, 23, 59), const Money(50)),
      (DateTime(2026, 11, 26), const Money(30)),
    ]);
    expect(daily, hasLength(7));
    expect(daily[0], (DateTime(2026, 11, 21), Money.zero));
    expect(daily[1].$2, const Money(150));
    expect(daily[5].$2, const Money(30));
  });

  group('buildInsights', () {
    final month = monthRange(now);

    test('nothing spent gives no insights', () {
      expect(
        buildInsights(
          range: month,
          now: now,
          spent: Money.zero,
          previousSpent: Money.zero,
          categories: const [],
          daily: const [],
        ),
        isEmpty,
      );
    });

    test('top share, change and daily average for the current month', () {
      final insights = buildInsights(
        range: month,
        now: now,
        spent: const Money.taka(26000),
        previousSpent: const Money.taka(20000),
        categories: [(category: _cat('Food'), total: const Money.taka(10400))],
        daily: dailyTotals(month, [
          (DateTime(2026, 11, 3), const Money.taka(26000)),
        ]),
      );
      expect(insights, hasLength(3));
      final top = insights[0] as TopCategoryShare;
      expect((top.categoryName, top.percent), ('Food', 40));
      expect((insights[1] as ChangeVsPrevious).percent, 30);
      // 26 days elapsed in November so far.
      expect((insights[2] as DailyAverage).amount, const Money.taka(1000));
    });

    test('small changes and small shares are skipped', () {
      final insights = buildInsights(
        range: month,
        now: now,
        spent: const Money.taka(1000),
        previousSpent: const Money.taka(980),
        categories: [(category: _cat('Misc'), total: const Money.taka(100))],
        daily: dailyTotals(month, [
          (DateTime(2026, 11, 3), const Money.taka(1000)),
        ]),
      );
      expect(insights.whereType<TopCategoryShare>(), isEmpty);
      expect(insights.whereType<ChangeVsPrevious>(), isEmpty);
      expect(
        insights.whereType<BiggestDay>().single.day,
        DateTime(2026, 11, 3),
      );
    });
  });
}
