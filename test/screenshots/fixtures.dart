import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';

import 'package:planner/data/models/contact.dart';
import 'package:planner/data/models/income.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/project.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/data/models/task.dart';
import 'package:planner/data/models/team_member.dart';
import 'package:planner/data/models/weekly_goal.dart';
import 'package:planner/data/models/weekly_review.dart';
import 'package:planner/data/repositories/profile_repository.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/insights/providers/insights_providers.dart';
import 'package:planner/features/money/providers/money_providers.dart';
import 'package:planner/features/outreach/providers/outreach_providers.dart';
import 'package:planner/features/projects/providers/projects_providers.dart';
import 'package:planner/features/review/providers/review_providers.dart';
import 'package:planner/features/space/providers/progress_providers.dart';
import 'package:planner/features/space/providers/space_providers.dart';
import 'package:planner/features/today/providers/today_providers.dart';

import '../helpers.dart';

/// Realistic sample data for screenshots: a Wednesday in a team space.
final shotToday = DateTime(2026, 11, 4, 9);

class _Profiles extends Mock implements ProfileRepository {
  @override
  Future<void> setLastSpace(String userId, String spaceId) async {}
}

final _personal = Space(
  id: 'p',
  name: 'Personal',
  kind: SpaceKind.personal,
  joinCode: null,
  createdAt: DateTime(2026),
);
final _team = Space(
  id: 't',
  name: 'Elvaris Studio',
  kind: SpaceKind.team,
  joinCode: 'XB6B9ZQZ',
  createdAt: DateTime(2026),
);

Task _task(
  String id,
  String space,
  String title, {
  bool done = false,
  int day = 4,
  String user = 'u1',
  String? item,
}) => Task(
  id: id,
  spaceId: space,
  userId: user,
  title: title,
  day: DateTime(2026, 11, day),
  done: done,
  createdAt: DateTime(2026, 11, day, 8, id.hashCode % 50),
  projectItemId: item,
);

final _todayTasks = [
  _task('a', 't', 'Send the invoice to Selam', done: true),
  _task('b', 't', 'Call Abebe about the café menu', item: 'i2'),
  _task('c', 'p', 'Gym, 30 minutes'),
];

final _history = [
  ..._todayTasks,
  for (var i = 1; i < 120; i++)
    for (var k = 0; k < (i * 7) % 4; k++)
      _task('h$i-$k', 't', 'Past task', done: k < ((i * 5) % 4), day: 4 - i),
];

final _projects = [
  Project(
    id: 'pr1',
    spaceId: 't',
    name: 'Website relaunch',
    template: 'launch',
    status: ProjectStatus.active,
    createdBy: 'u1',
    createdAt: DateTime(2026, 10, 20),
  ),
  Project(
    id: 'pr2',
    spaceId: 't',
    name: 'Café Abebe branding',
    template: 'client',
    status: ProjectStatus.active,
    createdBy: 'u2',
    createdAt: DateTime(2026, 10, 25),
  ),
];

ProjectItem _item(
  String id,
  String project,
  String title,
  int pos, {
  bool done = false,
}) => ProjectItem(
  id: id,
  projectId: project,
  spaceId: 't',
  title: title,
  done: done,
  position: pos,
  createdBy: 'u1',
);

final _items = [
  _item('i1', 'pr1', 'Define who it is for', 0, done: true),
  _item('i2', 'pr1', 'Write the one-line pitch', 1, done: true),
  _item('i3', 'pr1', 'Build the first version', 2),
  _item('i4', 'pr1', 'Test with three people', 3),
  _item('i5', 'pr1', 'Launch and share', 4),
  _item('j1', 'pr2', 'Kick-off call and goals', 0, done: true),
  _item('j2', 'pr2', 'Send proposal and price', 1),
];

Contact _contact(
  String id,
  String name,
  String business,
  ContactStatus s, {
  int? follow,
  double? price,
  String owner = 'u1',
}) => Contact(
  id: id,
  spaceId: 't',
  ownerId: owner,
  name: name,
  business: business,
  status: s,
  nextFollowUp: follow == null ? null : DateTime(2026, 11, follow),
  price: price,
  createdAt: DateTime(2026, 11, 2),
  updatedAt: DateTime(2026, 11, 3),
);

final _contacts = [
  _contact(
    'c1',
    'Abebe Kebede',
    'Café Abebe',
    ContactStatus.meeting,
    follow: 1,
    price: 12500,
  ),
  _contact(
    'c2',
    'Selam Tesfaye',
    'Selam Boutique',
    ContactStatus.proposal,
    follow: 6,
    owner: 'u2',
  ),
  _contact(
    'c3',
    'Dawit Haile',
    'Haile Logistics',
    ContactStatus.contacted,
    follow: 4,
  ),
  _contact('c4', 'Meron Alemu', 'Bloom Florist', ContactStatus.replied),
  _contact(
    'c5',
    'Yonas Bekele',
    'Bekele Motors',
    ContactStatus.paid,
    price: 30000,
  ),
];

final _members = [
  TeamMember(
    userId: 'u1',
    displayName: 'Habtamu',
    role: TeamRole.owner,
    joinedAt: DateTime(2026),
  ),
  TeamMember(
    userId: 'u2',
    displayName: 'Sara',
    role: TeamRole.member,
    joinedAt: DateTime(2026, 2),
  ),
];

/// Every override the app needs to run fully on sample data.
List<Override> shotOverrides() => [
  currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
  noPasswordRecovery,
  currentProfileProvider.overrideWith(
    (ref) async =>
        const Profile(id: 'u1', displayName: 'Habtamu', lastSpaceId: 't'),
  ),
  profileRepositoryProvider.overrideWithValue(_Profiles()),
  mySpacesProvider.overrideWith((ref) async => [_personal, _team]),
  spaceMembersProvider.overrideWith((ref) async => _members),
  myTasksProvider.overrideWith((ref) => Stream.value(_todayTasks)),
  activityTasksProvider.overrideWith((ref) async => _history),
  weeklyGoalProvider.overrideWith(
    (ref) async => WeeklyGoal(
      spaceId: 't',
      userId: 'u1',
      weekStart: DateTime(2026, 11, 2),
      goal: 'Ship the new landing page',
    ),
  ),
  projectsProvider.overrideWith((ref) => Stream.value(_projects)),
  projectItemsProvider.overrideWith((ref) => Stream.value(_items)),
  contactsProvider.overrideWith((ref) => Stream.value(_contacts)),
  incomeEntriesProvider.overrideWith(
    (ref) => Stream.value([
      IncomeEntry(
        id: 'e1',
        spaceId: 't',
        userId: 'u1',
        month: DateTime(2026, 11),
        cents: 1250000,
        note: 'Café Abebe deposit',
        createdAt: DateTime(2026, 11, 3),
      ),
      IncomeEntry(
        id: 'e2',
        spaceId: 't',
        userId: 'u2',
        month: DateTime(2026, 11),
        cents: 450000,
        note: 'Logo design',
        createdAt: DateTime(2026, 11, 2),
      ),
      for (var m = 1; m < 6; m++)
        IncomeEntry(
          id: 'h$m',
          spaceId: 't',
          userId: 'u1',
          month: DateTime(2026, 11 - m),
          cents: [800000, 1500000, 400000, 950000, 600000][m - 1],
          note: '',
          createdAt: DateTime(2026, 11 - m, 10),
        ),
    ]),
  ),
  monthlyTargetProvider.overrideWith(
    (ref) async =>
        MonthlyTarget(spaceId: 't', month: DateTime(2026, 11), cents: 5000000),
  ),
  spaceTasksProvider.overrideWith(
    (ref) => Stream.value([
      ..._todayTasks,
      _task('s1', 't', 'Draft proposal', user: 'u2', done: true),
      _task('s2', 't', 'Visit Bloom Florist', user: 'u2'),
    ]),
  ),
  spaceGoalsProvider.overrideWith(
    (ref) async => [
      WeeklyGoal(
        spaceId: 't',
        userId: 'u1',
        weekStart: DateTime(2026, 11, 2),
        goal: 'Ship the new landing page',
      ),
      WeeklyGoal(
        spaceId: 't',
        userId: 'u2',
        weekStart: DateTime(2026, 11, 2),
        goal: 'Close two new clients',
      ),
    ],
  ),
  spaceReviewsProvider.overrideWith(
    (ref) async => [
      WeeklyReview(
        spaceId: 't',
        userId: 'u2',
        weekStart: DateTime(2026, 10, 26),
        did: 'Signed Selam Boutique and drafted their proposal.',
        blocked: 'Waiting on photos from the café.',
        nextGoal: 'Close two new clients',
      ),
    ],
  ),
  clockProvider.overrideWithValue(() => shotToday),
];
