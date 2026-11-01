import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release builds keep the reminder icon (resource shrinking)', () {
    final keep = File('android/app/src/main/res/raw/keep.xml');
    expect(keep.existsSync(), isTrue);
    expect(keep.readAsStringSync(), contains('@drawable/ic_stat_planner'));
    expect(
      File('android/app/src/main/res/drawable-mdpi/ic_stat_planner.png')
          .existsSync(),
      isTrue,
    );
  });
}
