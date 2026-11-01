import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planner/app.dart';
import 'package:planner/core/config/app_config.dart';
import 'package:planner/data/models/profile.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/data/models/task.dart';
import 'package:planner/data/models/team_member.dart';
import 'package:planner/data/repositories/profile_repository.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/auth/screens/sign_in_screen.dart';
import 'package:planner/features/auth/screens/sign_up_screen.dart';
import 'package:planner/features/auth/screens/welcome_screen.dart';
import 'package:planner/features/money/providers/money_providers.dart';
import 'package:planner/features/outreach/providers/outreach_providers.dart';
import 'package:planner/features/projects/providers/projects_providers.dart';
import 'package:planner/features/review/providers/review_providers.dart';
import 'package:planner/features/space/providers/progress_providers.dart';
import 'package:planner/features/space/providers/space_providers.dart';
import 'package:planner/features/today/providers/today_providers.dart';

import 'helpers.dart';

class _Profiles extends Mock implements ProfileRepository {
  @override
  Future<void> setLastSpace(String userId, String spaceId) async {}
}

/// Android accessibility guidelines Flutter can check automatically:
/// 48 dp tap targets, every tappable thing labelled, readable contrast.
Future<void> expectGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

void main() {
  for (final brightness in Brightness.values) {
    group('accessibility guidelines ($brightness)', () {
      for (final (name, screen) in [
        ('welcome', const WelcomeScreen()),
        ('sign in', const SignInScreen()),
        ('sign up', const SignUpScreen()),
      ]) {
        testWidgets(name, (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          await pumpScreen(tester, screen);
          await tester.pumpAndSettle();
          await expectGuidelines(tester);
        });
      }

      testWidgets('app tabs', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final space = Space(
          id: 's1',
          name: 'Personal',
          kind: SpaceKind.personal,
          joinCode: null,
          createdAt: DateTime(2026),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
              currentProfileProvider.overrideWith(
                (ref) async => const Profile(id: 'u1', displayName: 'Abebe'),
              ),
              mySpacesProvider.overrideWith((ref) async => [space]),
              spaceMembersProvider.overrideWith(
                (ref) async => [
                  TeamMember(
                    userId: 'u1',
                    displayName: 'Abebe',
                    role: TeamRole.owner,
                    joinedAt: DateTime(2026),
                  ),
                ],
              ),
              profileRepositoryProvider.overrideWithValue(_Profiles()),
              myTasksProvider.overrideWith(
                (ref) => Stream.value([
                  Task(
                    id: 't1',
                    spaceId: 's1',
                    userId: 'u1',
                    title: 'Call Abebe',
                    day: DateTime(2026, 11, 4),
                    done: false,
                    createdAt: DateTime(2026, 11, 4, 8),
                  ),
                ]),
              ),
              weeklyGoalProvider.overrideWith((ref) async => null),
              projectsProvider.overrideWith((ref) => Stream.value(const [])),
              projectItemsProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              contactsProvider.overrideWith((ref) => Stream.value(const [])),
              incomeEntriesProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              monthlyTargetProvider.overrideWith((ref) async => null),
              spaceTasksProvider.overrideWith((ref) => Stream.value(const [])),
              spaceGoalsProvider.overrideWith((ref) async => const []),
              spaceReviewsProvider.overrideWith((ref) async => const []),
              clockProvider.overrideWithValue(() => DateTime(2026, 11, 4, 9)),
            ],
            child: const PlannerApp(
              config: AppConfig(
                supabaseUrl: 'https://example.supabase.co',
                supabaseAnonKey: 'test',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final tab in ['Today', 'Projects', 'Outreach', 'Money', 'Space']) {
          await tester.tap(find.byTooltip(tab));
          await tester.pumpAndSettle();
          await expectGuidelines(tester);
        }
      });
    });
  }
}
