import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/models/contact.dart';
import 'package:planner/data/models/task.dart';
import 'package:planner/data/models/team_member.dart';
import 'package:planner/data/models/weekly_goal.dart';
import 'package:planner/data/models/weekly_review.dart';
import 'package:planner/features/review/review_logic.dart';
import 'package:planner/features/space/progress_logic.dart';

// Wed 4 Nov 2026; the week runs Mon 2 – Sun 8 Nov.
final _today = DateTime(2026, 11, 4);

TeamMember member(String id) => TeamMember(
  userId: id,
  displayName: 'Member $id',
  role: TeamRole.member,
  joinedAt: DateTime(2026),
);

Task task(String user, DateTime day, {bool done = false}) => Task(
  id: '$user-${day.day}-$done-${day.microsecond}',
  spaceId: 's1',
  userId: user,
  title: 't',
  day: day,
  done: done,
  createdAt: day,
);

WeeklyReview review(String user, DateTime week, {String did = 'Did things'}) =>
    WeeklyReview(
      spaceId: 's1',
      userId: user,
      weekStart: week,
      did: did,
      blocked: '',
      nextGoal: '',
    );

void main() {
  group('member progress (weekly counts)', () {
    final result = buildProgress(
      members: [member('a'), member('b')],
      spaceTasks: [
        task('a', _today, done: true),
        task('a', _today),
        task('a', DateTime(2026, 11, 2), done: true), // Monday, this week
        task('a', DateTime(2026, 11), done: true), // last Sunday: not counted
        task('b', DateTime(2026, 11, 3)),
      ],
      contacts: [
        Contact(
          id: 'c1',
          spaceId: 's1',
          ownerId: 'a',
          name: 'X',
          status: ContactStatus.contacted,
          createdAt: DateTime(2026, 11, 3, 10),
          updatedAt: DateTime(2026, 11, 3, 10),
        ),
        Contact(
          id: 'c2',
          spaceId: 's1',
          ownerId: 'a',
          name: 'Old',
          status: ContactStatus.contacted,
          createdAt: DateTime(2026, 10, 30),
          updatedAt: DateTime(2026, 10, 30),
        ),
      ],
      goals: [
        WeeklyGoal(
          spaceId: 's1',
          userId: 'a',
          weekStart: DateTime(2026, 11, 2),
          goal: 'Ship it',
        ),
        WeeklyGoal(
          spaceId: 's1',
          userId: 'b',
          weekStart: DateTime(2026, 10, 26),
          goal: 'Last week',
        ),
      ],
      reviews: [review('a', DateTime(2026, 10, 26))],
      today: _today,
    );
    final a = result[0];
    final b = result[1];

    test('today: planned and done', () {
      expect(a.todayPlanned, 2);
      expect(a.todayDone, 1);
      expect(b.todayPlanned, 0);
    });

    test('done this week counts Monday to Sunday only', () {
      expect(a.doneThisWeek, 2);
      expect(b.doneThisWeek, 0);
    });

    test('contacts added this week, by creator', () {
      expect(a.contactsThisWeek, 1);
      expect(b.contactsThisWeek, 0);
    });

    test('only this week\'s goal; last review date', () {
      expect(a.goal, 'Ship it');
      expect(b.goal, isNull);
      expect(a.lastReview, DateTime(2026, 10, 26));
      expect(b.lastReview, isNull);
    });
  });

  group('review week and prompt', () {
    test('on Monday the review is still about the week that just ended', () {
      expect(reviewWeek(DateTime(2026, 11, 9)), DateTime(2026, 11, 2)); // Mon
      expect(reviewWeek(DateTime(2026, 11, 8)), DateTime(2026, 11, 2)); // Sun
      expect(reviewWeek(DateTime(2026, 11, 4)), DateTime(2026, 11, 2)); // Wed
    });

    test('prompt only on Sunday and Monday', () {
      for (final day in [3, 4, 5, 6, 7]) {
        expect(
          showReviewPrompt(today: DateTime(2026, 11, day), myReviews: const []),
          isFalse,
          reason: 'Nov $day',
        );
      }
      expect(
        showReviewPrompt(today: DateTime(2026, 11, 8), myReviews: const []),
        isTrue,
      );
      expect(
        showReviewPrompt(today: DateTime(2026, 11, 9), myReviews: const []),
        isTrue,
      );
    });

    test('no prompt once that week\'s review is written', () {
      final written = [review('me', DateTime(2026, 11, 2))];
      expect(
        showReviewPrompt(today: DateTime(2026, 11, 8), myReviews: written),
        isFalse,
      );
      expect(
        showReviewPrompt(today: DateTime(2026, 11, 9), myReviews: written),
        isFalse,
      );
    });

    test('an empty review does not count as written', () {
      final empty = [review('me', DateTime(2026, 11, 2), did: '  ')];
      expect(
        showReviewPrompt(today: DateTime(2026, 11, 8), myReviews: empty),
        isTrue,
      );
    });
  });

  test('review maps and round-trips (upsert payload)', () {
    final r = WeeklyReview.fromJson(const {
      'team_id': 's1',
      'user_id': 'u1',
      'week_start': '2026-11-02',
      'did': ' Did ',
      'blocked': '',
      'next_goal': 'Next',
      'updated_at': '2026-11-08T10:00:00Z',
    });
    expect(r.weekStart, DateTime(2026, 11, 2));
    expect(r.toJson()['did'], 'Did');
    expect(r.toJson()['week_start'], '2026-11-02');
    expect(r.isEmpty, isFalse);
  });
}
