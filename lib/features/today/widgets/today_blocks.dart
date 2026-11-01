import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';

class TodayErrorBlock extends StatelessWidget {
  const TodayErrorBlock({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: context.text.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// Gentle Sunday/Monday nudge when the weekly review is missing.
class ReviewPrompt extends StatelessWidget {
  const ReviewPrompt({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.accentSoft,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Symbols.edit_note, color: colors.accentText),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Take two minutes for your weekly review.',
                  style: context.text.bodyLarge,
                ),
              ),
              Icon(Symbols.chevron_right, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
