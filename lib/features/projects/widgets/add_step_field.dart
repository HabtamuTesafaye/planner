import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/project.dart';

/// Inline "Add a step" field under the checklist.
class AddStepField extends StatefulWidget {
  const AddStepField({required this.onAdd, super.key});

  /// Returns true when the step was saved (the field then clears).
  final Future<bool> Function(String title) onAdd;

  @override
  State<AddStepField> createState() => _AddStepFieldState();
}

class _AddStepFieldState extends State<AddStepField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    final ok = await widget.onAdd(title);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _controller.clear();
      _focus.requestFocus(); // keep adding steps quickly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        maxLength: ProjectItem.maxTitleLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Add a step',
          counterText: '',
          suffixIcon: IconButton(
            onPressed: _saving ? null : _submit,
            tooltip: 'Add step',
            icon: const Icon(Symbols.add),
          ),
        ),
      ),
    );
  }
}
