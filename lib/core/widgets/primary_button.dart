import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Full-width main action. While [loading], it is disabled and shows a
/// tiny spinner, so a form can never be submitted twice.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
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
    );
  }
}
