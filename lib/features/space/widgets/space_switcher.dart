import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../data/models/space.dart';
import '../providers/space_providers.dart';
import 'space_sheet.dart';

IconData spaceIcon(Space space) =>
    space.isPersonal ? Symbols.person : Symbols.group;

/// Current space name with a chevron. Tap to switch, create or join.
/// Sits above the title on every tab except Today.
class SpaceSwitcher extends ConsumerWidget {
  const SpaceSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(currentSpaceProvider);
    final colors = context.colors;
    if (space == null) return const SizedBox(height: AppSizes.touchTarget);

    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'Space: ${space.name}. Double tap to switch space.',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => showSpaceSheet(context),
          borderRadius: AppRadius.controlAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    spaceIcon(space),
                    size: AppSizes.iconSmall,
                    color: colors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      space.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                  ),
                  Icon(
                    Symbols.expand_more,
                    size: AppSizes.iconSmall,
                    color: colors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
