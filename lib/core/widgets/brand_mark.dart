import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// The app mark: a filled circle with a check (one task done) above three
/// rings (three tasks a day). Same geometry as the launcher icon
/// (assets/icon/src/make_icons.py), drawn in code so it stays sharp and
/// follows the theme.
///
/// With [animate], it draws itself once: the circle grows, the check is
/// drawn, then the rings appear one by one. Each piece moves for about
/// 250 ms; the whole reveal takes 700 ms.
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
    final box = Size(size, size * _MarkPainter.aspect);
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

  // Bounds of the mark in the icon's 1024 grid.
  static const double _left = 319;
  static const double _top = 268;
  static const double _width = 386;
  static const double _height = 478;
  static const double aspect = _height / _width;

  static const Offset _circle = Offset(512, 440);
  static const double _radius = 172;
  static const List<Offset> _check = [
    Offset(450, 444),
    Offset(494, 488),
    Offset(582, 394),
  ];
  static const double _ringY = 700;
  static const double _ringRadius = 38;
  static const double _ringWidth = 15;
  static const double _gap = 148;

  /// Progress of a sub-animation running from [start] to [end] (0..1).
  double _phase(double start, double end) =>
      AppMotion.enter.transform(((t - start) / (end - start)).clamp(0, 1));

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _width;
    canvas
      ..scale(scale)
      ..translate(-_left, -_top);

    // Circle: grows from 60% and fades in.
    final c = _phase(0, 0.36);
    if (c > 0) {
      canvas.drawCircle(
        _circle,
        _radius * (0.6 + 0.4 * c),
        Paint()..color = colors.accent.withValues(alpha: c),
      );
    }

    // Check: drawn along its path.
    final k = _phase(0.25, 0.6);
    if (k > 0) {
      final path = Path()
        ..moveTo(_check[0].dx, _check[0].dy)
        ..lineTo(_check[1].dx, _check[1].dy)
        ..lineTo(_check[2].dx, _check[2].dy);
      final drawn = Path();
      for (final metric in path.computeMetrics()) {
        drawn.addPath(metric.extractPath(0, metric.length * k), Offset.zero);
      }
      canvas.drawPath(
        drawn,
        Paint()
          ..color = colors.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 36
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Rings: one after another.
    for (var i = 0; i < 3; i++) {
      final start = 0.45 + 0.1 * i;
      final r = _phase(start, start + 0.35);
      if (r <= 0) continue;
      canvas.drawCircle(
        Offset(512 + _gap * (i - 1), _ringY),
        _ringRadius * (0.5 + 0.5 * r),
        Paint()
          ..color = colors.text.withValues(alpha: r)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t || old.colors != colors;
}
