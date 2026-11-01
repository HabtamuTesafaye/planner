import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/widgets/app_shell.dart';
import 'core/widgets/fade_through_stack.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/screens/check_email_screen.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/auth/screens/sign_up_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/team_setup_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/money/screens/money_screen.dart';
import 'features/outreach/screens/outreach_screen.dart';
import 'features/team/providers/team_providers.dart';
import 'features/team/screens/team_screen.dart';
import 'features/today/screens/today_screen.dart';
import 'router_redirect.dart';

/// The app router. Redirects follow the auth and team state (see
/// [resolveRedirect]) and re-run whenever either changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authStatusProvider, (_, _) => refresh.value++)
    ..listen(teamStatusProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      auth: ref.read(authStatusProvider),
      team: ref.read(teamStatusProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkEmail,
        builder: (context, state) =>
            CheckEmailScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.teamSetup,
        builder: (context, state) => const TeamSetupScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            FadeThroughStack(index: shell.currentIndex, children: children),
        branches: [
          _branch(AppRoutes.today, const TodayScreen()),
          _branch(AppRoutes.outreach, const OutreachScreen()),
          _branch(AppRoutes.money, const MoneyScreen()),
          _branch(AppRoutes.team, const TeamScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

StatefulShellBranch _branch(String path, Widget screen) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => screen)],
  );
}
