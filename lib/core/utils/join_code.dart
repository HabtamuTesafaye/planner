import 'package:flutter/services.dart';

/// Join codes are 8 characters from an alphabet without look-alikes
/// (no 0/O, 1/I/L). Matches the database check in 002_teams.
abstract final class JoinCode {
  static const int length = 8;
  static const String alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Uppercases and drops spaces, dashes and anything outside the alphabet.
  static String normalize(String input) {
    final upper = input.toUpperCase();
    final buffer = StringBuffer();
    for (final rune in upper.runes) {
      final char = String.fromCharCode(rune);
      if (alphabet.contains(char)) buffer.write(char);
    }
    return buffer.toString();
  }

  static bool isComplete(String input) => normalize(input).length == length;

  /// Shows a code in two groups for easier reading: `ABCD EFGH`.
  static String display(String code) {
    final c = normalize(code);
    if (c.length <= 4) return c;
    return '${c.substring(0, 4)} ${c.substring(4)}';
  }
}

/// Text field formatter: uppercase, no spaces, only valid characters,
/// max 8. Pasting "abcd-efgh" becomes "ABCDEFGH".
class JoinCodeInputFormatter extends TextInputFormatter {
  const JoinCodeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = JoinCode.normalize(newValue.text);
    if (text.length > JoinCode.length) {
      text = text.substring(0, JoinCode.length);
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
