import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// A soft wash of the accent at the top of a page, fading into the page
/// color. Static (painted once), so it costs nothing while scrolling.
class PageWash extends StatelessWidget {
  const PageWash({required this.child, super.key});

  final Widget child;

  /// Where the wash has faded into the page color (share of height).
  static const double _end = 0.45;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.accentSoft, colors.background],
          stops: const [0, _end],
        ),
      ),
      child: child,
    );
  }
}
