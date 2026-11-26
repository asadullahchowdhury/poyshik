import 'package:material_ui/material_ui.dart';

import '../../app/theme/theme.dart';

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

/// Symbol + "Poyshik" wordmark, cap-aligned as in the brand lockup.
class PoyshikLogo extends StatelessWidget {
  const PoyshikLogo({super.key, this.size = 32, this.color});

  /// Wordmark font size; the symbol scales with it.
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.colors.brand;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: size * 0.32),
          child: PoyshikSymbol(height: size * 1.24, ink: ink),
        ),
        SizedBox(width: size * 0.3),
        Text(
          'Poyshik',
          style: AppType.display.copyWith(
            fontSize: size,
            color: ink,
            height: 1,
          ),
        ),
      ],
    );
  }
}
