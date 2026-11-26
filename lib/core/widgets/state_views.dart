import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import 'motion.dart';

/// Calm placeholder while data loads: soft blocks that gently pulse.
/// Local SQLite is fast, so this usually shows for a frame or two.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget block(double h, {double w = double.infinity}) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
    );
    return Pulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Space.screen),
        children: [
          block(140),
          for (var i = 0; i < rows; i++) ...[
            const SizedBox(height: Space.md),
            block(64),
          ],
        ],
      ),
    );
  }
}

/// Friendly error with the technical detail tucked underneath.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 36, color: c.inkMuted),
            const SizedBox(height: Space.lg),
            Text(
              'Something went wrong loading this.',
              textAlign: TextAlign.center,
              style: AppType.titleMedium.copyWith(color: c.ink),
            ),
            const SizedBox(height: Space.sm),
            Text(
              '$error',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption.copyWith(color: c.inkSubtle),
            ),
          ],
        ),
      ),
    );
  }
}
