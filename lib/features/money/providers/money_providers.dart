import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/dates.dart';
import '../../../data/models/income.dart';
import '../../../data/repositories/money_repository.dart';
import '../../space/providers/space_providers.dart';
import '../../today/providers/today_providers.dart';

/// The month being shown (this month).
final currentMonthProvider = Provider<DateTime>(
  (ref) => Dates.monthStart(ref.watch(todayProvider)),
);

/// Live income entries of the current space.
final incomeEntriesProvider = StreamProvider<List<IncomeEntry>>((ref) {
  final space = ref.watch(currentSpaceProvider);
  if (space == null) return Stream.value(const []);
  return ref.watch(moneyRepositoryProvider).watchEntries(space.id);
});

/// This month's target of the current space.
final monthlyTargetProvider = FutureProvider<MonthlyTarget?>((ref) async {
  final space = ref.watch(currentSpaceProvider);
  if (space == null) return null;
  return ref
      .watch(moneyRepositoryProvider)
      .fetchTarget(space.id, ref.watch(currentMonthProvider));
});

/// Entries deleted on this device, hidden until the live list catches up
/// (so Undo feels instant).
class HiddenEntriesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.listen(incomeEntriesProvider, (_, next) {
      final ids = next.value?.map((e) => e.id).toSet();
      if (ids != null) state = state.where(ids.contains).toSet();
    });
    return const {};
  }

  void hide(String id) => state = {...state, id};
  void show(String id) => state = {...state}..remove(id);
}

final hiddenEntriesProvider =
    NotifierProvider<HiddenEntriesNotifier, Set<String>>(
      HiddenEntriesNotifier.new,
    );

/// Entries to show (pending deletes removed).
final visibleEntriesProvider = Provider<AsyncValue<List<IncomeEntry>>>((ref) {
  final hidden = ref.watch(hiddenEntriesProvider);
  return ref
      .watch(incomeEntriesProvider)
      .whenData(
        (all) => [
          for (final e in all)
            if (!hidden.contains(e.id)) e,
        ],
      );
});
