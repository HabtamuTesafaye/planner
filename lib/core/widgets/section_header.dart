import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Small uppercase-free label that starts a section, with an optional
/// trailing action (for example "Edit").
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.text.labelMedium!.copyWith(
                  color: context.colors.muted,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
