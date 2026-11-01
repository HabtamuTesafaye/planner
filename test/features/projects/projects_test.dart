import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/project.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/projects/providers/projects_providers.dart';
import 'package:planner/features/projects/screens/project_screen.dart';
import 'package:planner/features/projects/screens/projects_screen.dart';
import 'package:planner/features/projects/templates.dart';
import 'package:planner/features/space/providers/space_providers.dart';
import 'package:planner/features/today/providers/today_providers.dart';

import '../../helpers.dart';

ProjectItem step(
  String id, {
  bool done = false,
  int pos = 0,
  String project = 'p1',
}) => ProjectItem(
  id: id,
  projectId: project,
  spaceId: 's1',
  title: 'Step $id',
  done: done,
  position: pos,
  createdBy: 'u1',
);

final _project = Project(
  id: 'p1',
  spaceId: 's1',
  name: 'Website relaunch',
  template: 'launch',
  status: ProjectStatus.active,
  createdBy: 'u1',
  createdAt: DateTime(2026, 11),
);

List<Override> _overrides(List<Project> projects, List<ProjectItem> items) => [
  currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
  currentProfileProvider.overrideWith(
    (ref) async => const Profile(id: 'u1', displayName: 'Abebe'),
  ),
  mySpacesProvider.overrideWith(
    (ref) async => [
      Space(
        id: 's1',
        name: 'Personal',
        kind: SpaceKind.personal,
        joinCode: null,
        createdAt: DateTime(2026),
      ),
    ],
  ),
  projectsProvider.overrideWith((ref) => Stream.value(projects)),
  projectItemsProvider.overrideWith((ref) => Stream.value(items)),
  myTasksProvider.overrideWith((ref) => Stream.value(const [])),
];

void main() {
  group('templates', () {
    test('every template except Blank has 4 to 7 steps', () {
      for (final t in ProjectTemplate.values) {
        if (t == ProjectTemplate.blank) {
          expect(t.steps, isEmpty);
        } else {
          expect(t.steps.length, inInclusiveRange(4, 7), reason: t.label);
        }
      }
    });

    test('keys match the database check and unknown keys fall back', () {
      expect(ProjectTemplate.values.map((t) => t.key), [
        'blank',
        'client',
        'launch',
        'content',
        'event',
      ]);
      expect(ProjectTemplate.fromKey('gantt'), ProjectTemplate.blank);
    });
  });

  group('progress', () {
    test('done / total, and 0 for an empty project', () {
      expect(projectProgress([]), 0);
      expect(projectProgress([step('a', done: true), step('b')]), 0.5);
      expect(projectProgress([step('a', done: true)]), 1);
    });
  });

  group('steps with pending changes', () {
    test('only this project, in order, with pending toggles and deletes', () {
      final items = itemsOf('p1', [
        step('b', pos: 2),
        step('a', pos: 1),
        step('x', project: 'p2'),
        step('c', pos: 3),
      ], const ItemOverlay(done: {'a': true}, deleted: {'c'}));
      expect(items.map((i) => i.id), ['a', 'b']);
      expect(items.first.done, isTrue);
    });

    test('pending changes drop once the server agrees', () {
      const overlay = ItemOverlay(done: {'a': true}, deleted: {'b'});
      final pruned = overlay.prunedBy([step('a', done: true)]);
      expect(pruned.done, isEmpty);
      expect(pruned.deleted, isEmpty);
    });
  });

  testWidgets('projects list: progress and a done section', (tester) async {
    useSmallPhone(tester);
    final done = Project(
      id: 'p2',
      spaceId: 's1',
      name: 'Old flyer',
      template: 'blank',
      status: ProjectStatus.done,
      createdBy: 'u1',
      createdAt: DateTime(2026, 10),
    );
    await pumpScreen(
      tester,
      const ProjectsScreen(),
      overrides: _overrides(
        [_project, done],
        [step('a', done: true), step('b', pos: 1), step('c', pos: 2)],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Website relaunch'), findsOneWidget);
    expect(find.text('1 of 3 steps'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty projects: one line and one button', (tester) async {
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const ProjectsScreen(),
      overrides: _overrides([], []),
    );
    await tester.pumpAndSettle();
    expect(find.text('No projects yet.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'New project'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('project screen fits a small phone at 1.5x ($brightness)', (
      tester,
    ) async {
      useSmallPhone(tester, brightness: brightness);
      await pumpScreen(
        tester,
        const ProjectScreen(projectId: 'p1'),
        overrides: _overrides(
          [_project],
          [step('a', done: true), step('b', pos: 1)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Website relaunch'), findsOneWidget);
      expect(find.text('Product launch'), findsOneWidget);
      expect(find.text('1 of 2 steps'), findsOneWidget);
      // Done steps can't be planned; open ones can.
      expect(find.byTooltip('Plan for today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a deleted project shows a calm note', (tester) async {
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const ProjectScreen(projectId: 'gone'),
      overrides: _overrides([_project], []),
    );
    await tester.pumpAndSettle();
    expect(find.text('This project is gone.'), findsOneWidget);
  });

  testWidgets('every step done: a clear "Mark project done" button', (
    tester,
  ) async {
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const ProjectScreen(projectId: 'p1'),
      overrides: _overrides(
        [_project],
        [step('a', done: true), step('b', pos: 1, done: true)],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Every step is done. Close the project?'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Mark project done'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('open steps: no done button, a hint about planning', (
    tester,
  ) async {
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const ProjectScreen(projectId: 'p1'),
      overrides: _overrides([_project], [step('a'), step('b', pos: 1)]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mark project done'), findsNothing);
    expect(
      find.text('Tap a step to add a note. Tap the sun to plan it for today.'),
      findsOneWidget,
    );
  });

  testWidgets('a step with a note shows its first line; tap opens it', (
    tester,
  ) async {
    useSmallPhone(tester);
    final noted = ProjectItem.fromJson(const {
      'id': 'n1',
      'project_id': 'p1',
      'team_id': 's1',
      'title': 'Pick domain',
      'done': false,
      'position': 0,
      'note': 'Ask Hana for the login\nThen renew for 2 years',
      'note_updated_at': '2026-11-01T10:00:00Z',
      'note_updated_by': 'u1',
    });
    await pumpScreen(
      tester,
      const ProjectScreen(projectId: 'p1'),
      overrides: _overrides([_project], [noted]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ask Hana for the login'), findsOneWidget);
    await tester.tap(find.text('Pick domain'));
    await tester.pumpAndSettle();
    expect(find.text('Note'), findsOneWidget);
    expect(find.textContaining('Then renew'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'step notes: read from the database, sent on restore, blank is none',
    () {
      final item = ProjectItem.fromJson(const {
        'id': 'n1',
        'project_id': 'p1',
        'team_id': 's1',
        'title': 'T',
        'note': '  keep me  ',
        'note_updated_at': '2026-11-01T10:00:00Z',
      });
      expect(item.hasNote, isTrue);
      expect(item.noteUpdatedAt, isNotNull);
      expect(item.toInsertJson()['note'], 'keep me');
      final blank = ProjectItem.fromJson(const {
        'id': 'n2',
        'project_id': 'p1',
        'team_id': 's1',
        'title': 'T',
        'note': '   ',
      });
      expect(blank.hasNote, isFalse);
      expect(blank.toInsertJson().containsKey('note'), isFalse);
    },
  );
}
