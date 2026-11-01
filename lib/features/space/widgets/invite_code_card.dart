import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_decor.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/join_code.dart';

/// The team's invite code, large and readable, with a copy button.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({required this.code, this.spaceName, super.key});

  final String code;
  final String? spaceName;

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Join ${spaceName ?? 'my space'} on Planner',
        text:
            'Join ${spaceName ?? 'my space'} on Planner. Open the app, tap the '
            'space name at the top, choose "Join with a code" and enter: '
            '${JoinCode.display(code)}',
      ),
    );
  }

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
      decoration: AppDecor.card(colors),
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
          IconButton(
            onPressed: _share,
            tooltip: 'Share invite',
            icon: const Icon(Symbols.share),
          ),
        ],
      ),
    );
  }
}
