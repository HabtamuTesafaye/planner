import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/app.dart';
import 'package:planner/core/config/app_config.dart';

const _config = AppConfig(
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'test',
);

/// Small phone (360 x 640 dp) at 1.5x font scale, in the given theme.
Future<void> _pumpSmallPhone(
  WidgetTester tester, {
  required Brightness brightness,
  AppConfig config = _config,
}) async {
  tester.view.physicalSize = const Size(360, 640) * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.5;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  await tester.pumpWidget(ProviderScope(child: PlannerApp(config: config)));
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('4 tabs render without overflow ($brightness, 1.5x)', (
      tester,
    ) async {
      await _pumpSmallPhone(tester, brightness: brightness);

      expect(find.byType(NavigationBar), findsOneWidget);
      for (final (tab, message) in [
        ('Outreach', 'No contacts yet.'),
        ('Money', 'No income logged this month.'),
        ('Team', 'Your team shows up here.'),
        ('Today', 'Nothing planned yet.'),
      ]) {
        await tester.tap(find.widgetWithText(NavigationDestination, tab));
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
        // Layout overflow is reported as a FlutterError and fails the test.
        expect(tester.takeException(), isNull);
      }
      final theme = Theme.of(tester.element(find.byType(NavigationBar)));
      expect(theme.brightness, brightness);
    });
  }

  testWidgets('missing config shows setup screen instead of crashing', (
    tester,
  ) async {
    await _pumpSmallPhone(
      tester,
      brightness: Brightness.light,
      config: const AppConfig(supabaseUrl: '', supabaseAnonKey: ''),
    );
    expect(find.text('Setup needed'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
