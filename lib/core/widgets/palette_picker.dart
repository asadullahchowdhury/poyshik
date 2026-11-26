import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';

/// Pick one of the 12 palette colors (stored as an index).
class PalettePicker extends StatelessWidget {
  const PalettePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: Space.sm + 2,
      runSpacing: Space.sm + 2,
      children: [
        for (var i = 0; i < PoyshikColors.categoryPalette.length; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == i ? c.ink : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: PoyshikColors.categoryPalette[i],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
