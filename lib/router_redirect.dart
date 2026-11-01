import 'features/auth/providers/auth_providers.dart';
import 'features/space/providers/space_providers.dart';

/// Route paths, in one place.
abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const checkEmail = '/check-email';
  static const newSpace = '/spaces/new';
  static const today = '/today';
  static const projects = '/projects';
  static const outreach = '/outreach';
  static const money = '/money';
  static const space = '/space';

  /// Reachable while signed out.
  static const signedOutRoutes = {welcome, signIn, signUp, checkEmail};
}

/// Where to send the user, or null to stay. Pure so it can be tested.
///
/// * Starting up, or loading the user's spaces: splash.
/// * Signed out: the auth screens only (welcome by default).
/// * Signed in: the app. Nobody is forced to create a team; everyone has a
///   Personal space. Auth and splash screens go to Today.
String? resolveRedirect({
  required AuthStatus auth,
  required SpacesStatus spaces,
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
      switch (spaces) {
        case SpacesStatus.loading:
        case SpacesStatus.error:
          return goTo(AppRoutes.splash);
        case SpacesStatus.ready:
          final outsideApp = onSignedOutRoute || location == AppRoutes.splash;
          return outsideApp ? AppRoutes.today : null;
      }
  }
}
