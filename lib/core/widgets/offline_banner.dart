import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Calm strip shown when there is no connection. Visual only in Phase 0;
/// connectivity wiring arrives in Phase 7.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.visible, super.key});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedSize(
      duration: AppDurations.normal,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  border: Border(bottom: BorderSide(color: colors.divider)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.cloud_off,
                      size: AppSizes.iconSmall,
                      color: colors.muted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        "You're offline. Turn on mobile data or Wi-Fi to save changes.",
                        style: context.text.bodySmall!.copyWith(
                          color: colors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
