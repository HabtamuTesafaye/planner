import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/space.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/space_repository.dart';
import '../../../router_redirect.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/space_providers.dart';
import '../widgets/invite_code_card.dart';
import '../widgets/leave_space_dialog.dart';
import '../widgets/member_row.dart';
import '../widgets/space_switcher.dart';

/// Space tab: about the current space. Personal: what it is, and how to
/// start or join a team space. Team: invite code, members, leave.
/// Progress cards and settings arrive in Phase 6.
class SpaceScreen extends ConsumerStatefulWidget {
  const SpaceScreen({super.key});

  @override
  ConsumerState<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends ConsumerState<SpaceScreen> {
  bool _busy = false;

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

  Future<void> _refresh() async {
    ref
      ..invalidate(mySpacesProvider)
      ..invalidate(spaceMembersProvider);
    try {
      await ref.read(spaceMembersProvider.future);
    } on AppException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _leave(Space space) async {
    final members = ref.read(spaceMembersProvider).value ?? const [];
    final confirmed = await confirmLeaveSpace(
      context,
      spaceName: space.name,
      members: members,
      myUserId: ref.read(currentUserIdProvider).value,
    );
    if (!confirmed) return;
    await _run(() async {
      await ref.read(spaceRepositoryProvider).leaveSpace(space.id);
      final personal = (ref.read(mySpacesProvider).value ?? const <Space>[])
          .where((s) => s.isPersonal)
          .firstOrNull;
      if (personal != null) {
        await refreshAndSelect(ref, personal.id);
      } else {
        ref.invalidate(mySpacesProvider);
      }
      _showMessage('You left ${space.name}.');
    });
  }

  void _openNew(String mode) => context.push(
    Uri(path: AppRoutes.newSpace, queryParameters: {'mode': mode}).toString(),
  );

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(currentSpaceProvider);
    final colors = context.colors;

    return PageBody(
      title: 'Space',
      top: const SpaceSwitcher(),
      onRefresh: _refresh,
      children: [
        if (space == null)
          const SkeletonList(rows: 2)
        else if (space.isPersonal) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your private space. Only you can see what you keep here.',
            style: context.text.bodyLarge!.copyWith(color: colors.muted),
          ),
          const SectionHeader(title: 'Work with others'),
          OutlinedButton.icon(
            onPressed: () => _openNew('create'),
            icon: const Icon(Symbols.add),
            label: const Text('Create a team space'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _openNew('join'),
            icon: const Icon(Symbols.key),
            label: const Text('Join with a code'),
          ),
        ] else
          ..._teamSection(space),
        const SizedBox(height: AppSpacing.xxl),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(() => ref.read(authRepositoryProvider).signOut()),
          child: const Text('Sign out'),
        ),
        if (space != null && !space.isPersonal) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _busy ? null : () => _leave(space),
            style: TextButton.styleFrom(foregroundColor: colors.attention),
            child: const Text('Leave space'),
          ),
        ],
      ],
    );
  }

  List<Widget> _teamSection(Space space) {
    final members = ref.watch(spaceMembersProvider);
    final myId = ref.watch(currentUserIdProvider).value;
    return [
      const SectionHeader(title: 'Invite code'),
      InviteCodeCard(code: space.joinCode ?? ''),
      const SectionHeader(title: 'Members'),
      switch (members) {
        AsyncData(:final value) => Column(
          children: [
            for (final m in value) MemberRow(member: m, isMe: m.userId == myId),
          ],
        ),
        AsyncError(:final error) => Text(
          AppException.from(error).message,
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.attention,
          ),
        ),
        _ => const SkeletonList(rows: 2),
      },
    ];
  }
}
