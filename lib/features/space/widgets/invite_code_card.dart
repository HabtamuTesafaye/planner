import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/join_code.dart';

/// The team's invite code, large and readable, with a copy button.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({required this.code, super.key});

  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Invite code copied')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.controlAll,
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Invite code ${code.split('').join(' ')}',
                  excludeSemantics: true,
                  child: Text(
                    JoinCode.display(code),
                    style: context.text.headlineSmall!.copyWith(
                      letterSpacing: AppTextStyles.codeTrackingLarge,
                      fontFeatures: AppTextStyles.tabular,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your teammate enters this code to join.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copy(context),
            tooltip: 'Copy invite code',
            icon: const Icon(Symbols.content_copy),
          ),
        ],
      ),
    );
  }
}
