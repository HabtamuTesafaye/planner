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
    required this.attention,
    required this.success,
    required this.successSoft,
    required this.activity,
    required this.shadow,
    required this.cardEdge,
    required this.teal,
    required this.tealSoft,
    required this.amber,
    required this.amberSoft,
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

  /// Stormy blue brand accent: primary actions, active tab, indicators.
  final Color accent;

  /// Accent used for text and filled buttons. Equal to [accent] in this
  /// palette (both pass WCAG AA); kept separate so the brand color can
  /// change without breaking text contrast.
  final Color accentText;

  /// Text and icons placed on an [accentText] fill.
  final Color onAccent;

  /// Very light accent wash: selected chips, nav indicator.
  final Color accentSoft;

  /// Warm clay for things that need attention: overdue follow-ups, errors.
  final Color attention;

  /// Completed state.
  final Color success;

  /// Very light success wash.
  final Color successSoft;

  /// Activity heatmap ramp for 1, 2 and 3 tasks done (one hue, light to
  /// dark; validated with the data-viz palette checks against the card
  /// surface in each theme). Zero uses [surfaceSunken].
  final List<Color> activity;

  /// Soft shadow under cards (light theme only; dark uses [cardEdge]).
  final Color shadow;

  /// Hairline around cards: invisible in light (the shadow lifts them),
  /// a divider line in dark where shadows don't show.
  final Color cardEdge;

  /// Extra hues for the round quick actions on Today, so each action is
  /// recognisable at a glance. Icon color on its soft wash (3:1 or more).
  final Color teal;
  final Color tealSoft;
  final Color amber;
  final Color amberSoft;

  static const AppColors light = AppColors(
    background: Color(0xFFF3F1EC),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE9E6DF),
    text: Color(0xFF1B2430),
    muted: Color(0xFF5D6570),
    divider: Color(0xFFE2DFD8),
    border: Color(0xFF828993),
    accent: Color(0xFF2E4A6B),
    accentText: Color(0xFF2E4A6B),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE1E8F0),
    attention: Color(0xFFA9431A),
    success: Color(0xFF2A7046),
    successSoft: Color(0xFFE2F0E7),
    activity: [Color(0xFF86C09E), Color(0xFF4C9A6C), Color(0xFF2A7046)],
    shadow: Color(0x101B2430),
    cardEdge: Color(0x00FFFFFF),
    teal: Color(0xFF1D6670),
    tealSoft: Color(0xFFDCEEEF),
    amber: Color(0xFF85570A),
    amberSoft: Color(0xFFF6EAD2),
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF121519),
    surface: Color(0xFF1A1E24),
    surfaceSunken: Color(0xFF232830),
    text: Color(0xFFECEEF1),
    muted: Color(0xFF9BA4AF),
    divider: Color(0xFF272C34),
    border: Color(0xFF6B7380),
    accent: Color(0xFF8EB0D6),
    accentText: Color(0xFF8EB0D6),
    onAccent: Color(0xFF121519),
    accentSoft: Color(0xFF1F2C3C),
    attention: Color(0xFFF0905F),
    success: Color(0xFF5BB27F),
    successSoft: Color(0xFF1C2E23),
    activity: [Color(0xFF2C5640), Color(0xFF3F8A5E), Color(0xFF6CC392)],
    shadow: Color(0x00000000),
    cardEdge: Color(0xFF272C34),
    teal: Color(0xFF72C6CE),
    tealSoft: Color(0xFF172E32),
    amber: Color(0xFFE3B462),
    amberSoft: Color(0xFF332818),
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
    Color? attention,
    Color? success,
    Color? successSoft,
    List<Color>? activity,
    Color? shadow,
    Color? cardEdge,
    Color? teal,
    Color? tealSoft,
    Color? amber,
    Color? amberSoft,
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
      attention: attention ?? this.attention,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      activity: activity ?? this.activity,
      shadow: shadow ?? this.shadow,
      cardEdge: cardEdge ?? this.cardEdge,
      teal: teal ?? this.teal,
      tealSoft: tealSoft ?? this.tealSoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
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
      attention: l(attention, other.attention),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      activity: [
        for (var i = 0; i < activity.length; i++)
          l(activity[i], other.activity[i]),
      ],
      shadow: l(shadow, other.shadow),
      cardEdge: l(cardEdge, other.cardEdge),
      teal: l(teal, other.teal),
      tealSoft: l(tealSoft, other.tealSoft),
      amber: l(amber, other.amber),
      amberSoft: l(amberSoft, other.amberSoft),
    );
  }
}
