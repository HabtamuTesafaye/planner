import 'package:flutter/material.dart';

import '../theme/app_decor.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// One tab of [FloatingNavBar].
class NavItem {
  const NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Bottom navigation as a floating pill. Each tab is a round 48 dp button;
/// the selected one fills with the accent and grows to show its name when
/// there is room.
/// Every tab has a tooltip and is announced as a selected or unselected
/// tab by TalkBack.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.maxContentWidth,
                minHeight: AppSizes.navBar,
              ),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: colors.surface,
                  shape: StadiumBorder(
                    side: BorderSide(color: colors.cardEdge),
                  ),
                  shadows: AppDecor.shadow(colors),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showLabel = _labelFits(
                        context,
                        constraints.maxWidth,
                      );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final (i, item) in items.indexed)
                            _NavButton(
                              item: item,
                              selected: i == selectedIndex,
                              showLabel: showLabel,
                              onTap: () => onSelect(i),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Whether the selected tab's name fits next to its icon, with every
  /// other tab still a full round button. On narrow phones or large text
  /// it doesn't, and the selected tab is shown by its fill alone (the name
  /// stays in the tooltip and for TalkBack).
  bool _labelFits(BuildContext context, double width) {
    final style = context.text.labelMedium!;
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(text: items[selectedIndex].label, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final label = painter.width;
    painter.dispose();
    const grow = AppSpacing.sm + (AppSpacing.lg - AppSpacing.md) * 2;
    return items.length * AppSizes.navItem + label + grow <= width;
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = selected ? colors.onAccent : colors.muted;
    final expanded = selected && showLabel;
    final button = Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        excludeFromSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppDurations.normal,
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(
                minWidth: AppSizes.navItem,
                minHeight: AppSizes.navItem,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? AppSpacing.lg : AppSpacing.md,
              ),
              decoration: ShapeDecoration(
                color: selected ? colors.accentText : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: fg,
                    size: AppSizes.icon,
                    weight: selected ? 500 : 300,
                  ),
                  if (expanded) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: context.text.labelMedium!.copyWith(color: fg),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // The selected tab takes the free space it needs; the others stay round.
    return expanded ? Flexible(child: button) : button;
  }
}
