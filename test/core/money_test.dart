import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/amount_input.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/core/money/money_format.dart';

void main() {
  group('Money arithmetic', () {
    test('is exact where doubles are not', () {
      // 0.1 + 0.2 != 0.3 in doubles; in poisha it is exact.
      expect(const Money(10) + const Money(20), const Money(30));
      var total = Money.zero;
      for (var i = 0; i < 1000; i++) {
        total += const Money(1);
      }
      expect(total, const Money.taka(10));
    });

    test('taka constructor and parts', () {
      const m = Money(125050);
      expect(m.wholeTaka, 1250);
      expect(m.poisha, 50);
      expect(const Money.taka(5).minor, 500);
    });

    test('divide rounds down to whole poisha', () {
      expect(const Money.taka(100).divide(3), const Money(3333));
    });
  });

  group('Money.tryParse', () {
    final cases = <String, int?>{
      '1250': 125000,
      '1,250.50': 125050,
      '৳ 300': 30000,
      '0.5': 50,
      '.75': 75,
      '12.': 1200,
      '০৫০': 5000, // Bangla digits
      '১,২৫,০০০': 12500000,
      '-20': -2000,
      '': null,
      '.': null,
      'abc': null,
      '1.234': null, // more than 2 decimals
      '1.2.3': null,
      '9999999999999': null, // over max
    };
    cases.forEach((input, expected) {
      test('"$input" → $expected', () {
        expect(Money.tryParse(input)?.minor, expected);
      });
    });
  });

  group('MoneyFormat', () {
    test('lakh grouping', () {
      expect(MoneyFormat.groupIndian(0), '0');
      expect(MoneyFormat.groupIndian(999), '999');
      expect(MoneyFormat.groupIndian(1000), '1,000');
      expect(MoneyFormat.groupIndian(100000), '1,00,000');
      expect(MoneyFormat.groupIndian(12345678), '1,23,45,678');
    });

    test('format hides .00, shows real decimals, uses minus sign', () {
      expect(MoneyFormat.format(const Money.taka(125000)), '৳1,25,000');
      expect(MoneyFormat.format(const Money(105)), '৳1.05');
      expect(MoneyFormat.format(const Money(-2550)), '−৳25.50');
      expect(
        MoneyFormat.format(const Money.taka(5), alwaysDecimals: true),
        '৳5.00',
      );
      expect(MoneyFormat.format(const Money.taka(5), withSymbol: false), '5');
    });

    test('formatWhole rounds half up to whole taka', () {
      expect(MoneyFormat.formatWhole(const Money(12549)), '৳125');
      expect(MoneyFormat.formatWhole(const Money(12550)), '৳126');
      expect(MoneyFormat.formatWhole(const Money(-12550)), '−৳126');
    });
  });

  group('AmountInput', () {
    AmountInput type(String keys) {
      var input = const AmountInput();
      for (final k in keys.split('')) {
        input = input.press(k);
      }
      return input;
    }

    test('builds amounts from key presses', () {
      expect(type('1250').value, const Money.taka(1250));
      expect(type('12.5').value, const Money(1250));
      expect(type('12.').value, const Money.taka(12));
    });

    test('blocks leading zeros, second dot and third decimal', () {
      expect(type('007').text, '7');
      expect(type('1.2.3').text, '1.23');
      expect(type('1.234').text, '1.23');
      expect(type('.5').text, '0.5');
    });

    test('caps whole digits at 9', () {
      expect(type('1234567890').text, '123456789');
    });

    test('backspace and clear', () {
      expect(type('125').backspace().text, '12');
      expect(const AmountInput().backspace().text, '');
      expect(type('125').clear().isEmpty, isTrue);
    });
  });
}
