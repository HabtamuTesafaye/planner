import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/connectivity.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Full-width main action. While [loading], it is disabled and shows a
/// tiny spinner, so a form can never be submitted twice. When
/// [needsNetwork] and the phone is offline, it pauses with a short reason;
/// whatever was typed stays in the form.
class PrimaryButton extends ConsumerWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.needsNetwork = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool needsNetwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = needsNetwork && !ref.watch(isOnlineProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: loading || offline ? null : onPressed,
          child: AnimatedSwitcher(
            duration: AppDurations.fast,
            child: loading
                ? Semantics(
                    key: const ValueKey('loading'),
                    label: '$label, working',
                    child: const SizedBox.square(
                      dimension: AppSizes.inlineSpinner,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.inlineSpinnerStroke,
                      ),
                    ),
                  )
                : Text(label, key: const ValueKey('label')),
          ),
        ),
        if (offline)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'You’re offline. Saving is paused; what you typed is kept.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ),
      ],
    );
  }
}
