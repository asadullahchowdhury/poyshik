import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';
import 'motion.dart';

/// The Poyshik symbol: a P whose stem ends in a marigold leaf.
/// Same geometry as brand/tools/build-brand.mjs (512 grid).
class PoyshikSymbol extends StatelessWidget {
  const PoyshikSymbol({super.key, this.height = 40, this.ink, this.accent});

  final double height;
  final Color? ink;
  final Color? accent;

  // Tight bounds of the mark on the 512 grid (incl. leaf tip).
  static const _bounds = Rect.fromLTWH(146, 100, 234, 372);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: height,
      width: height * _bounds.width / _bounds.height,
      child: CustomPaint(
        painter: _SymbolPainter(ink ?? c.brand, accent ?? c.accent),
      ),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  _SymbolPainter(this.ink, this.accent);

  final Color ink;
  final Color accent;

  static Path get pBody => Path()
    ..fillType = PathFillType.evenOdd
    ..moveTo(168, 140)
    ..arcToPoint(const Offset(204, 104), radius: const Radius.circular(36))
    ..lineTo(276, 104)
    ..arcToPoint(const Offset(276, 304), radius: const Radius.circular(100))
    ..lineTo(248, 304)
    ..lineTo(248, 320)
    ..lineTo(168, 320)
    ..close()
    ..moveTo(248, 160)
    ..lineTo(274, 160)
    ..arcToPoint(const Offset(274, 248), radius: const Radius.circular(44))
    ..lineTo(248, 248)
    ..close();

  static Path get leaf => Path()
    ..moveTo(248, 334)
    ..cubicTo(250, 394, 220, 440, 150, 468)
    ..cubicTo(158, 430, 168, 392, 168, 334)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    const b = PoyshikSymbol._bounds;
    canvas
      ..scale(size.height / b.height)
      ..translate(-b.left, -b.top)
      ..drawPath(pBody, Paint()..color = ink)
      ..drawPath(leaf, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_SymbolPainter old) =>
      old.ink != ink || old.accent != accent;
}

/// The logo: the symbol is the "P", followed by "oyshik" in the display
/// serif, cap-aligned as in brand/svg/poyshik-logo-p-*.svg.
///
/// With [animate], the P settles in and "oyshik" slides out of it once, the
/// first time the logo is shown (skipped when the OS removes animations).
class PoyshikLogo extends StatefulWidget {
  const PoyshikLogo({
    super.key,
    this.size = 32,
    this.color,
    this.animate = false,
  });

  /// Wordmark font size; the symbol scales with it.
  final double size;
  final Color? color;
  final bool animate;

  @override
  State<PoyshikLogo> createState() => _PoyshikLogoState();
}

class _PoyshikLogoState extends State<PoyshikLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: widget.animate ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.value == 1 || _c.isAnimating) return;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      unawaited(_c.forward());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final ink = widget.color ?? context.colors.brand;
    // The P lands first, then the word unrolls from behind its bowl.
    final mark = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    final word = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
    );

    return Semantics(
      label: 'Poyshik',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(top: size * 0.32),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _c,
                  curve: const Interval(0, 0.3),
                ),
                child: ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.0).animate(mark),
                  alignment: const Alignment(0, 0.2),
                  child: PoyshikSymbol(height: size * 1.24, ink: ink),
                ),
              ),
            ),
            // Tight to the bowl, so the symbol reads as the first letter.
            SizedBox(width: size * 0.02),
            AnimatedBuilder(
              animation: word,
              builder: (context, child) => ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: word.value.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: word.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset((1 - word.value) * -size * 0.6, 0),
                      child: child,
                    ),
                  ),
                ),
              ),
              child: Text(
                'oyshik',
                style: AppType.display.copyWith(
                  fontSize: size,
                  color: ink,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
