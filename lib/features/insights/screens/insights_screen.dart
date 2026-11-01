import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/contact.dart';
import '../../../data/models/income.dart';
import '../../../data/models/task.dart';
import '../../money/money_logic.dart';
import '../../money/providers/money_providers.dart';
import '../../outreach/providers/outreach_providers.dart';
import '../../projects/providers/projects_providers.dart';
import '../../space/providers/space_providers.dart';
import '../../today/providers/today_providers.dart';
import '../insights_logic.dart';
import '../providers/insights_providers.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/bar_chart.dart';
import '../widgets/breakdown_bars.dart';
import '../widgets/insight_card.dart';
import '../widgets/stat_tile.dart';

/// A quiet dashboard: your activity across every space, then the current
/// space's money, outreach and projects. Facts, not scores.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  static const path = '/insights';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final tasks = ref.watch(activityTasksProvider);
    final space = ref.watch(currentSpaceProvider);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(activityTasksProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                      icon: const Icon(Symbols.arrow_back),
                    ),
                  ),
                  Semantics(
                    header: true,
                    child: Text('Insights', style: context.text.headlineMedium),
                  ),
                  Text(
                    'Your rhythm across every space.',
                    style: context.text.bodyLarge!.copyWith(
                      color: context.colors.muted,
                    ),
                  ),
                  ...switch (tasks) {
                    AsyncValue(hasValue: true, :final value?) => _personal(
                      context,
                      value,
                      today,
                    ),
                    AsyncValue(:final error?) => [
                      const SizedBox(height: AppSpacing.xl),
                      Text(AppException.from(error).message),
                    ],
                    _ => const [
                      SizedBox(height: AppSpacing.xl),
                      SkeletonList(),
                    ],
                  },
                  if (space != null) ..._space(context, ref, space.name, today),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _personal(
    BuildContext context,
    List<Task> tasks,
    DateTime today,
  ) {
    final summary = summarize(tasks, today);
    final byDay = doneByDay(tasks);
    final weekly = weeklyDone(byDay, today, 8);
    final rate = summary.completion30;
    final diff = summary.doneThisWeek - summary.doneLastWeek;
    return [
      const SectionHeader(title: 'This month at a glance'),
      FadeSlideIn(
        child: StatGrid(
          tiles: [
            StatTile(
              value: '${summary.doneThisWeek}',
              label: 'Done this week',
              note: diff == 0
                  ? 'Same as last week'
                  : '${diff.abs()} ${diff > 0 ? 'more' : 'fewer'} than last week',
            ),
            StatTile(
              value: '${summary.activeDays30}',
              label: 'Active days',
              note: 'In the last 30 days',
            ),
            StatTile(
              value: rate == null ? '–' : '${(rate * 100).round()}%',
              label: 'Finished',
              note: 'Of planned tasks, 30 days',
            ),
            StatTile(
              value: summary.bestWeekday == null
                  ? '–'
                  : DateFormat.EEEE().format(
                      Dates.weekStart(today)
                          .add(Duration(days: summary.bestWeekday! - 1)),
                    ),
              label: 'Your strongest day',
              note: 'Last 12 weeks',
            ),
          ],
        ),
      ),
      const SectionHeader(title: 'Activity'),
      FadeSlideIn(
        index: 1,
        child: InsightCard(
          child: ActivityHeatmap(
            byDay: byDay,
            today: today,
            maxWeeks: insightWeeks,
          ),
        ),
      ),
      const SectionHeader(title: 'Tasks done per week'),
      FadeSlideIn(
        index: 2,
        child: InsightCard(
          child: SimpleBarChart(
            semanticLabel: 'Tasks done per week',
            bars: [
              for (final w in weekly)
                BarDatum(
                  label: DateFormat.Md().format(w.weekStart),
                  value: w.done.toDouble(),
                  valueText: '${w.done} ${w.done == 1 ? 'task' : 'tasks'}',
                ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _space(
    BuildContext context,
    WidgetRef ref,
    String spaceName,
    DateTime today,
  ) {
    final entries =
        ref.watch(incomeEntriesProvider).value ?? const <IncomeEntry>[];
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final projects = ref.watch(projectsProvider).value ?? const [];
    final items = ref.watch(projectItemsProvider).value ?? const [];
    final month = Dates.monthStart(today);
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(month.year, month.month - i),
    ];
    final statusRows = [
      for (final s in ContactStatus.values)
        (label: s.label, count: contacts.where((c) => c.status == s).length),
    ].where((r) => r.count > 0).toList();
    final active = projects.where((p) => !p.isDone).length;
    final stepsDone = items.where((i) => i.done).length;

    return [
      SectionHeader(title: spaceName),
      InsightCard(
        title: 'Income per month',
        child: entries.isEmpty
            ? const _Quiet('No income logged yet.')
            : SimpleBarChart(
                semanticLabel: 'Income per month',
                bars: [
                  for (final m in months)
                    BarDatum(
                      label: DateFormat.MMM().format(m),
                      value: monthTotal(entries, m) / 100,
                      valueText: Money.etb(monthTotal(entries, m) / 100),
                    ),
                ],
              ),
      ),
      const SizedBox(height: AppSpacing.md),
      InsightCard(
        title: 'Outreach pipeline',
        child: statusRows.isEmpty
            ? const _Quiet('No contacts yet.')
            : BreakdownBars(rows: statusRows, semanticLabel: 'Leads by status'),
      ),
      const SizedBox(height: AppSpacing.md),
      StatGrid(
        tiles: [
          StatTile(value: '$active', label: 'Active projects'),
          StatTile(
            value: '$stepsDone',
            label: 'Steps done',
            note: 'Of ${items.length} in all projects',
          ),
        ],
      ),
    ];
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.text.bodyMedium!.copyWith(color: context.colors.muted),
  );
}
