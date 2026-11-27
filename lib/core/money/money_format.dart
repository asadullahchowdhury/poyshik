import 'currency.dart';
import 'money.dart';

/// The pieces of a formatted amount, so widgets can style each part
/// (e.g. a smaller ৳ and muted decimals).
typedef MoneyParts = ({
  String sign,
  String symbol,
  String whole,
  String fraction,
});

/// Formats money in the app currency: ৳1,25,000.50 for taka (South Asian
/// grouping: last three digits, then groups of two), \$125,000.50 for dollars.
abstract final class MoneyFormat {
  /// The app currency. Set from the currency setting (see
  /// currency_provider.dart) before anything is drawn; taka by default.
  static AppCurrency currency = AppCurrency.bdt;

  /// Symbol of the app currency, e.g. for an input's prefix.
  static String get symbol => currency.symbol;

  /// Proper minus sign (U+2212), wider and better aligned than '-'.
  static const minus = '−';

  /// `৳1,25,000` or `৳1,25,000.50`. Decimals appear only when non-zero
  /// unless [alwaysDecimals] is true.
  static String format(
    Money money, {
    bool withSymbol = true,
    bool alwaysDecimals = false,
  }) {
    final p = parts(money, alwaysDecimals: alwaysDecimals);
    return '${p.sign}${withSymbol ? p.symbol : ''}${p.whole}${p.fraction}';
  }

  /// Like [format] but rounded to whole taka (for compact summaries).
  static String formatWhole(Money money, {bool withSymbol = true}) {
    final rounded = Money(((money.minor.abs() + 50) ~/ 100) * 100);
    return format(
      money.isNegative ? -rounded : rounded,
      withSymbol: withSymbol,
    );
  }

  static MoneyParts parts(Money money, {bool alwaysDecimals = false}) {
    final fraction = money.poisha;
    return (
      sign: money.isNegative ? minus : '',
      symbol: currency.prefix,
      whole: switch (currency.grouping) {
        DigitGrouping.southAsian => groupIndian(money.wholeTaka),
        DigitGrouping.western => groupWestern(money.wholeTaka),
      },
      fraction: fraction == 0 && !alwaysDecimals
          ? ''
          : '.${fraction.toString().padLeft(2, '0')}',
    );
  }

  /// 125000 → "125,000".
  static String groupWestern(int value) {
    final s = value.abs().toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  /// 125000 → "1,25,000".
  static String groupIndian(int value) {
    final s = value.abs().toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    return '${groups.join(',')},$last3';
  }
}
