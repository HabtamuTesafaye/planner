import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Motion rules (AGENTS.md section 7):
/// * Implicit animations only. Each movement lasts 250 ms or less.
/// * Entrances may be staggered: every element still moves for at most
///   [AppDurations.slow]; only its start is delayed.
/// * Material 3 easing: emphasized decelerate for things arriving.
/// * Respect the system "Remove animations" setting: everything appears
///   immediately.
abstract final class AppMotion {
  static const Curve enter = Easing.emphasizedDecelerate;
  static const Curve exit = Easing.emphasizedAccelerate;
  static const Curve standard = Easing.standard;

  /// Gap between staggered items.
  static const Duration stagger = Duration(milliseconds: 60);

  /// How far entering content travels, as a fraction of its height.
  static const double rise = 0.08;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when animations are turned off.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}

/// Fades and rises its child into place once, after [delay]. Use [index]
/// for a staggered list (delay = index × [AppMotion.stagger]).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final int index;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    final wait = delay + AppMotion.stagger * index;
    final total = wait + AppDurations.slow;
    final start = wait.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: AppMotion.enter),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: FractionalTranslation(
          translation: Offset(0, (1 - t) * AppMotion.rise),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
