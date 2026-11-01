import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planner/app.dart';
import 'package:planner/core/config/app_config.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/data/models/team_member.dart';
import 'package:planner/data/repositories/profile_repository.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/space/providers/space_providers.dart';
import 'package:planner/features/space/screens/space_screen.dart';

import 'helpers.dart';

class _FakeProfiles extends Mock implements ProfileRepository {
  @override
  Future<void> setLastSpace(String userId, String spaceId) async {}
}

const _config = AppConfig(
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'test',
);

final _personal = Space(
  id: 'p1',
  name: 'Personal',
  kind: SpaceKind.personal,
  joinCode: null,
  createdAt: DateTime.utc(2026, 11),
);

final _team = Space(
  id: 't1',
  name: 'Founders Studio',
  kind: SpaceKind.team,
  joinCode: 'ABCDEFGH',
  createdAt: DateTime.utc(2026, 11),
);

final _members = [
  TeamMember(
    userId: 'u1',
    displayName: 'Abebe',
    role: TeamRole.owner,
    joinedAt: DateTime.utc(2026, 11),
  ),
  TeamMember(
    userId: 'u2',
    displayName: 'Sara',
    role: TeamRole.member,
    joinedAt: DateTime.utc(2026, 11, 2),
  ),
];

/// Signed in as u1 with a personal and a team space. [lastSpace] is the
/// space remembered on the profile.
Future<void> _pumpApp(WidgetTester tester, {String? lastSpace}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
        currentProfileProvider.overrideWith(
          (ref) async =>
              Profile(id: 'u1', displayName: 'Abebe', lastSpaceId: lastSpace),
        ),
        mySpacesProvider.overrideWith((ref) async => [_personal, _team]),
        spaceMembersProvider.overrideWith((ref) async => _members),
        profileRepositoryProvider.overrideWithValue(_FakeProfiles()),
      ],
      child: const PlannerApp(config: _config),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.widgetWithText(NavigationDestination, tab));
  await tester.pumpAndSettle();
}

const _marks = {
  'Today': 'Nothing planned yet.',
  'Projects': 'No projects yet.',
  'Outreach': 'No contacts yet.',
  'Money': 'No income logged this month.',
  'Space': 'Your private space. Only you can see what you keep here.',
};

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('signed in: 5 tabs fit a small phone ($brightness, 1.5x)', (
      tester,
    ) async {
      useSmallPhone(tester, brightness: brightness);
      await _pumpApp(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      for (final tab in ['Projects', 'Outreach', 'Money', 'Space', 'Today']) {
        await _openTab(tester, tab);
        expect(find.text(_marks[tab]!), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('switching tabs through the real router never overlaps', (
    tester,
  ) async {
    useSmallPhone(tester);
    await _pumpApp(tester);
    double visibility(String text) {
      final fades = find.ancestor(
        of: find.text(text, skipOffstage: false),
        matching: find.byType(FadeTransition),
      );
      if (fades.evaluate().isEmpty) return 0; // tab not built yet
      return tester.widget<FadeTransition>(fades.first).opacity.value;
    }

    for (final tab in [
      'Outreach',
      'Space',
      'Money',
      'Today',
      'Projects',
      'Outreach',
      'Today',
    ]) {
      await _openTab(tester, tab);
      _marks.forEach((other, text) {
        expect(
          visibility(text),
          other == tab ? 1 : 0,
          reason:
              'on $tab, $other must be ${other == tab ? 'shown' : 'hidden'}',
        );
      });
    }
  });

  testWidgets('new accounts land in Personal: no forced team setup', (
    tester,
  ) async {
    useSmallPhone(tester);
    await _pumpApp(tester);
    expect(find.text('Nothing planned yet.'), findsOneWidget);
    await _openTab(tester, 'Space');
    expect(find.text('Create a team space'), findsOneWidget);
    expect(find.text('Join with a code'), findsOneWidget);
    expect(find.text('Leave space'), findsNothing);
  });

  testWidgets('team space: code, members, leave', (tester) async {
    useSmallPhone(tester);
    await _pumpApp(tester, lastSpace: 't1');
    await _openTab(tester, 'Space');
    expect(find.text('ABCD EFGH'), findsOneWidget);
    expect(find.text('you · owner'), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Leave space'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SpaceScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Leave space'), findsOneWidget);
  });

  testWidgets('space switcher lists spaces and switches', (tester) async {
    useSmallPhone(tester);
    await _pumpApp(tester);
    await _openTab(tester, 'Projects');
    await tester.tap(find.bySemanticsLabel(RegExp('Space: Personal')).first);
    await tester.pumpAndSettle();
    expect(find.text('Spaces'), findsOneWidget);
    expect(find.text('New team space'), findsOneWidget);
    await tester.tap(find.text('Founders Studio'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Space: Founders Studio')),
      findsWidgets,
    );
  });

  testWidgets('signed out: the app opens on Welcome', (tester) async {
    useSmallPhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const PlannerApp(config: _config),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('missing config shows setup screen instead of crashing', (
    tester,
  ) async {
    useSmallPhone(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: PlannerApp(
          config: AppConfig(supabaseUrl: '', supabaseAnonKey: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Setup needed'), findsOneWidget);
  });
}
