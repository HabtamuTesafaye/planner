import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/task.dart';
import '../../review/providers/review_providers.dart';
import '../../review/screens/review_screen.dart';
import '../../space/providers/space_providers.dart';
import '../providers/today_controller.dart';
import '../providers/today_providers.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/day_progress.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_sheet.dart';
import '../widgets/task_row.dart';

/// Today: the big date, the goal of the week for the current space, and
/// my (max 3) tasks from every space.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // A new day may have started while the app was in the background.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(todayProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _message(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  Future<void> _addTask(int count) async {
    if (count >= Task.dailyLimit) {
      _message(const AppException(AppErrorKind.taskLimit).message);
      return;
    }
    await showAppSheet<void>(context, const AddTaskSheet());
  }

  Future<void> _toggle(Task task) async {
    final error = await ref.read(todayControllerProvider.notifier).toggle(task);
    if (error != null) _message(error.message);
  }

  Future<void> _delete(Task task) async {
    final controller = ref.read(todayControllerProvider.notifier);
    final error = await controller.delete(task);
    if (error != null) {
      _message(error.message);
      return;
    }
    _message(
      'Task deleted',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          final undoError = await controller.restore(task);
          if (undoError != null) _message(undoError.message);
        },
      ),
    );
  }

  Future<void> _editGoal(String spaceId, String? goal) =>
      showAppSheet<void>(context, GoalSheet(spaceId: spaceId, initial: goal));

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final tasks = ref.watch(todayTasksProvider);
    final space = ref.watch(currentSpaceProvider);
    final goal = ref.watch(weeklyGoalProvider).value?.goal;
    final names = ref.watch(spaceNamesProvider);
    final count = tasks.value?.length ?? 0;
    final done = tasks.value?.where((t) => t.done).length ?? 0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTask(count),
        icon: const Icon(Symbols.add),
        label: const Text('Add task'),
        tooltip: count >= Task.dailyLimit
            ? 'Three is the limit for today'
            : 'Add a task',
      ),
      body: PageBody(
        title: DateFormat.EEEE().format(today),
        subtitle: DateFormat.MMMMd().format(today),
        largeTitle: true,
        bottomPadding: AppSizes.fabClearance,
        onRefresh: () async => ref.invalidate(myTasksProvider),
        children: [
          const SizedBox(height: AppSpacing.xl),
          if (space != null)
            FadeSlideIn(
              child: GoalCard(
                goal: goal,
                spaceName: space.name,
                onTap: () => _editGoal(space.id, goal),
              ),
            ),
          if (ref.watch(reviewPromptProvider))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: FadeSlideIn(
                index: 1,
                child: _ReviewPrompt(
                  onOpen: () => context.push(ReviewScreen.path),
                ),
              ),
            ),
          SectionHeader(
            title: 'Today’s three',
            trailing: DayProgress(planned: count, done: done),
          ),
          ...switch (tasks) {
            AsyncValue(hasValue: true, :final value?) when value.isEmpty => [
              EmptyState(
                message: 'Nothing planned yet.',
                detail: 'Pick up to three things that matter today.',
                actionLabel: 'Add a task',
                onAction: () => _addTask(0),
              ),
            ],
            AsyncValue(hasValue: true, :final value?) => [
              for (final (i, task) in value.indexed)
                FadeSlideIn(
                  key: ValueKey('in-${task.id}'),
                  index: i,
                  child: TaskRow(
                    task: task,
                    spaceName: names.length > 1 ? names[task.spaceId] : null,
                    onToggle: () => _toggle(task),
                    onDelete: () => _delete(task),
                  ),
                ),
              if (value.length >= Task.dailyLimit)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Text(
                    done == value.length
                        ? 'All three done. Enjoy the rest of the day.'
                        : 'That’s your three for today.',
                    style: context.text.bodyMedium!.copyWith(
                      color: context.colors.muted,
                    ),
                  ),
                ),
            ],
            AsyncValue(:final error?) => [
              _ErrorBlock(
                message: AppException.from(error).message,
                onRetry: () => ref.invalidate(myTasksProvider),
              ),
            ],
            _ => [const SkeletonList()],
          },
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: context.text.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/// Gentle Sunday/Monday nudge when the weekly review is missing.
class _ReviewPrompt extends StatelessWidget {
  const _ReviewPrompt({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.accentSoft,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.controlAll),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Symbols.edit_note, color: colors.accentText),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Take two minutes for your weekly review.',
                  style: context.text.bodyLarge,
                ),
              ),
              Icon(Symbols.chevron_right, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
