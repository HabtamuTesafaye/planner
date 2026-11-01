import 'features/auth/providers/auth_providers.dart';
import 'features/team/providers/team_providers.dart';

/// Route paths, in one place.
abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const checkEmail = '/check-email';
  static const teamSetup = '/team-setup';
  static const today = '/today';
  static const outreach = '/outreach';
  static const money = '/money';
  static const team = '/team';

  /// Reachable while signed out.
  static const signedOutRoutes = {welcome, signIn, signUp, checkEmail};
}

/// Where to send the user, or null to stay. Pure so it can be tested.
///
/// * Starting up or loading the team: splash.
/// * Signed out: the auth screens only (welcome by default).
/// * Signed in without a team: team setup.
/// * Signed in with a team: the tabs; auth and setup screens go to Today.
String? resolveRedirect({
  required AuthStatus auth,
  required TeamStatus team,
  required String location,
}) {
  String? goTo(String target) => location == target ? null : target;
  final onSignedOutRoute = AppRoutes.signedOutRoutes.contains(location);

  switch (auth) {
    case AuthStatus.unknown:
      return goTo(AppRoutes.splash);
    case AuthStatus.signedOut:
      return onSignedOutRoute ? null : AppRoutes.welcome;
    case AuthStatus.signedIn:
      switch (team) {
        case TeamStatus.loading:
        case TeamStatus.error:
          return goTo(AppRoutes.splash);
        case TeamStatus.none:
          return goTo(AppRoutes.teamSetup);
        case TeamStatus.member:
          final outsideApp =
              onSignedOutRoute ||
              location == AppRoutes.splash ||
              location == AppRoutes.teamSetup;
          return outsideApp ? AppRoutes.today : null;
      }
  }
}
