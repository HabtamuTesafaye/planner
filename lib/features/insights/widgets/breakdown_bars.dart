import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context.dart';

/// Labelled horizontal bars in one hue (a count per category, such as leads
/// per status). Every row names its category and value in text, so color
/// never carries meaning alone.
class BreakdownBars extends StatelessWidget {
  const BreakdownBars({
    required this.rows,
    required this.semanticLabel,
    super.key,
  });

  final List<({String label, int count})> rows;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final max = rows.fold(0, (m, r) => r.count > m ? r.count : m);
    return Semantics(
      label:
          '$semanticLabel: ${rows.map((r) => '${r.label} ${r.count}').join(', ')}',
      excludeSemantics: true,
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(r.label, style: text.bodyMedium, maxLines: 1),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.barRadius),
                      child: SizedBox(
                        height: AppSizes.progressBar * 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: AppMotion.of(context, AppDurations.slow),
                            curve: AppMotion.enter,
                            widthFactor: max == 0 ? 0 : r.count / max,
                            heightFactor: 1,
                            child: ColoredBox(color: colors.accent),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: AppSizes.touchTarget / 2,
                    child: Text(
                      '${r.count}',
                      textAlign: TextAlign.end,
                      style: text.labelMedium!.copyWith(
                        fontFeatures: AppTextStyles.tabular,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
