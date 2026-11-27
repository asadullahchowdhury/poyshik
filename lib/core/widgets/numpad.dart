import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import '../money/money_format.dart';

/// Custom amount keypad: faster than the system keyboard and always the same
/// size, so the entry sheet never jumps. Keys give light haptic feedback.
class Numpad extends StatelessWidget {
  const Numpad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    this.onClear,
  });

  /// Called with '0'–'9' or '.'.
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  /// Long-press on backspace.
  final VoidCallback? onClear;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: Space.sm),
                  Expanded(child: _key(row[i])),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _key(String key) {
    if (key == '⌫') {
      return _NumpadKey(
        onTap: onBackspace,
        onLongPress: onClear,
        child: const Icon(Icons.backspace_outlined, size: 22),
      );
    }
    return _NumpadKey(
      onTap: () => onKey(key),
      child: Text(MoneyFormat.digits(key)),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surfaceRaised,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          unawaited(HapticFeedback.lightImpact());
          onTap();
        },
        onLongPress: onLongPress == null
            ? null
            : () {
                unawaited(HapticFeedback.mediumImpact());
                onLongPress!();
              },
        child: SizedBox(
          height: 58,
          child: Center(
            child: DefaultTextStyle(
              // Proportional figures read better on keys than tabular ones.
              style: AppType.amountMedium.copyWith(
                fontSize: 24,
                color: c.ink,
                fontWeight: FontWeight.w500,
                fontFeatures: const [],
              ),
              child: IconTheme(
                data: IconThemeData(color: c.ink),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
