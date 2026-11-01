import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context.dart';

/// A single headline number with a short label and an optional note.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    this.note,
    super.key,
  });

  final String value;
  final String label;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Semantics(
      label: '$label: $value${note == null ? '' : ', $note'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.controlAll,
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: text.headlineMedium!.copyWith(
                  fontFeatures: AppTextStyles.tabular,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: text.labelMedium),
            if (note != null) Text(note!, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Two tiles per row on phones, wrapping at large text sizes.
class StatGrid extends StatelessWidget {
  const StatGrid({required this.tiles, super.key});

  final List<StatTile> tiles;

  /// Above this text scale, tiles stack one per row so numbers stay whole.
  static const double _oneColumnAboveTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final perRow = scale > _oneColumnAboveTextScale ? 1 : 2;
        final width =
            (constraints.maxWidth - AppSpacing.md * (perRow - 1)) / perRow;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}
