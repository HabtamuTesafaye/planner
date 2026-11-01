import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/dates.dart';
import '../insights_logic.dart';

/// GitHub-style activity grid: one column per week (Monday on top), one
/// cell per day, shaded by tasks done (0–3, one hue light to dark). As many
/// weeks as fit the width. Tap a day to read it.
class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({
    required this.byDay,
    required this.today,
    required this.maxWeeks,
    super.key,
  });

  final Map<DateTime, int> byDay;
  final DateTime today;
  final int maxWeeks;

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  DateTime? _selected;

  Color _shade(BuildContext context, int n) {
    final colors = context.colors;
    if (n <= 0) return colors.surfaceSunken;
    return colors.activity[math.min(n, colors.activity.length) - 1];
  }

  String _describe(DateTime day) {
    final n = widget.byDay[day] ?? 0;
    final when = DateFormat.MMMEd().format(day);
    return n == 0
        ? '$when · nothing done'
        : '$when · $n ${n == 1 ? 'task' : 'tasks'} done';
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    const gap = AppSizes.chartGap;
    const dayLabelWidth = AppSizes.iconSmall;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - dayLabelWidth - AppSpacing.xs;
        final fit = ((width + gap) / (AppSizes.heatCellMin + gap)).floor();
        final weeks = math.max(1, math.min(widget.maxWeeks, fit));
        final cell = (width - gap * (weeks - 1)) / weeks;
        final mondays = heatmapWeeks(widget.today, weeks);
        final total = widget.byDay.entries
            .where((e) => !e.key.isBefore(mondays.first))
            .fold(0, (a, e) => a + e.value);
        final active = widget.byDay.entries
            .where((e) => !e.key.isBefore(mondays.first) && e.value > 0)
            .length;

        // Its own node: TalkBack reads the summary, then each day.
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label:
              'Activity over the last $weeks weeks: $total tasks done on '
              '$active days.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels over the week where a month starts.
              Padding(
                padding: const EdgeInsets.only(
                  left: dayLabelWidth + AppSpacing.xs,
                ),
                child: SizedBox(
                  height: text.labelSmall!.fontSize! * 1.6,
                  child: Stack(
                    children: [
                      for (final i in monthLabelColumns(mondays))
                        Positioned(
                          left: i * (cell + gap),
                          child: ExcludeSemantics(
                            child: Text(
                              DateFormat.MMM().format(mondays[i]),
                              style: text.labelSmall,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: dayLabelWidth,
                    child: Column(
                      children: [
                        for (var d = 0; d < 7; d++)
                          SizedBox(
                            height: cell + (d < 6 ? gap : 0),
                            child: d.isEven
                                ? ExcludeSemantics(
                                    child: Text(
                                      // Any Monday works as a reference
                                      // for the weekday initials.
                                      DateFormat.E()
                                          .format(
                                            mondays.first.add(
                                              Duration(days: d),
                                            ),
                                          )
                                          .substring(0, 1),
                                      style: text.labelSmall,
                                    ),
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  for (final (i, monday) in mondays.indexed) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Column(
                      children: [
                        for (var d = 0; d < 7; d++) ...[
                          if (d > 0) const SizedBox(height: gap),
                          _cell(
                            context,
                            DateTime(monday.year, monday.month, monday.day + d),
                            cell,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context, AppDurations.fast),
                      child: Text(
                        _selected == null
                            ? 'Tap a day to see it'
                            : _describe(_selected!),
                        key: ValueKey(_selected),
                        style: text.bodySmall!.copyWith(
                          color: _selected == null ? colors.muted : colors.text,
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: _Legend(shade: (n) => _shade(context, n)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cell(BuildContext context, DateTime day, double size) {
    final future = day.isAfter(widget.today);
    final n = widget.byDay[day] ?? 0;
    final selected = _selected != null && Dates.isSameDay(_selected!, day);
    return GestureDetector(
      onTap: future ? null : () => setState(() => _selected = day),
      child: Semantics(
        label: future ? null : _describe(day),
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppDurations.fast),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: future ? Colors.transparent : _shade(context, n),
            borderRadius: BorderRadius.circular(AppSizes.chartGap),
            border: selected
                ? Border.all(
                    color: context.colors.text,
                    width: AppSizes.ringStroke,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.shade});

  final Color Function(int n) shade;

  @override
  Widget build(BuildContext context) {
    final style = context.text.labelSmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('0', style: style),
        const SizedBox(width: AppSpacing.xs),
        for (var n = 0; n <= 3; n++) ...[
          if (n > 0) const SizedBox(width: AppSizes.chartGap),
          Container(
            width: AppSizes.heatCellMin,
            height: AppSizes.heatCellMin,
            decoration: BoxDecoration(
              color: shade(n),
              borderRadius: BorderRadius.circular(AppSizes.chartGap),
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.xs),
        Text('3', style: style),
      ],
    );
  }
}

/// Columns that get a month label: where a month starts, at least
/// four columns apart and not at the very right edge, so labels never
/// collide or get cut off. A short partial month at the left gives way to
/// the next full one.
List<int> monthLabelColumns(List<DateTime> mondays) {
  const minGap = 4;
  final starts = [
    for (var i = 0; i < mondays.length; i++)
      if (i == 0 || mondays[i].month != mondays[i - 1].month) i,
  ];
  if (starts.length > 1 && starts[1] - starts[0] < minGap) starts.removeAt(0);
  final result = <int>[];
  for (final i in starts) {
    final roomBefore = result.isEmpty || i - result.last >= minGap;
    final roomAfter = mondays.length - i >= minGap - 1;
    if (roomBefore && roomAfter) result.add(i);
  }
  return result;
}
