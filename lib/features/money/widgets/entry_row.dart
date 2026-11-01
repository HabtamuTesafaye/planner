import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/income.dart';

/// One income entry: amount, note, who added it and when. Swipe to delete.
class EntryRow extends StatelessWidget {
  const EntryRow({
    required this.entry,
    required this.addedBy,
    required this.onDelete,
    super.key,
  });

  final IncomeEntry entry;
  final String? addedBy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final meta = [
      ?addedBy,
      DateFormat.MMMd().format(entry.createdAt),
    ].join(' · ');
    return Dismissible(
      key: ValueKey('entry-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colors.surfaceSunken,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Icon(Symbols.delete, color: colors.attention),
      ),
      onUpdate: (d) {
        if (d.reached && !d.previousReached) {
          unawaited(HapticFeedback.selectionClick());
        }
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.note.isEmpty ? 'Income' : entry.note,
                    style: text.bodyLarge,
                  ),
                  Text(meta, style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              Money.etb(entry.amount),
              style: text.titleMedium!.copyWith(
                fontFeatures: AppTextStyles.tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
