import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/income.dart';
import '../../../data/repositories/money_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../outreach/providers/outreach_providers.dart';
import '../../space/providers/space_providers.dart';
import '../../space/widgets/space_switcher.dart';
import '../money_logic.dart';
import '../providers/money_providers.dart';
import '../widgets/amount_sheet.dart';
import '../widgets/entry_row.dart';
import '../widgets/money_hero.dart';

/// This month's income against the target, entries, and earlier months.
class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  void _message(BuildContext context, String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  /// Add an income entry to the current space. Also used by the quick
  /// actions on Today.
  static Future<void> addIncome(BuildContext context, WidgetRef ref) async {
    final space = ref.read(currentSpaceProvider);
    if (space == null) return;
    await showAppSheet<void>(
      context,
      AmountSheet(
        title: 'Add income',
        buttonLabel: 'Add',
        withNote: true,
        onSave: (cents, note) async {
          try {
            await ref
                .read(moneyRepositoryProvider)
                .add(
                  IncomeEntry(
                    id: newUuid(),
                    spaceId: space.id,
                    userId: ref.read(currentUserIdProvider).value,
                    month: monthOf(ref.read(currentMonthProvider)),
                    cents: cents,
                    note: note,
                    createdAt: DateTime.now(),
                  ),
                );
            return null;
          } on AppException catch (e) {
            return e.message;
          }
        },
      ),
    );
  }

  Future<void> _editTarget(
    BuildContext context,
    WidgetRef ref,
    int? current,
  ) async {
    final space = ref.read(currentSpaceProvider);
    if (space == null) return;
    await showAppSheet<void>(
      context,
      AmountSheet(
        title: 'Monthly target',
        buttonLabel: 'Save target',
        initialCents: current,
        onSave: (cents, _) async {
          try {
            await ref
                .read(moneyRepositoryProvider)
                .setTarget(
                  MonthlyTarget(
                    spaceId: space.id,
                    month: ref.read(currentMonthProvider),
                    cents: cents,
                  ),
                );
            ref.invalidate(monthlyTargetProvider);
            return null;
          } on AppException catch (e) {
            return e.message;
          }
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    IncomeEntry e,
  ) async {
    final hidden = ref.read(hiddenEntriesProvider.notifier)..hide(e.id);
    final repo = ref.read(moneyRepositoryProvider);
    try {
      if (!await repo.delete(e.id)) {
        hidden.show(e.id);
        if (context.mounted) {
          _message(
            context,
            const AppException(AppErrorKind.notAllowed).message,
          );
        }
        return;
      }
    } on AppException catch (err) {
      hidden.show(e.id);
      if (context.mounted) _message(context, err.message);
      return;
    }
    if (!context.mounted) return;
    _message(
      context,
      'Entry deleted',
      action: SnackBarAction(label: 'Undo', onPressed: () => repo.restore(e)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(currentMonthProvider);
    final entries = ref.watch(visibleEntriesProvider);
    final target = ref.watch(monthlyTargetProvider).value?.cents;
    final names = ref.watch(memberNamesProvider);
    final isTeam = !(ref.watch(currentSpaceProvider)?.isPersonal ?? true);
    final all = entries.value ?? const <IncomeEntry>[];
    final thisMonth = entriesOf(all, month);
    final history = previousMonths(all, month);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        // Every tab stays alive, so each button needs its own hero tag.
        heroTag: 'fab-money',
        onPressed: () => addIncome(context, ref),
        icon: const Icon(Symbols.add),
        label: const Text('Add income'),
      ),
      body: PageBody(
        title: 'Money',
        top: const SpaceSwitcher(),
        bottomPadding: AppSizes.fabClearance,
        onRefresh: () async => ref
          ..invalidate(incomeEntriesProvider)
          ..invalidate(monthlyTargetProvider),
        itemCount: thisMonth.length,
        itemBuilder: (context, i) => GroupTile(
          isFirst: i == 0,
          isLast: i == thisMonth.length - 1,
          child: EntryRow(
            entry: thisMonth[i],
            addedBy: isTeam ? names[thisMonth[i].userId] : null,
            onDelete: () => _delete(context, ref, thisMonth[i]),
          ),
        ),
        footer: [
          if (history.isNotEmpty) ...[
            const SectionHeader(title: 'Previous months'),
            GroupedSection(
              children: [
                for (final h in history)
                  _MonthRow(month: h.month, cents: h.cents),
              ],
            ),
          ],
        ],
        children: [
          const SizedBox(height: AppSpacing.xl),
          if (entries.hasValue)
            FadeSlideIn(
              child: MoneyHero(
                month: month,
                totalCents: monthTotal(all, month),
                targetCents: target,
                onEditTarget: () => _editTarget(context, ref, target),
              ),
            )
          else if (entries.hasError)
            EmptyState(
              message: AppException.from(entries.error!).message,
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(incomeEntriesProvider),
            )
          else
            const SkeletonList(rows: 2),
          if (entries.hasValue) ...[
            const SectionHeader(title: 'This month'),
            if (thisMonth.isEmpty)
              EmptyState(
                message: 'No income logged this month.',
                detail: 'Entries you add count toward the monthly target.',
                actionLabel: 'Add income',
                onAction: () => addIncome(context, ref),
              ),
          ],
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month, required this.cents});

  final DateTime month;
  final int cents;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat.yMMMM().format(month),
              style: context.text.bodyLarge,
            ),
          ),
          Text(
            Money.etb(cents / 100),
            style: context.text.titleMedium!.copyWith(
              fontFeatures: AppTextStyles.tabular,
            ),
          ),
        ],
      ),
    );
  }
}
