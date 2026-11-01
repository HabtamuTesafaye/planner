import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/task.dart';
import '../../money/screens/money_screen.dart';
import '../../outreach/screens/outreach_screen.dart';
import '../../projects/screens/projects_screen.dart';
import '../../review/providers/review_providers.dart';
import '../../review/screens/review_screen.dart';
import '../../space/providers/space_providers.dart';
import '../providers/today_controller.dart';
import '../providers/today_providers.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_sheet.dart';
import '../widgets/quick_actions.dart';
import '../widgets/task_row.dart';
import '../widgets/today_blocks.dart';

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

  Widget _shortcuts(String spaceName) => QuickActions(
    actions: [
      QuickAction(
        icon: QuickIcons.project,
        label: 'Project',
        hint: 'New project in $spaceName',
        tone: QuickTone.accent,
        onTap: () => ProjectsScreen.startNew(context, ref, fromOtherTab: true),
      ),
      QuickAction(
        icon: QuickIcons.contact,
        label: 'Contact',
        hint: 'Add a contact in $spaceName',
        tone: QuickTone.teal,
        onTap: () => OutreachScreen.openContact(context, ref),
      ),
      QuickAction(
        icon: QuickIcons.income,
        label: 'Income',
        hint: 'Add income in $spaceName',
        tone: QuickTone.success,
        onTap: () => MoneyScreen.addIncome(context, ref),
      ),
      QuickAction(
        icon: QuickIcons.review,
        label: 'Review',
        hint: 'Weekly review',
        tone: QuickTone.amber,
        onTap: () => context.push(ReviewScreen.path),
      ),
    ],
  );

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
        // Every tab stays alive, so each button needs its own hero tag.
        heroTag: 'fab-today',
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
        trailing: tasks.hasValue
            ? ProgressRing(
                done: done,
                total: Task.dailyLimit,
                semanticLabel:
                    '$done of $count tasks done today, '
                    '${Task.dailyLimit - count} free',
              )
            : null,
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
                child: ReviewPrompt(
                  onOpen: () => context.push(ReviewScreen.path),
                ),
              ),
            ),
          const SectionHeader(title: 'Today’s three'),
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
                  child: GroupTile(
                    isFirst: i == 0,
                    isLast: i == value.length - 1,
                    child: TaskRow(
                      task: task,
                      spaceName: names.length > 1 ? names[task.spaceId] : null,
                      onToggle: () => _toggle(task),
                      onDelete: () => _delete(task),
                    ),
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
              TodayErrorBlock(
                message: AppException.from(error).message,
                onRetry: () => ref.invalidate(myTasksProvider),
              ),
            ],
            _ => [const SkeletonList()],
          },
          if (space != null) ...[
            SectionHeader(title: 'Add to ${space.name}'),
            _shortcuts(space.name),
          ],
        ],
      ),
    );
  }
}
