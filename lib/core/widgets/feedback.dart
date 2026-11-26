import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import 'motion.dart';

/// A check mark that pops in once: confirms a save without being loud.
class SuccessCheck extends StatelessWidget {
  const SuccessCheck({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
      child: Icon(Icons.check_rounded, size: size * 0.7, color: c.onAccent),
    );
    if (Motion.reduced(context)) return circle;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(
        scale: v,
        child: Opacity(opacity: ((v - 0.4) / 0.6).clamp(0, 1), child: child),
      ),
      child: circle,
    );
  }
}

/// Standard confirmation snackbar: animated check + message (+ optional
/// action such as Undo).
SnackBar successSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  return SnackBar(
    content: Row(
      children: [
        const SuccessCheck(),
        const SizedBox(width: Space.md),
        Expanded(child: Text(message)),
      ],
    ),
    action: action,
  );
}
