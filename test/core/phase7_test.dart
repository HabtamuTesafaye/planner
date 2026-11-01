import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/theme/app_spacing.dart';
import 'package:planner/core/theme/app_theme.dart';
import 'package:planner/core/widgets/primary_button.dart';
import 'package:planner/data/connectivity.dart';
import 'package:planner/data/reminders/reminder_service.dart';
import 'package:planner/features/auth/screens/sign_in_screen.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers.dart' show pumpScreen;

void main() {
  group('daily reminder time', () {
    tzdata.initializeTimeZones();
    final zone = tz.getLocation('Africa/Addis_Ababa');

    test('later today when the time has not passed yet', () {
      final now = tz.TZDateTime(zone, 2026, 11, 4, 7);
      final next = nextReminder(now, const TimeOfDay(hour: 8, minute: 30));
      expect(next, tz.TZDateTime(zone, 2026, 11, 4, 8, 30));
    });

    test('tomorrow when the time already passed (or is now)', () {
      final now = tz.TZDateTime(zone, 2026, 11, 4, 8, 30);
      final next = nextReminder(now, const TimeOfDay(hour: 8, minute: 30));
      expect(next, tz.TZDateTime(zone, 2026, 11, 5, 8, 30));
    });

    test('rolls over the end of the month and the year', () {
      expect(
        nextReminder(
          tz.TZDateTime(zone, 2026, 11, 30, 22),
          const TimeOfDay(hour: 7, minute: 0),
        ),
        tz.TZDateTime(zone, 2026, 12, 1, 7),
      );
      expect(
        nextReminder(
          tz.TZDateTime(zone, 2026, 12, 31, 22),
          const TimeOfDay(hour: 7, minute: 0),
        ),
        tz.TZDateTime(zone, 2027, 1, 1, 7),
      );
    });
  });

  group('offline', () {
    testWidgets('save buttons pause with a short reason; typing is kept', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const SignInScreen(),
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(false)),
        ],
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byType(PrimaryButton),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(find.textContaining('You’re offline'), findsOneWidget);
      expect(find.text('a@b.co'), findsOneWidget);
    });

    testWidgets('online: the button works and no notice is shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: PrimaryButton(label: 'Save', onPressed: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('offline'), findsNothing);
    });

    testWidgets('unknown connectivity counts as online (never locks the app)', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.error('no plugin')),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(isOnlineProvider), isTrue);
    });
  });

  testWidgets('tablet: content stays centered at max 600 dp', (tester) async {
    tester.view.physicalSize = const Size(1280, 800) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await pumpScreen(tester, const SignInScreen());
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(TextFormField).first);
    expect(field.width, lessThanOrEqualTo(AppSizes.maxContentWidth));
    expect((field.center.dx - 640).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });
}
