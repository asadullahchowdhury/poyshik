import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';

enum ButtonTone { ink, accent }

/// Full-width main action. Ink by default; [ButtonTone.accent] is reserved
/// for the single most important action on a screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = ButtonTone.ink,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = tone == ButtonTone.accent
        ? FilledButton.styleFrom(
            backgroundColor: c.accent,
            foregroundColor: c.onAccent,
          )
        : null;
    final text = Text(label);
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: text)
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 20),
            label: text,
          );
  }
}
