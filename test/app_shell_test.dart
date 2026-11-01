import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/app.dart';
import 'package:planner/core/config/app_config.dart';
import 'package:planner/data/models/team.dart';
import 'package:planner/data/models/team_member.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/team/providers/team_providers.dart';
import 'package:planner/features/team/screens/team_screen.dart';

import 'helpers.dart';

const _config = AppConfig(
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'test',
);

final _team = Team(
  id: 't1',
  name: 'Founders Studio',
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

Future<void> _pumpSignedInApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
        currentTeamProvider.overrideWith((ref) async => _team),
        teamMembersProvider.overrideWith((ref) async => _members),
      ],
      child: const PlannerApp(config: _config),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('signed in with a team: 4 tabs fit ($brightness, 1.5x)', (
      tester,
    ) async {
      useSmallPhone(tester, brightness: brightness);
      await _pumpSignedInApp(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      for (final (tab, expected) in [
        ('Outreach', 'No contacts yet.'),
        ('Money', 'No income logged this month.'),
        ('Team', 'Founders Studio'),
        ('Today', 'Nothing planned yet.'),
      ]) {
        await tester.tap(find.widgetWithText(NavigationDestination, tab));
        await tester.pumpAndSettle();
        expect(find.text(expected), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      final theme = Theme.of(tester.element(find.byType(NavigationBar)));
      expect(theme.brightness, brightness);
    });
  }

  testWidgets('team tab shows code, members, sign out and leave', (
    tester,
  ) async {
    useSmallPhone(tester);
    await _pumpSignedInApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Team'));
    await tester.pumpAndSettle();

    expect(find.text('ABCD EFGH'), findsOneWidget);
    expect(find.byTooltip('Copy invite code'), findsOneWidget);
    expect(find.text('Abebe'), findsOneWidget);
    expect(find.text('you · owner'), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Leave team'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(TeamScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Leave team'), findsOneWidget);
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

  testWidgets('signed in without a team: the app opens team setup', (
    tester,
  ) async {
    useSmallPhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => Stream.value('u9')),
          currentTeamProvider.overrideWith((ref) async => null),
        ],
        child: const PlannerApp(config: _config),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set up your team'), findsOneWidget);
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
    expect(find.byType(NavigationBar), findsNothing);
  });
}
