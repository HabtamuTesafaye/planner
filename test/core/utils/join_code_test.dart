import 'package:flutter_test/flutter_test.dart';
import 'package:planner/core/utils/join_code.dart';

TextEditingValue type(String text) => const JoinCodeInputFormatter()
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  group('normalize', () {
    test('uppercases and trims spaces', () {
      expect(JoinCode.normalize('  abcd efgh  '), 'ABCDEFGH');
    });

    test('drops dashes and other separators', () {
      expect(JoinCode.normalize('abcd-efgh'), 'ABCDEFGH');
      expect(JoinCode.normalize('AB.CD_EF/GH'), 'ABCDEFGH');
    });

    test('drops look-alike characters not in the alphabet', () {
      // 0, O, 1, I and L are never in a code.
      expect(JoinCode.normalize('A0O1IL2B'), 'A2B');
    });

    test('isComplete needs exactly 8 valid characters', () {
      expect(JoinCode.isComplete('abcd efgh'), isTrue);
      expect(JoinCode.isComplete('ABCDEFG'), isFalse);
    });
  });

  group('input formatter', () {
    test('typed lowercase becomes uppercase', () {
      expect(type('abc').text, 'ABC');
    });

    test('pasted code with spaces or dash is cleaned', () {
      expect(type(' abcd-efgh ').text, 'ABCDEFGH');
    });

    test('stops at 8 characters', () {
      expect(type('ABCDEFGHJK').text, 'ABCDEFGH');
    });

    test('cursor goes to the end', () {
      expect(type('ab cd').selection.baseOffset, 4);
    });
  });

  test('display groups the code in two halves', () {
    expect(JoinCode.display('ABCDEFGH'), 'ABCD EFGH');
    expect(JoinCode.display('abc'), 'ABC');
  });
}
