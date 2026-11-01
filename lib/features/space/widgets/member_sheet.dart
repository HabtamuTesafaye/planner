import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/circle_check.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../data/models/weekly_review.dart';
import '../../review/widgets/review_card.dart';
import '../progress_logic.dart';

/// A member's tasks today and latest review, read only.
class MemberSheet extends StatelessWidget {
  const MemberSheet({required this.progress, required this.latest, super.key});

  final MemberProgress progress;
  final WeeklyReview? latest;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return SheetFrame(
      title: p.member.displayName,
      children: [
        const SectionHeader(title: 'Today'),
        if (p.todayTasks.isEmpty)
          Text(
            'Nothing planned today.',
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.muted,
            ),
          )
        else
          for (final t in p.todayTasks)
            Row(
              children: [
                CircleCheck(value: t.done, label: t.title, onChanged: null),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(t.title, style: context.text.bodyLarge)),
              ],
            ),
        const SectionHeader(title: 'Latest weekly review'),
        if (latest == null)
          Text(
            'No review yet.',
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.muted,
            ),
          )
        else
          ReviewCard(review: latest!, authorName: null),
      ],
    );
  }
}
