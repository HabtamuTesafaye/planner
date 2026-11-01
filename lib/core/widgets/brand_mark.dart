import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// The app mark: a check inside a ring of three arcs (three tasks a day) on
/// a rounded accent tile. Same geometry as the launcher icon and splash
/// (assets/icon/src/make_icons.py), drawn in code so it stays sharp and
/// follows the theme.
///
/// With [animate], it draws itself once: the tile settles in, the three
/// arcs sweep one after another, then the check is drawn. Each piece moves
/// for 250 ms or less; the whole reveal takes 700 ms.
class BrandMark extends StatelessWidget {
  const BrandMark({
    this.size = AppSizes.brandMarkLarge,
    this.animate = false,
    super.key,
  });

  final double size;
  final bool animate;

  static const Duration _reveal = Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final box = Size.square(size);
    if (!animate || AppMotion.reduced(context)) {
      return ExcludeSemantics(
        child: CustomPaint(size: box, painter: _MarkPainter(colors, 1)),
      );
    }
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: _reveal,
        builder: (context, t, _) =>
            CustomPaint(size: box, painter: _MarkPainter(colors, t)),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.colors, this.t);

  final AppColors colors;
  final double t;

  // Fractions of the tile side (keep in sync with make_icons.py).
  static const double _corner = 0.28;
  static const double _ringRadius = 0.30;
  static const double _stroke = 0.075;
  static const double _arcSweep = 100;
  static const double _arcStart = -80;
  static const double _arcStep = 120;
  static const List<Offset> _check = [
    Offset(-0.125, 0.005),
    Offset(-0.035, 0.095),
    Offset(0.13, -0.075),
  ];

  /// Progress of a sub-animation running from [start] to [end] (0..1).
  double _phase(double start, double end) =>
      AppMotion.enter.transform(((t - start) / (end - start)).clamp(0, 1));

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    final center = size.center(Offset.zero);

    // Tile: grows from 85% and fades in.
    final tile = _phase(0, 0.35);
    if (tile <= 0) return;
    final scaled = side * (0.85 + 0.15 * tile);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: scaled, height: scaled),
        Radius.circular(_corner * scaled),
      ),
      Paint()..color = colors.accent.withValues(alpha: tile),
    );

    final ink = Paint()
      ..color = colors.onAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke * side
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Arcs: one after another.
    final ring = Rect.fromCircle(center: center, radius: _ringRadius * side);
    for (var i = 0; i < 3; i++) {
      final start = 0.25 + 0.15 * i;
      final a = _phase(start, start + 0.2);
      if (a <= 0) continue;
      canvas.drawArc(
        ring,
        _rad(_arcStart + _arcStep * i),
        _rad(_arcSweep * a),
        false,
        ink,
      );
    }

    // Check: drawn along its path.
    final k = _phase(0.6, 0.95);
    if (k <= 0) return;
    Offset at(Offset f) => center + f * side;
    final path = Path()
      ..moveTo(at(_check[0]).dx, at(_check[0]).dy)
      ..lineTo(at(_check[1]).dx, at(_check[1]).dy)
      ..lineTo(at(_check[2]).dx, at(_check[2]).dy);
    final drawn = Path();
    for (final metric in path.computeMetrics()) {
      drawn.addPath(metric.extractPath(0, metric.length * k), Offset.zero);
    }
    canvas.drawPath(drawn, ink);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t || old.colors != colors;
}
