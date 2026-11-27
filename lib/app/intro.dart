import 'package:material_ui/material_ui.dart';

import '../core/widgets/motion.dart';
import '../core/widgets/poyshik_logo.dart';
import 'theme/theme.dart';

/// The opening moment, played once per launch over the first screen.
///
/// The native launch screen is the bare app background (see
/// android/app/src/main/res/values-v31/styles.xml), so this picks up on the
/// same colour: a soft marigold bloom opens, the P lands and "oyshik" slides
/// out of it, then the whole layer lifts away to reveal the app. Skipped
/// entirely when the OS asks for reduced motion.
class AppIntro extends StatefulWidget {
  const AppIntro({super.key, required this.child});

  final Widget child;

  @override
  State<AppIntro> createState() => _AppIntroState();
}

class _AppIntroState extends State<AppIntro>
    with SingleTickerProviderStateMixin {
  static const _length = Duration(milliseconds: 2000);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _length,
  )..addStatusListener(_onStatus);
  bool _done = false;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _done = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done || _c.isAnimating) return;
    if (Motion.reduced(context)) {
      _done = true;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final bloom = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.02, 0.6, curve: Curves.easeOutCubic),
    );
    final leave = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.74, 1, curve: Curves.easeInOutCubic),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // The app settles up into place as the intro lifts away.
        AnimatedBuilder(
          animation: leave,
          builder: (context, child) =>
              Transform.scale(scale: 0.97 + 0.03 * leave.value, child: child),
          child: widget.child,
        ),
        // The app keeps its place in the tree when the intro is removed, so
        // nothing below it rebuilds from scratch.
        if (!_done)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, logo) => Opacity(
                opacity: 1 - leave.value,
                // Material gives the logo text a default style: the intro
                // sits above the app's own Material widgets.
                child: Material(
                  color: c.background,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // A slow marigold bloom behind the mark.
                      Opacity(
                        opacity:
                            (bloom.value * 2).clamp(0.0, 1.0) *
                            (1 - bloom.value * 0.6),
                        child: Transform.scale(
                          scale: 0.4 + bloom.value * 1.1,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  c.accent.withValues(alpha: 0.34),
                                  c.accent.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -14 * leave.value),
                        child: Transform.scale(
                          scale: 1 + 0.06 * leave.value,
                          child: logo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: const PoyshikLogo(size: 46, animate: true),
            ),
          ),
      ],
    );
  }
}
