import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// One row of a grouped list: rows sit together on a rounded surface card,
/// separated by inset hairlines. Works in lazy lists too: pass whether the
/// row is the first and last of its group. Swipe backgrounds inside are
/// clipped to the card's shape.
class GroupTile extends StatelessWidget {
  const GroupTile({
    required this.child,
    required this.isFirst,
    required this.isLast,
    super.key,
  });

  final Widget child;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const radius = Radius.circular(AppRadius.card);
    final shape = BorderRadius.vertical(
      top: isFirst ? radius : Radius.zero,
      bottom: isLast ? radius : Radius.zero,
    );
    final side = BorderSide(color: colors.cardEdge);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        border: Border(
          left: side,
          right: side,
          top: isFirst ? side : BorderSide.none,
          bottom: isLast ? side : BorderSide.none,
        ),
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: ColoredBox(
          color: colors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  child: Divider(height: 1, color: colors.divider),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A whole group at once, for short lists that are not lazy.
class GroupedSection extends StatelessWidget {
  const GroupedSection({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, child) in children.indexed)
          GroupTile(
            isFirst: i == 0,
            isLast: i == children.length - 1,
            child: child,
          ),
      ],
    );
  }
}
