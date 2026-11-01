import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_decor.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../data/models/weekly_review.dart';

/// A weekly review, read only. [authorName] null hides the name line.
class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, required this.authorName, super.key});

  final WeeklyReview review;
  final String? authorName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final week = 'Week of ${DateFormat.MMMd().format(review.weekStart)}';

    Widget part(String label, String value) => value.trim().isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelSmall),
                Text(value, style: text.bodyMedium),
              ],
            ),
          );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecor.card(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            authorName == null ? week : '$authorName · $week',
            style: text.titleSmall,
          ),
          part('What I did', review.did),
          part('What is blocked', review.blocked),
          part('Next week’s goal', review.nextGoal),
        ],
      ),
    );
  }
}
