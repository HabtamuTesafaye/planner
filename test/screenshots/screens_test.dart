// Renders every main screen to PNG with the real fonts and icons, in light
// and dark, for design review. Skipped unless an output folder is given:
//
//   flutter test test/screenshots --dart-define=SHOTS_DIR=/tmp/shots
//
// Images are only for looking at; nothing is compared.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:planner/app.dart';
import 'package:planner/core/config/app_config.dart';
import 'package:planner/core/theme/app_theme.dart';
import 'package:planner/features/auth/screens/sign_in_screen.dart';
import 'package:planner/features/auth/screens/welcome_screen.dart';
import 'package:planner/features/review/screens/review_screen.dart';

import 'fixtures.dart';

const _dir = String.fromEnvironment('SHOTS_DIR');

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(rootBundle.load(f));
    }
    await loader.load();
  }

  await family('Fraunces', [
    for (final w in [400, 500, 600]) 'assets/fonts/Fraunces-$w.ttf',
  ]);
  await family('Manrope', [
    for (final w in [400, 500, 600, 700]) 'assets/fonts/Manrope-$w.ttf',
  ]);
  await family('packages/material_symbols_icons/MaterialSymbolsOutlined', [
    'packages/material_symbols_icons/lib/fonts/MaterialSymbolsOutlined.ttf',
  ]);
}

Future<void> _snap(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_dir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void _phone(WidgetTester tester, Brightness b) {
  tester.view.physicalSize = const Size(400, 860) * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.platformBrightnessTestValue = b;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

void main() {
  setUpAll(_loadFonts);

  for (final b in Brightness.values) {
    final mode = b.name;

    testWidgets('app tabs ($mode)', (tester) async {
      _phone(tester, b);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('shot'),
          child: ProviderScope(
            overrides: shotOverrides(),
            child: const PlannerApp(
              config: AppConfig(
                supabaseUrl: 'https://example.supabase.co',
                supabaseAnonKey: 'x',
              ),
            ),
          ),
        ),
      );
      await _snap(tester, '${mode}_1_today');
      for (final (i, tab) in [
        'Projects',
        'Outreach',
        'Money',
        'Space',
      ].indexed) {
        await tester.tap(find.widgetWithText(NavigationDestination, tab));
        await _snap(tester, '${mode}_${i + 2}_${tab.toLowerCase()}');
      }
      await tester.tap(find.widgetWithText(NavigationDestination, 'Projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Website relaunch'));
      await _snap(tester, '${mode}_6_project');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'Today'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Insights').first);
      await _snap(tester, '${mode}_7_insights');
    }, skip: _dir.isEmpty);

    for (final (name, screen) in [
      ('8_welcome', const WelcomeScreen()),
      ('9_sign_in', const SignInScreen()),
      ('10_review', const ReviewScreen()),
    ]) {
      testWidgets('$name ($mode)', (tester) async {
        _phone(tester, b);
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('shot'),
            child: ProviderScope(
              overrides: shotOverrides(),
              child: MaterialApp.router(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                routerConfig: GoRouter(
                  routes: [GoRoute(path: '/', builder: (_, _) => screen)],
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        await _snap(tester, '${mode}_$name');
      }, skip: _dir.isEmpty);
    }
  }
}
