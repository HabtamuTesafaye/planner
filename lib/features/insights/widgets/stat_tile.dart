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
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final perRow = scale > _oneColumnAboveTextScale ? 1 : 2;
    final rows = [
      for (var i = 0; i < tiles.length; i += perRow)
        tiles.sublist(i, (i + perRow).clamp(0, tiles.length)),
    ];
    return Column(
      children: [
        for (final (r, row) in rows.indexed) ...[
          if (r > 0) const SizedBox(height: AppSpacing.md),
          // Tiles in a row share one height.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, tile) in row.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(child: tile),
                ],
                // Keep a lone last tile at half width.
                if (row.length < perRow) ...[
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
