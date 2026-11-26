import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import 'motion.dart';

/// The standard surface: cream with a hairline border and no shadow.
/// Tappable cards get a subtle press-scale. [elevated] adds the single soft
/// brand shadow, reserved for feature surfaces (e.g. the dashboard hero).
class PoyshikCard extends StatelessWidget {
  const PoyshikCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.xl),
    this.onTap,
    this.color,
    this.radius = Radii.lg,
    this.elevated = false,
    this.bordered = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final bool elevated;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: bordered ? BorderSide(color: c.hairline) : BorderSide.none,
    );
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                  spreadRadius: -8,
                ),
              ]
            : null,
      ),
      child: Material(
        color: color ?? c.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null ? card : Pressable(child: card);
  }
}
