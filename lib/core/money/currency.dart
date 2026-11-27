import 'package:flutter/foundation.dart';

/// How digits are grouped: South Asian `1,25,000` or western `125,000`.
enum DigitGrouping { southAsian, western }

/// The one currency the whole app shows amounts in (a setting).
///
/// Amounts are stored as whole minor units (poisha, paise, cents) whatever
/// the currency, so switching changes only how they are displayed; it never
/// converts values.
@immutable
final class AppCurrency {
  const AppCurrency(
    this.code,
    this.symbol, {
    this.grouping = DigitGrouping.western,
    this.spaced = false,
  });

  /// ISO 4217 code, stored in settings and on accounts.
  final String code;
  final String symbol;
  final DigitGrouping grouping;

  /// Letter symbols ("Rs", "AED") read better with a space before the number.
  final bool spaced;

  /// The symbol as printed before an amount.
  String get prefix => spaced ? '$symbol ' : symbol;

  static const bdt = AppCurrency(
    'BDT',
    '৳',
    grouping: DigitGrouping.southAsian,
  );

  @override
  bool operator ==(Object other) => other is AppCurrency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'AppCurrency($code)';
}

/// Currencies offered in Settings. All use two decimal places, which the
/// amount input and storage assume.
const supportedCurrencies = <AppCurrency>[
  AppCurrency.bdt,
  AppCurrency('INR', '₹', grouping: DigitGrouping.southAsian),
  AppCurrency('PKR', 'Rs', grouping: DigitGrouping.southAsian, spaced: true),
  AppCurrency('NPR', 'Rs', grouping: DigitGrouping.southAsian, spaced: true),
  AppCurrency('LKR', 'Rs', spaced: true),
  AppCurrency('USD', r'$'),
  AppCurrency('EUR', '€'),
  AppCurrency('GBP', '£'),
  AppCurrency('AED', 'AED', spaced: true),
  AppCurrency('SAR', 'SAR', spaced: true),
  AppCurrency('MYR', 'RM'),
  AppCurrency('SGD', r'S$'),
];

/// The supported currency with [code], or taka when unknown or unset.
AppCurrency currencyFor(String? code) =>
    supportedCurrencies.where((c) => c.code == code).firstOrNull ??
    AppCurrency.bdt;
