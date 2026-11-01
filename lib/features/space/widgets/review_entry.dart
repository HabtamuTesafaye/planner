import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../review/providers/review_providers.dart';

/// "Weekly review" row: written or not, tap to open.
class ReviewEntry extends ConsumerWidget {
  const ReviewEntry({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final written = ref.watch(myCurrentReviewProvider)?.isEmpty == false;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Material(
        color: written ? colors.surface : colors.accentSoft,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.controlAll,
          side: BorderSide(color: written ? colors.divider : colors.accent),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  written ? Symbols.task_alt : Symbols.edit_note,
                  color: written ? colors.success : colors.accentText,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly review', style: context.text.titleSmall),
                      Text(
                        written
                            ? 'Written for this week. Tap to edit or read others.'
                            : 'Two minutes, three questions.',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Symbols.chevron_right, color: colors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
