import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../data/app_exception.dart';
import '../../../data/models/weekly_goal.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/today_providers.dart';

/// Edit the goal of the week for a space. Saving an empty goal clears it.
class GoalSheet extends ConsumerStatefulWidget {
  const GoalSheet({required this.spaceId, required this.initial, super.key});

  final String spaceId;
  final String? initial;

  @override
  ConsumerState<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<GoalSheet> {
  late final _controller = TextEditingController(text: widget.initial ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save([String? value]) async {
    final userId = ref.read(currentUserIdProvider).value;
    if (userId == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(goalsRepositoryProvider)
          .saveGoal(
            WeeklyGoal(
              spaceId: widget.spaceId,
              userId: userId,
              weekStart: Dates.weekStart(ref.read(todayProvider)),
              goal: value ?? _controller.text,
            ),
          );
      ref.invalidate(weeklyGoalProvider);
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGoal = (widget.initial ?? '').isNotEmpty;
    return SheetFrame(
      title: 'Goal of the week',
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: WeeklyGoal.maxLength,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: const InputDecoration(
            hintText: 'One outcome that would make this week a win',
          ),
        ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Save', loading: _saving, onPressed: _save),
        if (hasGoal) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _saving ? null : () => _save(''),
            child: const Text('Clear goal'),
          ),
        ],
      ],
    );
  }
}
