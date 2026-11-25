import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/dates/periods.dart';

void main() {
  group('weekRange (Saturday start)', () {
    test('a Wednesday belongs to the week starting the previous Saturday', () {
      // 2026-11-25 is a Wednesday.
      final r = weekRange(DateTime(2026, 11, 25, 15, 30));
      expect(r.start, DateTime(2026, 11, 21)); // Saturday
      expect(r.end, DateTime(2026, 11, 28));
      expect(r.dayCount, 7);
    });

    test('Saturday starts its own week; Friday ends it', () {
      expect(weekRange(DateTime(2026, 11, 21)).start, DateTime(2026, 11, 21));
      expect(
        weekRange(DateTime(2026, 11, 27, 23, 59)).start,
        DateTime(2026, 11, 21),
      );
    });

    test('crosses month and year boundaries', () {
      // 2027-01-01 is a Friday → week started Sat 2026-12-26.
      final r = weekRange(DateTime(2027, 1, 1));
      expect(r.start, DateTime(2026, 12, 26));
      expect(r.end, DateTime(2027, 1, 2));
    });

    test('other start days', () {
      final r = weekRange(DateTime(2026, 11, 25), startDay: DateTime.monday);
      expect(r.start, DateTime(2026, 11, 23));
    });
  });

  group('monthRange', () {
    test('is half-open and covers the calendar month', () {
      final r = monthRange(DateTime(2026, 11, 25));
      expect(r.start, DateTime(2026, 11));
      expect(r.end, DateTime(2026, 12));
      expect(r.dayCount, 30);
      expect(r.contains(DateTime(2026, 11, 30, 23, 59, 59)), isTrue);
      expect(r.contains(DateTime(2026, 12)), isFalse);
      expect(r.contains(DateTime(2026, 11)), isTrue);
    });

    test('December rolls into next year', () {
      final r = monthRange(DateTime(2026, 12, 31));
      expect(r.end, DateTime(2027));
    });

    test('February in leap and non-leap years', () {
      expect(monthRange(DateTime(2028, 2, 10)).dayCount, 29);
      expect(monthRange(DateTime(2027, 2, 10)).dayCount, 28);
    });

    test('previous month, including January', () {
      expect(
        previousMonthRange(DateTime(2026, 11, 25)).start,
        DateTime(2026, 10),
      );
      expect(
        previousMonthRange(DateTime(2027, 1, 5)).start,
        DateTime(2026, 12),
      );
    });

    test('consecutive months tile without gaps', () {
      final nov = monthRange(DateTime(2026, 11));
      final dec = monthRange(DateTime(2026, 12));
      expect(nov.end, dec.start);
    });
  });

  group('day helpers', () {
    test('dayRange and dateOnly', () {
      final r = dayRange(DateTime(2026, 11, 25, 18));
      expect(r.start, DateTime(2026, 11, 25));
      expect(r.end, DateTime(2026, 11, 26));
    });

    test('daysLeftInMonth counts today', () {
      expect(daysLeftInMonth(DateTime(2026, 11, 25, 9)), 6);
      expect(daysLeftInMonth(DateTime(2026, 11, 30, 23)), 1);
      expect(daysLeftInMonth(DateTime(2026, 11)), 30);
    });

    test('sameDayLastMonth clamps to the shorter month', () {
      expect(
        sameDayLastMonth(DateTime(2027, 3, 31, 10)),
        DateTime(2027, 2, 28, 10),
      );
      expect(sameDayLastMonth(DateTime(2028, 3, 31)), DateTime(2028, 2, 29));
      expect(sameDayLastMonth(DateTime(2027, 1, 15)), DateTime(2026, 12, 15));
    });
  });
}
