import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/card_material.dart';
import '../../today/widgets/day_progress.dart';
import '../progress_logic.dart';

/// A member's week at a glance. Compact, so two fit on a small screen.
class MemberCard extends StatelessWidget {
  const MemberCard({
    required this.progress,
    required this.isMe,
    required this.onTap,
    super.key,
  });

  final MemberProgress progress;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final p = progress;
    final name = isMe ? '${p.member.displayName} (you)' : p.member.displayName;
    final week = [
      '${p.doneThisWeek} ${p.doneThisWeek == 1 ? 'task' : 'tasks'} done this week',
      if (p.contactsThisWeek > 0)
        '${p.contactsThisWeek} new ${p.contactsThisWeek == 1 ? 'contact' : 'contacts'}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CardMaterial(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: text.titleMedium)),
                    DayProgress(planned: p.todayPlanned, done: p.todayDone),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  p.todayPlanned == 0
                      ? 'Nothing planned today'
                      : 'Today: ${p.todayDone} of ${p.todayPlanned} done',
                  style: text.bodyMedium,
                ),
                Text(week, style: text.bodySmall),
                if (p.goal != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Symbols.flag,
                        size: AppSizes.tagIcon,
                        color: colors.accent,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(p.goal!, style: text.bodyMedium)),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  p.lastReview == null
                      ? 'No weekly review yet'
                      : 'Last review ${DateFormat.MMMd().format(p.lastReview!)}',
                  style: text.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
