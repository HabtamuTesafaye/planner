import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/widgets/app_shell.dart';
import 'core/widgets/fade_through_stack.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/screens/check_email_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/new_password_screen.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/auth/screens/sign_up_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/insights/screens/insights_screen.dart';
import 'features/money/screens/money_screen.dart';
import 'features/outreach/screens/outreach_screen.dart';
import 'features/projects/screens/project_screen.dart';
import 'features/projects/screens/projects_screen.dart';
import 'features/review/screens/review_screen.dart';
import 'features/space/providers/space_providers.dart';
import 'features/space/screens/new_space_screen.dart';
import 'features/space/screens/space_screen.dart';
import 'features/today/screens/today_screen.dart';
import 'router_redirect.dart';

/// The app router. Redirects follow the auth and spaces state (see
/// [resolveRedirect]) and re-run whenever either changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authStatusProvider, (_, _) => refresh.value++)
    ..listen(spacesStatusProvider, (_, _) => refresh.value++)
    ..listen(passwordRecoveryProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      auth: ref.read(authStatusProvider),
      spaces: ref.read(spacesStatusProvider),
      location: state.matchedLocation,
      recovering: ref.read(passwordRecoveryProvider),
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
        path: AppRoutes.forgotPassword,
        builder: (context, state) => ForgotPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.newPassword,
        builder: (context, state) => const NewPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.newSpace,
        builder: (context, state) => NewSpaceScreen(
          initialMode: state.uri.queryParameters['mode'] == 'join'
              ? NewSpaceMode.join
              : NewSpaceMode.create,
        ),
      ),
      GoRoute(
        path: ReviewScreen.path,
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) =>
            ProjectScreen(projectId: state.pathParameters['id']!),
      ),
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            FadeThroughStack(index: shell.currentIndex, children: children),
        branches: [
          _branch(AppRoutes.today, const TodayScreen()),
          _branch(InsightsScreen.path, const InsightsScreen()),
          _branch(AppRoutes.projects, const ProjectsScreen()),
          _branch(AppRoutes.outreach, const OutreachScreen()),
          _branch(AppRoutes.money, const MoneyScreen()),
          _branch(AppRoutes.space, const SpaceScreen()),
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
