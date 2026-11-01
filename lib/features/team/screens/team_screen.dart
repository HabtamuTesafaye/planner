import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/team_providers.dart';
import '../widgets/invite_code_card.dart';
import '../widgets/leave_team_dialog.dart';
import '../widgets/member_row.dart';

/// Team tab (temporary version for Phase 2): team name, invite code,
/// members, sign out and leave team. Progress cards arrive in Phase 6.
class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  bool _busy = false;

  Future<void> _refresh() async {
    ref.invalidate(currentTeamProvider);
    try {
      await ref.read(teamMembersProvider.future);
    } on AppException catch (e) {
      _showMessage(e.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AppException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(String teamName) async {
    final members = ref.read(teamMembersProvider).value ?? const [];
    final confirmed = await confirmLeaveTeam(
      context,
      teamName: teamName,
      members: members,
      myUserId: ref.read(currentUserIdProvider).value,
    );
    if (!confirmed) return;
    await _run(() async {
      await ref.read(teamRepositoryProvider).leaveTeam();
      // The router sends us to team setup once the team is gone.
      ref.invalidate(currentTeamProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(currentTeamProvider).value;
    final members = ref.watch(teamMembersProvider);
    final myId = ref.watch(currentUserIdProvider).value;
    final colors = context.colors;

    return PageBody(
      title: 'Team',
      onRefresh: _refresh,
      children: [
        if (team != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            team.name,
            style: context.text.titleLarge!.copyWith(color: colors.muted),
          ),
          const SectionHeader(title: 'Invite code'),
          InviteCodeCard(code: team.joinCode),
        ],
        const SectionHeader(title: 'Members'),
        switch (members) {
          AsyncData(:final value) => Column(
            children: [
              for (final m in value)
                MemberRow(member: m, isMe: m.userId == myId),
            ],
          ),
          AsyncError(:final error) => Text(
            AppException.from(error).message,
            style: context.text.bodyMedium!.copyWith(color: colors.attention),
          ),
          _ => const SkeletonList(rows: 2),
        },
        const SizedBox(height: AppSpacing.xxl),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(() => ref.read(authRepositoryProvider).signOut()),
          child: const Text('Sign out'),
        ),
        if (team != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _busy ? null : () => _leave(team.name),
            style: TextButton.styleFrom(foregroundColor: colors.attention),
            child: const Text('Leave team'),
          ),
        ],
      ],
    );
  }
}
