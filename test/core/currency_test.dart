import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/money/currency.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/core/money/money_format.dart';

void main() {
  tearDown(() => MoneyFormat.currency = AppCurrency.bdt);

  test('western grouping', () {
    expect(MoneyFormat.groupWestern(0), '0');
    expect(MoneyFormat.groupWestern(999), '999');
    expect(MoneyFormat.groupWestern(1000), '1,000');
    expect(MoneyFormat.groupWestern(12345678), '12,345,678');
  });

  test('formatting follows the app currency', () {
    const amount = Money(12500050);
    expect(MoneyFormat.format(amount), '৳1,25,000.50');

    MoneyFormat.currency = currencyFor('USD');
    expect(MoneyFormat.format(amount), r'$125,000.50');
    expect(MoneyFormat.format(-amount), r'−$125,000.50');

    MoneyFormat.currency = currencyFor('INR');
    expect(MoneyFormat.format(amount), '₹1,25,000.50');

    MoneyFormat.currency = currencyFor('PKR');
    expect(MoneyFormat.format(amount), 'Rs 1,25,000.50');
    expect(MoneyFormat.format(amount, withSymbol: false), '1,25,000.50');
  });

  test('parsing ignores any supported symbol', () {
    expect(Money.tryParse('Rs 300'), const Money.taka(300));
    expect(Money.tryParse(r'S$12.5'), const Money(1250));
    expect(Money.tryParse(r'$1,000'), const Money.taka(1000));
    expect(Money.tryParse('€ 20'), const Money.taka(20));
  });

  test('unknown or missing codes fall back to taka', () {
    expect(currencyFor(null), AppCurrency.bdt);
    expect(currencyFor('XYZ'), AppCurrency.bdt);
    expect(currencyFor('EUR').symbol, '€');
    expect(
      supportedCurrencies.map((c) => c.code).toSet(),
      hasLength(supportedCurrencies.length),
    );
  });
}
