import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/space.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/space_repository.dart';
import '../../../router_redirect.dart';
import '../../auth/providers/auth_providers.dart';
import '../../review/providers/review_providers.dart';
import '../../review/screens/review_screen.dart';
import '../providers/progress_providers.dart';
import '../providers/space_providers.dart';
import '../widgets/invite_code_card.dart';
import '../widgets/leave_space_dialog.dart';
import '../widgets/member_card.dart';
import '../widgets/member_sheet.dart';
import '../widgets/review_entry.dart';
import '../widgets/settings_section.dart';
import '../widgets/space_switcher.dart';

/// Space tab: this week for everyone in the space, the weekly review,
/// invite (team spaces), settings, sign out and leave.
class SpaceScreen extends ConsumerStatefulWidget {
  const SpaceScreen({super.key});

  @override
  ConsumerState<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends ConsumerState<SpaceScreen> {
  bool _busy = false;

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AppException catch (e) {
      _message(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(mySpacesProvider)
      ..invalidate(spaceMembersProvider)
      ..invalidate(spaceTasksProvider)
      ..invalidate(spaceGoalsProvider)
      ..invalidate(spaceReviewsProvider);
  }

  Future<void> _leave(Space space) async {
    final confirmed = await confirmLeaveSpace(
      context,
      spaceName: space.name,
      members: ref.read(spaceMembersProvider).value ?? const [],
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
      _message('You left ${space.name}.');
    });
  }

  void _openNew(String mode) => context.push(
    Uri(path: AppRoutes.newSpace, queryParameters: {'mode': mode}).toString(),
  );

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(currentSpaceProvider);
    final progress = ref.watch(spaceProgressProvider);
    final reviews = ref.watch(spaceReviewsProvider).value ?? const [];
    final me = ref.watch(currentUserIdProvider).value;
    final colors = context.colors;

    return PageBody(
      title: 'Space',
      top: const SpaceSwitcher(),
      onRefresh: _refresh,
      children: [
        if (space == null)
          const SkeletonList(rows: 2)
        else ...[
          if (space.isPersonal) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your private space. Only you can see what you keep here.',
              style: context.text.bodyLarge!.copyWith(color: colors.muted),
            ),
          ],
          const SectionHeader(title: 'This week'),
          ...switch (progress) {
            AsyncValue(hasValue: true, :final value?) => [
              for (final (i, p) in value.indexed)
                FadeSlideIn(
                  key: ValueKey('member-${p.member.userId}'),
                  index: i,
                  child: MemberCard(
                    progress: p,
                    isMe: p.member.userId == me,
                    onTap: () => showAppSheet<void>(
                      context,
                      MemberSheet(
                        progress: p,
                        latest: reviews
                            .where(
                              (r) => r.userId == p.member.userId && !r.isEmpty,
                            )
                            .firstOrNull,
                      ),
                    ),
                  ),
                ),
            ],
            AsyncValue(:final error?) => [
              Text(
                AppException.from(error).message,
                style: context.text.bodyMedium!.copyWith(
                  color: colors.attention,
                ),
              ),
            ],
            _ => [const SkeletonList(rows: 2)],
          },
          ReviewEntry(onOpen: () => context.push(ReviewScreen.path)),
          if (space.isPersonal) ...[
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
          ] else ...[
            const SectionHeader(title: 'Invite'),
            InviteCodeCard(code: space.joinCode ?? '', spaceName: space.name),
          ],
        ],
        const SettingsSection(),
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
}
