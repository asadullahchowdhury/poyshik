import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';

enum AmountSize { hero, large, medium, small }

enum AmountTone { neutral, expense, income, transfer }

/// Displays a money amount given in poisha (1 ৳ = 100 poisha).
///
/// The number is the hero: the ৳ sign and any decimals are drawn smaller and
/// muted so the whole-taka figure reads first.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amountMinor, {
    super.key,
    this.size = AmountSize.medium,
    this.tone = AmountTone.neutral,
    this.showSign = false,
    this.color,
  });

  /// Amount in poisha. Sign is taken from [tone], not from this value.
  final int amountMinor;
  final AmountSize size;
  final AmountTone tone;

  /// Prefix "−" for expenses and "+" for income.
  final bool showSign;

  /// Overrides the tone color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = switch (size) {
      AmountSize.hero => AppType.amountHero,
      AmountSize.large => AppType.amountLarge,
      AmountSize.medium => AppType.amountMedium,
      AmountSize.small => AppType.amountSmall,
    };
    final mainColor =
        color ??
        switch (tone) {
          AmountTone.neutral => c.ink,
          AmountTone.expense => c.expense,
          AmountTone.income => c.income,
          AmountTone.transfer => c.transfer,
        };
    final minorColor = tone == AmountTone.neutral && color == null
        ? c.inkMuted
        : mainColor.withValues(alpha: 0.7);
    final small = base.copyWith(
      fontSize: base.fontSize! * (size == AmountSize.hero ? 0.55 : 0.75),
      color: minorColor,
      letterSpacing: 0,
    );

    final abs = amountMinor.abs();
    final whole = _groupIndian(abs ~/ 100);
    final fraction = abs % 100;
    final sign = !showSign
        ? ''
        : switch (tone) {
            AmountTone.expense => '−', // proper minus sign
            AmountTone.income => '+',
            _ => '',
          };

    return Text.rich(
      TextSpan(
        style: base.copyWith(color: mainColor),
        children: [
          if (sign.isNotEmpty) TextSpan(text: sign),
          TextSpan(text: '৳', style: small),
          TextSpan(text: whole),
          if (fraction != 0)
            TextSpan(
              text: '.${fraction.toString().padLeft(2, '0')}',
              style: small,
            ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
    );
  }

  // TEMPORARY: replaced by the Money formatter in step 0.5.
  // South Asian grouping: 1,25,000 (last three digits, then pairs).
  static String _groupIndian(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }
}
