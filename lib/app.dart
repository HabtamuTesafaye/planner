import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/setup_needed_screen.dart';
import 'router.dart';

/// Root widget: theme, router, and the setup guard.
class PlannerApp extends ConsumerWidget {
  const PlannerApp({required this.config, super.key});

  final AppConfig config;

  static const String title = 'Planner';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme mode follows the system (the default) until the setting arrives
    // in Phase 6.
    if (!config.isComplete) {
      return MaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        builder: _withSystemBars,
        home: SetupNeededScreen(problems: config.problems),
      );
    }

    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      builder: _withSystemBars,
      routerConfig: ref.watch(routerProvider),
    );
  }

  /// Keeps status and navigation bar icons readable in both themes, also on
  /// screens without an AppBar. Caps text scaling at 1.5x (AGENTS.md 4).
  static Widget _withSystemBars(BuildContext context, Widget? child) {
    final brightness = Theme.of(context).brightness;
    final media = MediaQuery.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle(brightness),
      child: MediaQuery(
        data: media.copyWith(
          textScaler: media.textScaler.clamp(maxScaleFactor: 1.5),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
