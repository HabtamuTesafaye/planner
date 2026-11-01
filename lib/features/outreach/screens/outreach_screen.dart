import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/contact.dart';
import '../../../data/repositories/contacts_repository.dart';
import '../../space/providers/space_providers.dart';
import '../../space/widgets/space_switcher.dart';
import '../../today/providers/today_providers.dart';
import '../providers/outreach_providers.dart';
import '../widgets/contact_row.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/outreach_filters.dart';
import '../widgets/status_sheet.dart';

/// The space's outreach pipeline: overdue follow-ups first.
class OutreachScreen extends ConsumerWidget {
  const OutreachScreen({super.key});

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on AppException catch (e) {
      if (context.mounted) _message(context, e.message);
    }
  }

  Future<void> _open(BuildContext context, WidgetRef ref, [Contact? c]) async {
    final space = ref.read(currentSpaceProvider);
    if (space == null) return;
    await showAppSheet<bool>(
      context,
      ContactSheet(
        spaceId: space.id,
        today: ref.read(todayProvider),
        existing: c,
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Contact c) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${c.name}?'),
        content: const Text('This removes the lead for everyone in the space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: context.colors.text),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.attention,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return sure ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(visibleContactsProvider);
    final all = ref.watch(contactsProvider).value ?? const <Contact>[];
    final names = ref.watch(memberNamesProvider);
    final today = ref.watch(todayProvider);
    final isTeam = !(ref.watch(currentSpaceProvider)?.isPersonal ?? true);
    // Read only when an action runs, never while drawing.
    ContactsRepository repo() => ref.read(contactsRepositoryProvider);
    final list = contacts.value ?? const <Contact>[];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, ref),
        icon: const Icon(Symbols.add),
        label: const Text('Add contact'),
      ),
      body: PageBody(
        title: 'Outreach',
        top: const SpaceSwitcher(),
        bottomPadding: AppSizes.fabClearance,
        onRefresh: () async => ref.invalidate(contactsProvider),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final c = list[i];
          return Dismissible(
            key: ValueKey('contact-${c.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: context.colors.surfaceSunken,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Icon(Symbols.delete, color: context.colors.attention),
            ),
            confirmDismiss: (_) async {
              if (!await _confirmDelete(context, c)) return false;
              try {
                final ok = await repo().delete(c.id);
                if (!ok && context.mounted) {
                  _message(
                    context,
                    const AppException(AppErrorKind.notAllowed).message,
                  );
                }
                return ok;
              } on AppException catch (e) {
                if (context.mounted) _message(context, e.message);
                return false;
              }
            },
            child: ContactRow(
              contact: c,
              today: today,
              ownerName: isTeam ? names[c.ownerId] : null,
              onOpen: () => _open(context, ref, c),
              onStatus: () async {
                final s = await pickStatus(context, c.status);
                if (s != null && context.mounted) {
                  await _run(context, () => repo().setStatus(c.id, s));
                }
              },
              onFollowedUp: () async {
                final next = await pickFollowUp(context, today: today);
                if (next != null && context.mounted) {
                  await _run(context, () => repo().setFollowUp(c.id, next));
                  if (context.mounted) {
                    _message(context, 'Next follow-up saved');
                  }
                }
              },
            ),
          );
        },
        children: [
          const SizedBox(height: AppSpacing.md),
          if (all.isNotEmpty) OutreachFilters(contacts: all, showMine: isTeam),
          ...switch (contacts) {
            AsyncValue(hasValue: true) when all.isEmpty => [
              EmptyState(
                icon: Symbols.handshake,
                message: 'No contacts yet.',
                detail: 'Add the first business you message.',
                actionLabel: 'Add contact',
                onAction: () => _open(context, ref),
              ),
            ],
            AsyncValue(hasValue: true) when list.isEmpty => [
              const EmptyState(message: 'Nobody here with this filter.'),
            ],
            AsyncValue(hasValue: true) => const [],
            AsyncValue(:final error?) => [
              EmptyState(
                message: AppException.from(error).message,
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(contactsProvider),
              ),
            ],
            _ => const [SkeletonList()],
          },
        ],
      ),
    );
  }
}
