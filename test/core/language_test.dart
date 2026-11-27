import 'package:flutter_test/flutter_test.dart';
import 'package:poyshik/core/locale/language_provider.dart';
import 'package:poyshik/core/money/money.dart';
import 'package:poyshik/core/money/money_format.dart';

void main() {
  tearDown(() => MoneyFormat.bengaliDigits = false);

  test('amounts use Bangla numerals when the app is in Bangla', () {
    const amount = Money(12500050);
    expect(MoneyFormat.format(amount), '৳1,25,000.50');

    MoneyFormat.bengaliDigits = true;
    expect(MoneyFormat.format(amount), '৳১,২৫,০০০.৫০');
    expect(MoneyFormat.formatWhole(amount), '৳১,২৫,০০১');
    expect(MoneyFormat.digits('83%'), '৮৩%');
  });

  test('typed Bangla numerals still parse', () {
    expect(Money.tryParse('৳ ১,২৫০.৫০'), const Money(125050));
  });

  test('language setting round-trips and defaults to the phone', () {
    for (final l in AppLanguage.values) {
      expect(AppLanguage.fromSetting(l.name), l);
    }
    expect(AppLanguage.fromSetting(null), AppLanguage.system);
    expect(AppLanguage.fromSetting('xx'), AppLanguage.system);
    expect(AppLanguage.bn.locale?.languageCode, 'bn');
    expect(AppLanguage.system.locale, isNull);
  });
}
