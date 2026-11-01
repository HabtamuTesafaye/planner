import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../data/models/space.dart';
import '../../../data/models/task.dart';
import '../../space/providers/space_providers.dart';
import '../providers/today_controller.dart';

/// Add one of today's three tasks, in a chosen space.
class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  String? _spaceId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  static String? _validate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Write what you want to get done.';
    if (v.length > Task.maxTitleLength) return 'Keep it under 120 characters.';
    return null;
  }

  Future<void> _submit(String spaceId) async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref
        .read(todayControllerProvider.notifier)
        .add(title: _title.text, spaceId: spaceId);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spaces = ref.watch(mySpacesProvider).value ?? const <Space>[];
    final current = ref.watch(currentSpaceProvider);
    final spaceId = _spaceId ?? current?.id;

    return SheetFrame(
      title: 'Add a task',
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _title,
            validator: _validate,
            autofocus: true,
            maxLength: Task.maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) async {
              if (spaceId != null) await _submit(spaceId);
            },
            decoration: const InputDecoration(hintText: 'What matters today?'),
          ),
        ),
        if (spaces.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in spaces)
                ChoiceChip(
                  label: Text(s.name),
                  selected: s.id == spaceId,
                  onSelected: (_) => setState(() => _spaceId = s.id),
                ),
            ],
          ),
        ],
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Add',
          loading: _saving,
          onPressed: spaceId == null ? null : () => _submit(spaceId),
        ),
      ],
    );
  }
}
