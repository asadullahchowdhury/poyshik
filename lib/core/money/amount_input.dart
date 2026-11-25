import 'package:flutter/foundation.dart';

import 'money.dart';

/// Pure state for typing an amount on the [Numpad]. Immutable: each key
/// returns a new value. Rules: max 2 decimals, max 9 whole digits
/// (stays within [Money.max]), no leading zeros, a single decimal point.
@immutable
final class AmountInput {
  const AmountInput([this.text = '']);

  static const _maxWholeDigits = 9;

  /// What the user typed, e.g. "1250.5".
  final String text;

  bool get isEmpty => text.isEmpty;

  Money get value =>
      Money.tryParse(text.endsWith('.') ? '${text}0' : text) ?? Money.zero;

  /// Applies a key: '0'–'9' or '.'.
  AmountInput press(String key) {
    if (key == '.') {
      if (text.contains('.')) return this;
      return AmountInput(text.isEmpty ? '0.' : '$text.');
    }
    if (key.length != 1 || !'0123456789'.contains(key)) return this;
    final dot = text.indexOf('.');
    if (dot != -1) {
      if (text.length - dot > 2) return this; // already 2 decimals
      return AmountInput('$text$key');
    }
    if (text == '0') return AmountInput(key); // no leading zeros
    if (text.length >= _maxWholeDigits) return this;
    return AmountInput('$text$key');
  }

  AmountInput backspace() =>
      isEmpty ? this : AmountInput(text.substring(0, text.length - 1));

  AmountInput clear() => const AmountInput();

  @override
  bool operator ==(Object other) => other is AmountInput && other.text == text;

  @override
  int get hashCode => text.hashCode;
}
