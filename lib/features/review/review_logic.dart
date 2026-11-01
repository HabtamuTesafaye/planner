import '../../core/utils/dates.dart';
import '../../data/models/weekly_review.dart';

/// The week a review written [today] is about. On Monday it is still the
/// week that just ended (a grace day); otherwise the current week.
DateTime reviewWeek(DateTime today) {
  final start = Dates.weekStart(today);
  return today.weekday == DateTime.monday
      ? DateTime(start.year, start.month, start.day - 7)
      : start;
}

/// Show the gentle prompt on Today only on Sunday and Monday, and only
/// when the review for [reviewWeek] is not written yet.
bool showReviewPrompt({
  required DateTime today,
  required Iterable<WeeklyReview> myReviews,
}) {
  final day = today.weekday;
  if (day != DateTime.sunday && day != DateTime.monday) return false;
  final week = reviewWeek(today);
  return !myReviews.any((r) => r.weekStart == week && !r.isEmpty);
}
