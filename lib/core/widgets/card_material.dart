import 'package:flutter/material.dart';

import '../theme/app_decor.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// A soft surface card that ink (taps) can draw on. Same look as
/// [AppDecor.card]; put an [InkWell] inside for a tappable card.
class CardMaterial extends StatelessWidget {
  const CardMaterial({
    required this.child,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecor.card(context.colors),
      child: Material(
        type: MaterialType.transparency,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}
