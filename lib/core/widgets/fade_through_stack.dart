import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// Keeps every tab alive (scroll position and state survive) but shows only
/// the active one, with a short Material fade-through: the old tab fades
/// out while the new one fades in and settles from 98% scale.
///
/// Inactive tabs don't paint (opacity 0), can't be tapped, are hidden from
/// TalkBack, and have their animations paused (TickerMode).
class FadeThroughStack extends StatelessWidget {
  const FadeThroughStack({
    required this.index,
    required this.children,
    super.key,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppDurations.normal);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _Page(active: i == index, duration: duration, child: children[i]),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.active,
    required this.duration,
    required this.child,
  });

  final bool active;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: ExcludeFocus(
          excluding: !active,
          child: TickerMode(
            enabled: active,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: duration,
              curve: active ? AppMotion.enter : AppMotion.exit,
              child: AnimatedScale(
                scale: active ? 1 : 0.98,
                duration: duration,
                curve: AppMotion.enter,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
