import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../data/models/project.dart';
import '../../space/providers/space_providers.dart';
import '../providers/projects_providers.dart';

/// One step up close: its title and a note the whole space can read.
/// Shows who changed the note last, and when.
class StepSheet extends ConsumerStatefulWidget {
  const StepSheet({required this.item, super.key});

  final ProjectItem item;

  @override
  ConsumerState<StepSheet> createState() => _StepSheetState();
}

class _StepSheetState extends ConsumerState<StepSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item.title);
  late final _note = TextEditingController(text: widget.item.note ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final e = await ref
        .read(projectsControllerProvider.notifier)
        .editStep(widget.item, title: _title.text, note: _note.text);
    if (!mounted) return;
    if (e == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  /// "Edited by Hana · Nov 3", or null when there is no note yet.
  String? _byline() {
    final item = widget.item;
    final at = item.noteUpdatedAt;
    if (!item.hasNote || at == null) return null;
    final members = ref.watch(spaceMembersProvider).value ?? const [];
    final name = members
        .where((m) => m.userId == item.noteUpdatedBy)
        .map((m) => m.displayName)
        .firstOrNull;
    final when = DateFormat.MMMd().format(at);
    return name == null ? 'Edited $when' : 'Edited by $name · $when';
  }

  @override
  Widget build(BuildContext context) {
    final byline = _byline();
    return SheetFrame(
      title: 'Step',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                maxLength: ProjectItem.maxTitleLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Step'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Give the step a name.' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                minLines: 4,
                maxLines: 10,
                maxLength: ProjectItem.maxNoteLength,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Details, links, what is left to do…',
                  helperText: 'Everyone in this space can read it.',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        if (byline != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              byline,
              style: context.text.bodySmall!.copyWith(
                color: context.colors.muted,
              ),
            ),
          ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Save', loading: _saving, onPressed: _save),
      ],
    );
  }
}
