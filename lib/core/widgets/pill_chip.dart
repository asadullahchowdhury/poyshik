import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';

/// The one pill-shaped chip used for choices, filters and quick fields.
/// Selected chips use the brand colour; others sit on a raised fill.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onBrand : c.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? c.brand : c.surfaceRaised,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md + 2,
                vertical: Space.sm + 1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: Space.xs + 2),
                  ],
                  Text(label, style: AppType.label.copyWith(color: fg)),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: Space.xs),
                    Icon(trailingIcon, size: 18, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
