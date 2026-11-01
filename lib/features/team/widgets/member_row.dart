import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../data/models/team_member.dart';

/// One member: name, plus "you" and "owner" labels.
class MemberRow extends StatelessWidget {
  const MemberRow({required this.member, required this.isMe, super.key});

  final TeamMember member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labels = [if (isMe) 'you', if (member.isOwner) 'owner'];
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(member.displayName, style: context.text.bodyLarge),
          ),
          if (labels.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              labels.join(' · '),
              style: context.text.labelMedium!.copyWith(color: colors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
