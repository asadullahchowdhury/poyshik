import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../money/money.dart';
import '../money/money_format.dart';

enum AmountSize { hero, large, medium, small }

enum AmountTone { neutral, expense, income, transfer }

/// Displays a [Money] amount.
///
/// The number is the hero: the ৳ sign and any decimals are drawn smaller and
/// muted so the whole-taka figure reads first.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.size = AmountSize.medium,
    this.tone = AmountTone.neutral,
    this.showSign = false,
    this.color,
  });

  /// Shown as an absolute value; the sign comes from [tone] and [showSign].
  final Money amount;
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

    final p = MoneyFormat.parts(amount.abs());
    final sign = !showSign
        ? ''
        : switch (tone) {
            AmountTone.expense => MoneyFormat.minus,
            AmountTone.income => '+',
            _ => '',
          };

    return Text.rich(
      TextSpan(
        style: base.copyWith(color: mainColor),
        children: [
          if (sign.isNotEmpty) TextSpan(text: sign),
          TextSpan(text: p.symbol, style: small),
          TextSpan(text: p.whole),
          if (p.fraction.isNotEmpty) TextSpan(text: p.fraction, style: small),
        ],
      ),
      maxLines: 1,
      softWrap: false,
    );
  }
}
