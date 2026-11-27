import 'package:flutter/foundation.dart';

import 'currency.dart';

/// An amount of Bangladeshi Taka stored as whole poisha (1 ৳ = 100 poisha).
///
/// Never use `double` for money: binary floating point cannot represent
/// values like 0.1 exactly and totals drift. All arithmetic is on [minor].
@immutable
final class Money implements Comparable<Money> {
  const Money(this.minor);

  /// From whole taka: `Money.taka(250)` is ৳250.
  const Money.taka(int taka) : minor = taka * 100;

  static const zero = Money(0);

  /// Largest amount the app accepts from input: ৳99,99,99,999.99.
  static const max = Money(99999999999);

  /// Amount in poisha.
  final int minor;

  int get wholeTaka => minor.abs() ~/ 100;
  int get poisha => minor.abs() % 100;
  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;
  bool get isPositive => minor > 0;

  Money operator +(Money other) => Money(minor + other.minor);
  Money operator -(Money other) => Money(minor - other.minor);
  Money operator -() => Money(-minor);
  Money abs() => Money(minor.abs());

  /// Splits evenly over [parts], rounding down to whole poisha.
  Money divide(int parts) => Money(minor ~/ parts);

  bool operator <(Money other) => minor < other.minor;
  bool operator >(Money other) => minor > other.minor;
  bool operator <=(Money other) => minor <= other.minor;
  bool operator >=(Money other) => minor >= other.minor;

  @override
  int compareTo(Money other) => minor.compareTo(other.minor);

  @override
  bool operator ==(Object other) => other is Money && other.minor == minor;

  @override
  int get hashCode => minor.hashCode;

  /// Parses user text such as "1,250.50", "৳ 300", "Rs 300", "০৫০" (Bangla
  /// digits).
  /// Returns null for empty, malformed, more than 2 decimals, or > [max].
  static Money? tryParse(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    s = _toAsciiDigits(s);
    for (final symbol in _symbolsLongestFirst) {
      s = s.replaceAll(symbol, '');
    }
    s = s.replaceAll(RegExp(r'[,\s]'), '');
    final negative = s.startsWith('-') || s.startsWith('−');
    if (negative) s = s.substring(1);
    final match = RegExp(r'^(\d+)?(?:\.(\d{0,2}))?$').firstMatch(s);
    if (match == null || (match[1] == null && (match[2] ?? '').isEmpty)) {
      return null;
    }
    final wholeText = match[1] ?? '0';
    if (wholeText.length > 12) return null;
    final whole = int.parse(wholeText);
    final fraction = int.parse((match[2] ?? '').padRight(2, '0'));
    final value = Money(whole * 100 + fraction);
    if (value > max) return null;
    return negative ? -value : value;
  }

  /// Longest first, so "S\$" is removed before "\$".
  static final _symbolsLongestFirst = [
    for (final c in supportedCurrencies) c.symbol,
  ]..sort((a, b) => b.length.compareTo(a.length));

  static String _toAsciiDigits(String s) {
    const bangla = '০১২৩৪৫৬৭৮৯';
    final out = StringBuffer();
    for (final rune in s.runes) {
      final i = bangla.indexOf(String.fromCharCode(rune));
      out.write(i >= 0 ? i.toString() : String.fromCharCode(rune));
    }
    return out.toString();
  }

  @override
  String toString() => 'Money($minor)';
}
