import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planner/core/widgets/circle_check.dart';
import 'package:planner/data/app_exception.dart';
import 'package:planner/data/repositories/auth_repository.dart';
import 'package:planner/data/repositories/space_repository.dart';
import 'package:planner/features/auth/screens/check_email_screen.dart';
import 'package:planner/features/auth/screens/sign_in_screen.dart';
import 'package:planner/features/auth/screens/sign_up_screen.dart';
import 'package:planner/features/auth/screens/welcome_screen.dart';
import 'package:planner/features/auth/widgets/today_preview.dart';
import 'package:planner/features/space/screens/new_space_screen.dart';

import '../../helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSpaceRepository extends Mock implements SpaceRepository {}

void main() {
  testWidgets('Google: not switched on shows a calm message', (tester) async {
    final auth = MockAuthRepository();
    when(
      auth.signInWithGoogle,
    ).thenThrow(const AppException(AppErrorKind.googleNotSetUp));
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const SignInScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    final google = find.text('Continue with Google');
    await tester.ensureVisible(google);
    await tester.pumpAndSettle();
    await tester.tap(google);
    await tester.pumpAndSettle();
    verify(auth.signInWithGoogle).called(1);
    expect(
      find.text(const AppException(AppErrorKind.googleNotSetUp).message),
      findsOneWidget,
    );
    expect(google, findsOneWidget); // Button is usable again.
  });

  group('screens fit a small phone at 1.5x text, both themes', () {
    final screens = <String, Widget>{
      'welcome': const WelcomeScreen(),
      'sign in': const SignInScreen(),
      'sign up': const SignUpScreen(),
      'check email': const CheckEmailScreen(email: 'someone@example.com'),
      'new space': const NewSpaceScreen(),
      'join space': const NewSpaceScreen(initialMode: NewSpaceMode.join),
    };
    for (final brightness in Brightness.values) {
      screens.forEach((name, screen) {
        testWidgets('$name ($brightness)', (tester) async {
          useSmallPhone(tester, brightness: brightness);
          await pumpScreen(tester, screen);
          expect(tester.takeException(), isNull);
        });
      });
    }
  });

  testWidgets('sign in: empty form shows field errors, no request', (
    tester,
  ) async {
    final auth = MockAuthRepository();
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const SignInScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    verifyNever(
      () => auth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('sign in: wrong password shows a friendly message', (
    tester,
  ) async {
    final auth = MockAuthRepository();
    when(
      () => auth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AppException(AppErrorKind.wrongCredentials));
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const SignInScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextFormField).at(1), 'nope');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(
      find.text(const AppException(AppErrorKind.wrongCredentials).message),
      findsOneWidget,
    );
  });

  testWidgets('join space: a wrong code shows a friendly message', (
    tester,
  ) async {
    final teams = MockSpaceRepository();
    when(() => teams.joinSpace(any()))
        .thenThrow(const AppException(AppErrorKind.invalidCode));
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const NewSpaceScreen(),
      overrides: [spaceRepositoryProvider.overrideWithValue(teams)],
    );
    await tester.tap(find.text('Join with code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'abcd efgh');
    expect(find.text('ABCDEFGH'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Join space'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Join space'));
    await tester.pumpAndSettle();
    verify(() => teams.joinSpace('ABCDEFGH')).called(1);
    expect(
      find.text(const AppException(AppErrorKind.invalidCode).message),
      findsOneWidget,
    );
  });

  testWidgets('password field can be shown and hidden', (tester) async {
    useSmallPhone(tester);
    await pumpScreen(tester, const SignUpScreen());
    EditableText password() =>
        tester.widget<EditableText>(find.byType(EditableText).last);
    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('welcome preview ticks the first task by itself', (tester) async {
    useSmallPhone(tester);
    await pumpScreen(tester, const WelcomeScreen());
    bool firstDone() =>
        tester.widget<CircleCheck>(find.byType(CircleCheck).first).value;
    expect(firstDone(), isFalse);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(firstDone(), isTrue);
    expect(find.text('1 of 3'), findsOneWidget);
  });

  testWidgets('welcome preview circles can be tapped', (tester) async {
    useSmallPhone(tester);
    await pumpScreen(
      tester,
      const Scaffold(
        body: Center(child: TodayPreview(autoCheckAfter: Duration(hours: 1))),
      ),
    );
    await tester.tap(find.byType(CircleCheck).at(1));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsOneWidget);
  });
}
