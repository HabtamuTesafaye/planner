import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/theme/app_theme.dart';
import 'package:planner/core/widgets/circle_check.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('toggles and exposes checkbox semantics', (tester) async {
    var value = false;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => CircleCheck(
            value: value,
            label: 'Call Abebe',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byType(CircleCheck)),
      matchesSemantics(
        label: 'Call Abebe',
        hasCheckedState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(CircleCheck));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(
      tester.getSemantics(find.byType(CircleCheck)),
      matchesSemantics(
        label: 'Call Abebe',
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('tap target is at least 48 dp', (tester) async {
    await tester.pumpWidget(
      _wrap(CircleCheck(value: false, label: 'x', onChanged: (_) {})),
    );
    final size = tester.getSize(find.byType(CircleCheck));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('disabled when onChanged is null', (tester) async {
    await tester.pumpWidget(
      _wrap(const CircleCheck(value: false, label: 'x', onChanged: null)),
    );
    await tester.tap(find.byType(CircleCheck));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
