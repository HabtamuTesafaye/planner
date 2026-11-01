import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context.dart';

/// One bar of a [SimpleBarChart].
class BarDatum {
  const BarDatum({
    required this.label,
    required this.value,
    required this.valueText,
  });

  final String label;
  final double value;

  /// How the value reads in words or numbers ("5 tasks", "12,500 ETB").
  final String valueText;
}

/// Single-series vertical bars: thin, rounded at the data end, anchored to
/// one baseline, no grid. The selected bar (last by default) shows its
/// value; tap another bar to read it. No legend: the card title names it.
class SimpleBarChart extends StatefulWidget {
  const SimpleBarChart({
    required this.bars,
    required this.semanticLabel,
    super.key,
  });

  final List<BarDatum> bars;
  final String semanticLabel;

  @override
  State<SimpleBarChart> createState() => _SimpleBarChartState();
}

class _SimpleBarChartState extends State<SimpleBarChart> {
  late int _selected = widget.bars.length - 1;

  @override
  void didUpdateWidget(SimpleBarChart old) {
    super.didUpdateWidget(old);
    if (_selected >= widget.bars.length) _selected = widget.bars.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final bars = widget.bars;
    if (bars.isEmpty) return const SizedBox.shrink();
    final maxValue = bars.map((b) => b.value).fold(0.0, math.max);
    final selected = bars[_selected.clamp(0, bars.length - 1)];
    final duration = AppMotion.of(context, AppDurations.slow);

    return Semantics(
      label:
          '${widget.semanticLabel}: '
          '${bars.map((b) => '${b.label} ${b.valueText}').join(', ')}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${selected.label} · ${selected.valueText}',
            style: text.titleSmall!.copyWith(
              fontFeatures: AppTextStyles.tabular,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSizes.chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, bar) in bars.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSizes.chartGap * 2),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = i),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: duration,
                          curve: AppMotion.enter,
                          height: maxValue == 0
                              ? AppSizes.chartGap
                              : math.max(
                                  AppSizes.chartGap,
                                  AppSizes.chartHeight * bar.value / maxValue,
                                ),
                          decoration: BoxDecoration(
                            // Every bar keeps full contrast; the selection is
                            // shown by the value line and the bold label.
                            color: colors.accent,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppSizes.barRadius),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(height: AppSizes.ringStroke, color: colors.divider),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final (i, bar) in bars.indexed) ...[
                if (i > 0) const SizedBox(width: AppSizes.chartGap * 2),
                Expanded(
                  child: Text(
                    bar.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: text.labelSmall!.copyWith(
                      color: i == _selected ? colors.text : colors.muted,
                      fontWeight: i == _selected ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
