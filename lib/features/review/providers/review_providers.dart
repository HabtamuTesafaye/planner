import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/weekly_review.dart';
import '../../../data/repositories/reviews_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../space/providers/space_providers.dart';
import '../../today/providers/today_providers.dart';
import '../review_logic.dart';

/// Recent reviews of everyone in the current space, newest first.
final spaceReviewsProvider = FutureProvider<List<WeeklyReview>>((ref) async {
  final space = ref.watch(currentSpaceProvider);
  if (space == null) return const [];
  return ref.watch(reviewsRepositoryProvider).fetchSpaceReviews(space.id);
});

/// My review for the week being reviewed now (see [reviewWeek]), if any.
final myCurrentReviewProvider = Provider<WeeklyReview?>((ref) {
  final me = ref.watch(currentUserIdProvider).value;
  final week = reviewWeek(ref.watch(todayProvider));
  final reviews = ref.watch(spaceReviewsProvider).value ?? const [];
  return reviews
      .where((r) => r.userId == me && r.weekStart == week)
      .firstOrNull;
});

/// Whether Today shows the gentle review prompt.
final reviewPromptProvider = Provider<bool>((ref) {
  final reviews = ref.watch(spaceReviewsProvider);
  // Never nag on stale, loading or failed data (for example right after
  // switching space).
  if (!reviews.hasValue || reviews.isLoading || reviews.hasError) return false;
  final me = ref.watch(currentUserIdProvider).value;
  return showReviewPrompt(
    today: ref.watch(todayProvider),
    myReviews: reviews.value!.where((r) => r.userId == me),
  );
});
