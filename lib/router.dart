import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/widgets/app_shell.dart';
import 'features/money/screens/money_screen.dart';
import 'features/outreach/screens/outreach_screen.dart';
import 'features/team/screens/team_screen.dart';
import 'features/today/screens/today_screen.dart';

/// Route paths, in one place.
abstract final class AppRoutes {
  static const today = '/today';
  static const outreach = '/outreach';
  static const money = '/money';
  static const team = '/team';
}

/// The app router. Auth redirects are added in Phase 2.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.today,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          _branch(AppRoutes.today, const TodayScreen()),
          _branch(AppRoutes.outreach, const OutreachScreen()),
          _branch(AppRoutes.money, const MoneyScreen()),
          _branch(AppRoutes.team, const TeamScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(String path, Widget screen) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => screen)],
  );
}
