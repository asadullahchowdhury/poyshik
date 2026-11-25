import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';

/// The standard surface: white (or graphite) with a hairline border and
/// no shadow. Tappable when [onTap] is set.
class PoyshikCard extends StatelessWidget {
  const PoyshikCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.xl),
    this.onTap,
    this.color,
    this.radius = Radii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: color ?? c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
