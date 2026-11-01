import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../data/models/space.dart';
import '../../../router_redirect.dart';
import '../providers/space_providers.dart';
import 'space_switcher.dart';

/// Bottom sheet: every space (tap to switch), then create or join.
Future<void> showSpaceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _SpaceSheet(),
  );
}

class _SpaceSheet extends ConsumerWidget {
  const _SpaceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(mySpacesProvider).value ?? const <Space>[];
    final current = ref.watch(currentSpaceProvider);
    final colors = context.colors;

    void openNew(String mode) {
      Navigator.of(context).pop();
      unawaited(
        context.push(
          Uri(
            path: AppRoutes.newSpace,
            queryParameters: {'mode': mode},
          ).toString(),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Semantics(
                header: true,
                child: Text('Spaces', style: context.text.headlineSmall),
              ),
            ),
            for (final space in spaces)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                leading: Icon(spaceIcon(space), color: colors.accent),
                title: Text(
                  space.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  space.isPersonal ? 'Only you' : 'Team space',
                  style: context.text.bodySmall,
                ),
                selected: space.id == current?.id,
                selectedColor: colors.text,
                trailing: space.id == current?.id
                    ? Icon(Symbols.check, color: colors.accentText)
                    : null,
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  unawaited(
                    ref.read(selectedSpaceIdProvider.notifier).select(space.id),
                  );
                  Navigator.of(context).pop();
                },
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              leading: Icon(Symbols.add, color: colors.accentText),
              title: const Text('New team space'),
              onTap: () => openNew('create'),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              leading: Icon(Symbols.key, color: colors.accentText),
              title: const Text('Join with a code'),
              onTap: () => openNew('join'),
            ),
          ],
        ),
      ),
    );
  }
}
