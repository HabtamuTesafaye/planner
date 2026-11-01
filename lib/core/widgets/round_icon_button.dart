import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Round icon button on a surface circle, for actions at the top of a page
/// (for example Insights on Today). 48 dp, with a tooltip for TalkBack.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        fixedSize: const Size.square(AppSizes.touchTarget),
        side: BorderSide(color: colors.cardEdge),
        shape: const CircleBorder(),
      ),
    );
  }
}
