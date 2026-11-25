import 'money.dart';

/// The pieces of a formatted amount, so widgets can style each part
/// (e.g. a smaller ৳ and muted decimals).
typedef MoneyParts = ({
  String sign,
  String symbol,
  String whole,
  String fraction,
});

/// Formats money the way people in Bangladesh read it: ৳1,25,000.50
/// (South Asian grouping: last three digits, then groups of two).
abstract final class MoneyFormat {
  static const symbol = '৳';

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
      symbol: symbol,
      whole: groupIndian(money.wholeTaka),
      fraction: fraction == 0 && !alwaysDecimals
          ? ''
          : '.${fraction.toString().padLeft(2, '0')}',
    );
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
