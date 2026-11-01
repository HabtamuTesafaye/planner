import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/thin_progress_bar.dart';
import '../money_logic.dart';

/// The month's total, big, with the target and a thin progress bar.
class MoneyHero extends StatelessWidget {
  const MoneyHero({
    required this.month,
    required this.totalCents,
    required this.targetCents,
    required this.onEditTarget,
    super.key,
  });

  final DateTime month;
  final int totalCents;
  final int? targetCents;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    final total = Money.etb(totalCents / 100);
    final progress = targetProgress(totalCents, targetCents);
    final monthName = DateFormat.yMMMM().format(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(monthName, style: text.labelMedium!.copyWith(color: colors.muted)),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          label: 'Income this month: $total',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(total, style: text.displayLarge),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (targetCents == null)
          TextButton(
            onPressed: onEditTarget,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('Set a monthly target'),
          )
        else ...[
          ThinProgressBar(
            value: progress,
            semanticLabel: 'Progress toward the monthly target',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  progress >= 1
                      ? 'Target reached · ${Money.etb(targetCents! / 100)}'
                      : '${(progress * 100).floor()}% of '
                            '${Money.etb(targetCents! / 100)}',
                  style: text.bodyMedium!.copyWith(
                    color: progress >= 1 ? colors.success : colors.muted,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEditTarget,
                child: const Text('Edit target'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
