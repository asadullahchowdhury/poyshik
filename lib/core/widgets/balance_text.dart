import 'package:material_ui/material_ui.dart';

import '../money/money.dart';
import 'amount_text.dart';

/// A balance: neutral when zero or positive, coral with "−" when negative
/// (e.g. a credit card or an overdrawn wallet).
class BalanceText extends StatelessWidget {
  const BalanceText(this.balance, {super.key, this.size = AmountSize.medium});

  final Money balance;
  final AmountSize size;

  @override
  Widget build(BuildContext context) {
    return AmountText(
      balance.abs(),
      size: size,
      tone: balance.isNegative ? AmountTone.expense : AmountTone.neutral,
      showSign: balance.isNegative,
    );
  }
}
