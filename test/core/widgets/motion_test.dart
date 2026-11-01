import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/theme/app_motion.dart';
import 'package:planner/core/theme/app_theme.dart';
import 'package:planner/core/widgets/brand_mark.dart';
import 'package:planner/core/widgets/fade_through_stack.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('FadeSlideIn starts hidden and settles fully visible', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const FadeSlideIn(child: Text('Hello'))));
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 0);
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('with "Remove animations" on, content appears at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const FadeSlideIn(child: Text('Hello')), reduceMotion: true),
    );
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);

    await tester.pumpWidget(
      _app(const BrandMark(animate: true), reduceMotion: true),
    );
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });

  testWidgets('each entrance movement lasts at most 250 ms', (tester) async {
    await tester.pumpWidget(
      _app(const FadeSlideIn(index: 3, child: Text('x'))),
    );
    final builder = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    final interval = builder.curve as Interval;
    final moving = builder.duration * (interval.end - interval.begin);
    expect(moving.inMilliseconds, lessThanOrEqualTo(250));
  });

  testWidgets('hidden tabs cannot be tapped or read by TalkBack', (
    tester,
  ) async {
    var tappedHidden = false;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        FadeThroughStack(
          index: 0,
          children: [
            const Center(child: Text('Visible tab')),
            Center(
              child: TextButton(
                onPressed: () => tappedHidden = true,
                child: const Text('Hidden tab'),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Visible tab'), findsOneWidget);
    expect(find.bySemanticsLabel('Hidden tab'), findsNothing);
    await tester.tap(find.text('Hidden tab'), warnIfMissed: false);
    expect(tappedHidden, isFalse);
    handle.dispose();
  });

  testWidgets('BrandMark draws at the requested width', (tester) async {
    await tester.pumpWidget(_app(const Center(child: BrandMark(size: 80))));
    final size = tester.getSize(find.byType(CustomPaint).last);
    expect(size.width, 80);
  });
}
