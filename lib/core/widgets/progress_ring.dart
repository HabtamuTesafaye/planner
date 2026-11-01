import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';

/// A thin ring that fills as tasks are done, with "1/3" in the middle.
/// Animates when the count changes (≤ 250 ms).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.done,
    required this.total,
    required this.semanticLabel,
    this.size = AppSizes.progressRing,
    super.key,
  });

  final int done;
  final int total;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: AppMotion.of(context, AppDurations.slow),
          curve: AppMotion.enter,
          builder: (context, v, child) => CustomPaint(
            painter: _RingPainter(
              value: v,
              track: colors.surfaceSunken,
              fill: colors.success,
            ),
            child: child,
          ),
          child: Center(
            child: Text(
              '$done/$total',
              style: context.text.titleSmall!.copyWith(
                fontFeatures: AppTextStyles.tabular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.fill});

  final double value;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppSizes.progressRingStroke;
    final rect = Offset.zero & size;
    final circle = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(circle, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        circle,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track || old.fill != fill;
}
