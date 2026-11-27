import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/features/home/forecast.dart';

/// One expense of [taka] at noon on each listed day of November 2026.
List<(DateTime, Money)> _days(Map<int, int> takaByDay) => [
  for (final e in takaByDay.entries)
    (DateTime(2026, 11, e.key, 12), Money.taka(e.value)),
];

void main() {
  test('needs a few days of data and some spending', () {
    expect(
      forecastMonth(entries: _days({1: 500}), now: DateTime(2026, 11, 3, 20)),
      isNull,
    );
    expect(
      forecastMonth(entries: const [], now: DateTime(2026, 11, 20, 20)),
      isNull,
    );
  });

  test('steady pace projects across the rest of the month', () {
    // 10 completed days at ৳1,000; it is the 11th, nothing yet today.
    final f = forecastMonth(
      entries: _days({for (var d = 1; d <= 10; d++) d: 1000}),
      now: DateTime(2026, 11, 11, 9),
    )!;
    expect(f.pace, const Money.taka(1000));
    // ৳10,000 spent + 20 more days (11th..30th) at ৳1,000.
    expect(f.total, const Money.taka(30000));
    expect(f.over, Money.zero);
    expect(f.crossesOn, isNull);
  });

  test('a one-off big day is counted once, not repeated', () {
    final f = forecastMonth(
      entries: _days({
        for (var d = 1; d <= 10; d++) d: 1000,
        1: 15000, // rent on the 1st
      }),
      now: DateTime(2026, 11, 11, 9),
    )!;
    // Pace ignores most of the rent day (capped at 3× the median).
    expect(f.pace, const Money.taka(1200));
    // Everything already spent is kept: ৳24,000 + 20 days × ৳1,200.
    expect(f.total, const Money.taka(48000));
  });

  test('flags the overspend and roughly when the budget runs out', () {
    final f = forecastMonth(
      entries: _days({for (var d = 1; d <= 10; d++) d: 1000}),
      now: DateTime(2026, 11, 11, 9),
      budget: const Money.taka(25000),
    )!;
    expect(f.over, const Money.taka(5000));
    // ৳15,000 left at ৳1,000/day → runs out on the 25th.
    expect(f.crossesOn, DateTime(2026, 11, 25));
  });

  test('scheduled bills are added; already over budget crosses today', () {
    final f = forecastMonth(
      entries: _days({for (var d = 1; d <= 10; d++) d: 3000}),
      now: DateTime(2026, 11, 11, 9),
      budget: const Money.taka(20000),
      scheduled: const Money.taka(2000),
    )!;
    expect(f.total, const Money.taka(30000 + 60000 + 2000));
    expect(f.crossesOn, DateTime(2026, 11, 11));
  });

  test("today's spending counts toward a normal day", () {
    final f = forecastMonth(
      entries: _days({for (var d = 1; d <= 11; d++) d: 1000}),
      now: DateTime(2026, 11, 11, 20),
    )!;
    // Today already had its ৳1,000, so nothing extra for today.
    expect(f.total, const Money.taka(11000 + 19000));
  });
}
