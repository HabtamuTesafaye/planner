import 'package:flutter_test/flutter_test.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/space/providers/space_providers.dart';
import 'package:planner/router_redirect.dart';

String? go(AuthStatus auth, SpacesStatus spaces, String location) =>
    resolveRedirect(auth: auth, spaces: spaces, location: location);

const _tabs = [
  AppRoutes.today,
  AppRoutes.projects,
  AppRoutes.outreach,
  AppRoutes.money,
  AppRoutes.space,
];

void main() {
  const any = SpacesStatus.loading;

  test('starting up waits on the splash screen', () {
    expect(go(AuthStatus.unknown, any, AppRoutes.today), AppRoutes.splash);
    expect(go(AuthStatus.unknown, any, AppRoutes.splash), isNull);
  });

  group('signed out', () {
    test('app screens go to welcome', () {
      for (final location in [AppRoutes.splash, AppRoutes.newSpace, ..._tabs]) {
        expect(
          go(AuthStatus.signedOut, any, location),
          AppRoutes.welcome,
          reason: location,
        );
      }
    });

    test('auth screens stay', () {
      for (final location in AppRoutes.signedOutRoutes) {
        expect(go(AuthStatus.signedOut, any, location), isNull);
      }
    });
  });

  group('signed in, spaces ready', () {
    test('auth and splash screens open Today (no forced team setup)', () {
      for (final location in [AppRoutes.splash, ...AppRoutes.signedOutRoutes]) {
        expect(
          go(AuthStatus.signedIn, SpacesStatus.ready, location),
          AppRoutes.today,
          reason: location,
        );
      }
    });

    test('tabs and the new-space screen stay', () {
      for (final location in [..._tabs, AppRoutes.newSpace]) {
        expect(go(AuthStatus.signedIn, SpacesStatus.ready, location), isNull);
      }
    });
  });

  test('spaces loading or failed: splash (with retry)', () {
    for (final spaces in [SpacesStatus.loading, SpacesStatus.error]) {
      expect(
        go(AuthStatus.signedIn, spaces, AppRoutes.today),
        AppRoutes.splash,
      );
      expect(go(AuthStatus.signedIn, spaces, AppRoutes.splash), isNull);
    }
  });
}
