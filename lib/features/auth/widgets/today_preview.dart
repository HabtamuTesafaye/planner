import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/circle_check.dart';

/// A small, real-looking Today card for the Welcome screen: three example
/// tasks, one per part of the app. Shortly after it appears, the first one
/// ticks itself off; the circles can also be tapped. Shows what the app
/// does instead of describing it.
class TodayPreview extends StatefulWidget {
  const TodayPreview({this.autoCheckAfter, super.key});

  /// When to tick the first task. Null uses the default timing.
  final Duration? autoCheckAfter;

  static const tasks = [
    'Call Abebe about the café order',
    'Follow up with three new leads',
    'Log this week’s payment',
  ];

  @override
  State<TodayPreview> createState() => _TodayPreviewState();
}

class _TodayPreviewState extends State<TodayPreview> {
  final List<bool> _done = [false, false, false];
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _done[0]) return;
    if (AppMotion.reduced(context)) {
      _done[0] = true;
      return;
    }
    _timer = Timer(
      widget.autoCheckAfter ?? const Duration(milliseconds: 1400),
      () {
        if (mounted) setState(() => _done[0] = true);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final date = DateFormat.MMMMEEEEd().format(DateTime.now());
    final doneCount = _done.where((d) => d).length;

    return Semantics(
      label: 'Example of the Today screen with three tasks',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.sheetAll,
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(date, style: text.titleMedium)),
                  AnimatedSwitcher(
                    duration: AppMotion.of(context, AppDurations.normal),
                    child: Text(
                      '$doneCount of 3',
                      key: ValueKey(doneCount),
                      style: text.labelMedium!.copyWith(color: colors.muted),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              for (var i = 0; i < TodayPreview.tasks.length; i++)
                _Row(
                  title: TodayPreview.tasks[i],
                  done: _done[i],
                  onChanged: (v) => setState(() => _done[i] = v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.done,
    required this.onChanged,
  });

  final String title;
  final bool done;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = context.text.bodyLarge!;
    return Row(
      children: [
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.of(context, AppDurations.normal),
            style: base.copyWith(
              color: done ? colors.muted : colors.text,
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: colors.muted,
            ),
            child: Text(title),
          ),
        ),
        CircleCheck(value: done, label: title, onChanged: onChanged),
      ],
    );
  }
}
