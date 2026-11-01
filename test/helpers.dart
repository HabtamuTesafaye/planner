import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:planner/core/theme/app_theme.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';

/// Small phone (360 x 640 dp) at 1.5x font scale, in the given theme.
void useSmallPhone(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
}) {
  tester.view.physicalSize = const Size(360, 640) * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.5;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

/// Pumps one screen inside a router and the app theme, with overrides.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (context, state) => screen)],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

/// No password-reset link was opened. The real notifier listens to
/// Supabase auth events, which full-app tests don't have.
class NoPasswordRecovery extends PasswordRecoveryNotifier {
  @override
  bool build() => false;
}

/// Override for tests that pump the whole app.
final noPasswordRecovery = passwordRecoveryProvider.overrideWith(
  NoPasswordRecovery.new,
);
