import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Shown instead of the app when the Supabase settings were not passed at
/// build time. Explains exactly how to fix it; never crashes.
class SetupNeededScreen extends StatelessWidget {
  const SetupNeededScreen({required this.problems, super.key});

  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Icon(Symbols.settings, color: colors.accent),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text('Setup needed', style: text.headlineMedium),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This build was made without its server settings, so it '
                  "can't connect yet.",
                  style: text.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final p in problems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      '• $p',
                      style: text.bodyMedium!.copyWith(color: colors.muted),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text('To fix it, run:', style: text.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceSunken,
                    borderRadius: AppRadius.controlAll,
                  ),
                  child: SelectableText(
                    'flutter run --dart-define-from-file=env/staging.json',
                    style: text.bodySmall!.copyWith(
                      color: colors.text,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'See README.md for how to create env/staging.json.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
