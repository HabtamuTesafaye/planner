import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// A plain placeholder box shown while content loads. No shimmer: a gentle
/// fade keeps it cheap on low-end devices.
class Skeleton extends StatefulWidget {
  const Skeleton({
    this.width,
    this.height = 16,
    this.radius = AppRadius.control,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  bool _dim = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _toggle());
  }

  void _toggle() {
    if (!mounted) return;
    setState(() => _dim = !_dim);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: AnimatedOpacity(
        opacity: _dim && !reduceMotion ? 0.55 : 1,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        onEnd: reduceMotion ? null : _toggle,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: context.colors.surfaceSunken,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// A few skeleton rows shaped like a list. Announced once as "Loading".
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.rows = 3, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Skeleton(
                  width: AppSizes.checkCircle,
                  height: AppSizes.checkCircle,
                  radius: AppSizes.checkCircle / 2,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: i.isEven ? 0.8 : 0.6,
                    child: const Skeleton(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
