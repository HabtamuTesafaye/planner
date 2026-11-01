import 'package:flutter_test/flutter_test.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/team/providers/team_providers.dart';
import 'package:planner/router_redirect.dart';

String? go(AuthStatus auth, TeamStatus team, String location) =>
    resolveRedirect(auth: auth, team: team, location: location);

void main() {
  const anyTeam = TeamStatus.loading;

  group('starting up', () {
    test('waits on the splash screen', () {
      expect(
        go(AuthStatus.unknown, anyTeam, AppRoutes.today),
        AppRoutes.splash,
      );
      expect(go(AuthStatus.unknown, anyTeam, AppRoutes.splash), isNull);
    });
  });

  group('signed out', () {
    test('protected screens go to welcome', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.today,
        AppRoutes.team,
        AppRoutes.teamSetup,
      ]) {
        expect(
          go(AuthStatus.signedOut, anyTeam, location),
          AppRoutes.welcome,
          reason: location,
        );
      }
    });

    test('auth screens stay', () {
      for (final location in AppRoutes.signedOutRoutes) {
        expect(go(AuthStatus.signedOut, anyTeam, location), isNull);
      }
    });
  });

  group('signed in without a team', () {
    test('goes to team setup from anywhere', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.today,
        AppRoutes.team,
      ]) {
        expect(
          go(AuthStatus.signedIn, TeamStatus.none, location),
          AppRoutes.teamSetup,
          reason: location,
        );
      }
      expect(
        go(AuthStatus.signedIn, TeamStatus.none, AppRoutes.teamSetup),
        isNull,
      );
    });
  });

  group('signed in with a team', () {
    test('auth, splash and setup screens open Today', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.checkEmail,
        AppRoutes.teamSetup,
      ]) {
        expect(
          go(AuthStatus.signedIn, TeamStatus.member, location),
          AppRoutes.today,
          reason: location,
        );
      }
    });

    test('tabs stay where they are', () {
      for (final location in [
        AppRoutes.today,
        AppRoutes.outreach,
        AppRoutes.money,
        AppRoutes.team,
      ]) {
        expect(go(AuthStatus.signedIn, TeamStatus.member, location), isNull);
      }
    });
  });

  test('team still loading or failed: splash (with retry)', () {
    for (final team in [TeamStatus.loading, TeamStatus.error]) {
      expect(go(AuthStatus.signedIn, team, AppRoutes.today), AppRoutes.splash);
      expect(go(AuthStatus.signedIn, team, AppRoutes.splash), isNull);
    }
  });
}
