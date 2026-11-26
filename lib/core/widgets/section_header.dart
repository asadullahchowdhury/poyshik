import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';

/// Small uppercase label above a group of content, with an optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.md),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppType.overline.copyWith(color: context.colors.inkMuted),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A text action for section headers ("See all").
class SectionAction extends StatelessWidget {
  const SectionAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.xs,
          vertical: Space.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppType.label.copyWith(
                color: c.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.brand),
          ],
        ),
      ),
    );
  }
}
