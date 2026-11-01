import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/weekly_review.dart';
import '../../../data/repositories/reviews_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/widgets/auth_page.dart';
import '../../outreach/providers/outreach_providers.dart';
import '../../space/providers/space_providers.dart';
import '../../today/providers/today_providers.dart';
import '../providers/review_providers.dart';
import '../review_logic.dart';
import '../widgets/review_card.dart';

/// Three short questions about the week, then everyone's past reviews.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  static const path = '/review';

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late final WeeklyReview? _existing = ref.read(myCurrentReviewProvider);
  late final _did = TextEditingController(text: _existing?.did);
  late final _blocked = TextEditingController(text: _existing?.blocked);
  late final _next = TextEditingController(text: _existing?.nextGoal);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _did.dispose();
    _blocked.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final me = ref.read(currentUserIdProvider).value;
    final space = ref.read(currentSpaceProvider);
    if (me == null || space == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(reviewsRepositoryProvider)
          .save(
            WeeklyReview(
              spaceId: space.id,
              userId: me,
              weekStart: reviewWeek(ref.read(todayProvider)),
              did: _did.text,
              blocked: _blocked.text,
              nextGoal: _next.text,
            ),
          );
      ref
        ..invalidate(spaceReviewsProvider)
        ..invalidate(weeklyGoalProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review saved. Nice work this week.')),
      );
      context.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController c, String label, String hint, int max) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TextField(
          controller: c,
          maxLength: max,
          minLines: 2,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            counterText: '',
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final week = reviewWeek(ref.watch(todayProvider));
    final space = ref.watch(currentSpaceProvider);
    final names = ref.watch(memberNamesProvider);
    final me = ref.watch(currentUserIdProvider).value;
    final past =
        (ref.watch(spaceReviewsProvider).value ?? const <WeeklyReview>[])
            .where(
              (r) => !(r.userId == me && r.weekStart == week) && !r.isEmpty,
            )
            .toList();

    return AuthPage(
      title: 'Weekly review',
      subtitle:
          '${space?.name ?? ''} · week of ${DateFormat.MMMd().format(week)}. '
          'Two minutes, three questions.',
      children: [
        _field(
          _did,
          'What I did',
          'The things you moved forward',
          WeeklyReview.maxText,
        ),
        _field(
          _blocked,
          'What is blocked',
          'Anything in the way',
          WeeklyReview.maxText,
        ),
        _field(
          _next,
          'Next week’s goal',
          'Becomes next week’s goal of the week',
          WeeklyReview.maxGoal,
        ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(label: 'Save review', loading: _saving, onPressed: _save),
        if (past.isNotEmpty) ...[
          const SectionHeader(title: 'Past reviews'),
          for (final r in past)
            ReviewCard(
              review: r,
              authorName: r.userId == me
                  ? 'You'
                  : (names[r.userId] ?? 'Teammate'),
            ),
        ] else ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Icon(Symbols.history, size: AppSizes.iconSmall),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Past reviews from you and your teammates will show here.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
