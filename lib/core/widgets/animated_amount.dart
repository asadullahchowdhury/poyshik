import 'package:material_ui/material_ui.dart';

import '../money/money.dart';
import 'amount_text.dart';
import 'motion.dart';

/// An [AmountText] whose value rolls smoothly to each new amount.
/// Counts up from zero on first appearance; snaps when motion is reduced.
class AnimatedAmountText extends StatefulWidget {
  const AnimatedAmountText(
    this.amount, {
    super.key,
    this.size = AmountSize.medium,
    this.tone = AmountTone.neutral,
    this.showSign = false,
    this.color,
    this.duration = const Duration(milliseconds: 700),
  });

  final Money amount;
  final AmountSize size;
  final AmountTone tone;
  final bool showSign;
  final Color? color;
  final Duration duration;

  @override
  State<AnimatedAmountText> createState() => _AnimatedAmountTextState();
}

class _AnimatedAmountTextState extends State<AnimatedAmountText> {
  double _from = 0;

  @override
  void didUpdateWidget(AnimatedAmountText old) {
    super.didUpdateWidget(old);
    if (old.amount != widget.amount) _from = old.amount.minor.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.amount.minor.toDouble();
    if (Motion.reduced(context)) return _text(widget.amount);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _from, end: target),
      duration: widget.duration,
      curve: Curves.easeOutQuart,
      builder: (context, v, _) => _text(
        // Land exactly on the target (no rounding drift on the last frame).
        v == target ? widget.amount : Money(v.round()),
      ),
    );
  }

  Widget _text(Money m) => AmountText(
    m,
    size: widget.size,
    tone: widget.tone,
    showSign: widget.showSign,
    color: widget.color,
  );
}
