import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planner/data/connectivity.dart';
import 'package:planner/data/models/space.dart';
import 'package:planner/features/auth/providers/auth_providers.dart';
import 'package:planner/features/auth/screens/splash_screen.dart';
import 'package:planner/features/space/providers/space_providers.dart';

import '../../helpers.dart';

void main() {
  testWidgets('opening offline says so, and retries by itself when back', (
    tester,
  ) async {
    useSmallPhone(tester);
    final network = StreamController<bool>();
    addTearDown(network.close);
    var loads = 0;
    await pumpScreen(
      tester,
      const SplashScreen(),
      overrides: [
        connectivityProvider.overrideWith((ref) => network.stream),
        currentUserIdProvider.overrideWith((ref) => Stream.value('u1')),
        mySpacesProvider.overrideWith((ref) async {
          loads++;
          return Completer<List<Space>>().future; // Never answers offline.
        }),
      ],
    );
    network.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.textContaining('mobile data or Wi-Fi'), findsOneWidget);
    expect(find.text('Getting your spaces ready…'), findsNothing);

    final before = loads;
    network.add(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(loads, greaterThan(before));
    expect(find.text("You're offline"), findsNothing);
  });
}
