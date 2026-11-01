import 'package:flutter/material.dart';

/// Design tokens for color, light and dark (AGENTS.md section 7).
///
/// Exposed as a [ThemeExtension] so screens read colors from the theme
/// (`context.colors.muted`) and never hardcode them.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceSunken,
    required this.text,
    required this.muted,
    required this.divider,
    required this.border,
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
  });

  /// Page background.
  final Color background;

  /// Cards, sheets, inputs.
  final Color surface;

  /// Slightly darker than [background]: skeletons, inactive tracks.
  final Color surfaceSunken;

  /// Primary text.
  final Color text;

  /// Secondary text (still AA on background and surface).
  final Color muted;

  /// Hairline dividers.
  final Color divider;

  /// Input and outlined button borders (stronger than [divider]).
  final Color border;

  /// Brand accent for non-text use: icons, indicators, progress (3:1 rule).
  final Color accent;

  /// Accent for text and filled buttons. In light mode the brand accent
  /// `#D9480F` is only 3.9:1 on the background, so text uses a slightly
  /// deeper shade that passes WCAG AA (4.5:1). In dark mode it equals [accent].
  final Color accentText;

  /// Text and icons placed on an [accentText] fill.
  final Color onAccent;

  /// Very light accent wash: selected chips, nav indicator.
  final Color accentSoft;

  /// Completed state.
  final Color success;

  /// Very light success wash.
  final Color successSoft;

  static const AppColors light = AppColors(
    background: Color(0xFFF6F3EE),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEDE8E0),
    text: Color(0xFF1A1A1A),
    muted: Color(0xFF6B665E),
    divider: Color(0xFFE4DED4),
    border: Color(0xFFCFC7BA),
    accent: Color(0xFFD9480F),
    accentText: Color(0xFFBC3E0B),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFFBE6DC),
    success: Color(0xFF2F7D4F),
    successSoft: Color(0xFFE2F0E7),
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF141311),
    surface: Color(0xFF1D1B19),
    surfaceSunken: Color(0xFF262320),
    text: Color(0xFFF2EEE8),
    muted: Color(0xFFA39D93),
    divider: Color(0xFF2E2B27),
    border: Color(0xFF45403A),
    accent: Color(0xFFF26B38),
    accentText: Color(0xFFF26B38),
    onAccent: Color(0xFF141311),
    accentSoft: Color(0xFF3A231A),
    success: Color(0xFF5BB27F),
    successSoft: Color(0xFF1C2E23),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSunken,
    Color? text,
    Color? muted,
    Color? divider,
    Color? border,
    Color? accent,
    Color? accentText,
    Color? onAccent,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      divider: l(divider, other.divider),
      border: l(border, other.border),
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
    );
  }
}
