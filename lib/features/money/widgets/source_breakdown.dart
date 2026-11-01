import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/thin_progress_bar.dart';

/// This month's income per source: name and amount, with a thin bar
/// relative to the largest source. Shown only when there are two or more.
class SourceBreakdown extends StatelessWidget {
  const SourceBreakdown({required this.rows, super.key});

  final List<({String label, int cents})> rows;

  @override
  Widget build(BuildContext context) {
    final max = rows.isEmpty ? 0 : rows.first.cents;
    final text = context.text;
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.label,
                        style: text.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      Money.etb(r.cents / 100),
                      style: text.titleSmall!.copyWith(
                        fontFeatures: AppTextStyles.tabular,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ThinProgressBar(
                  value: max == 0 ? 0 : r.cents / max,
                  semanticLabel:
                      '${r.label}: ${Money.etb(r.cents / 100)} this month',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
