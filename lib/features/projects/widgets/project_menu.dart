import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../data/models/project.dart';
import '../providers/projects_providers.dart';

enum _Action { rename, toggleDone, delete }

/// Rename, mark done / active, delete.
class ProjectMenu extends ConsumerWidget {
  const ProjectMenu({required this.project, super.key});

  final Project project;

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    _Action action,
  ) async {
    final controller = ref.read(projectsControllerProvider.notifier);
    switch (action) {
      case _Action.rename:
        final name = await showAppSheet<String>(
          context,
          _RenameSheet(initial: project.name),
        );
        if (name == null) return;
        final e = await controller.rename(project, name);
        if (e != null && context.mounted) _message(context, e.message);
      case _Action.toggleDone:
        final next = project.isDone ? ProjectStatus.active : ProjectStatus.done;
        final e = await controller.setStatus(project, next);
        if (context.mounted) {
          _message(
            context,
            e?.message ??
                (next == ProjectStatus.done
                    ? 'Marked as done'
                    : 'Back in progress'),
          );
        }
      case _Action.delete:
        final sure = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete ${project.name}?'),
            content: const Text(
              'Its steps are deleted too. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.text,
                ),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.attention,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (sure != true) return;
        final e = await controller.delete(project);
        if (!context.mounted) return;
        if (e != null) return _message(context, e.message);
        context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_Action>(
      tooltip: 'Project options',
      icon: const Icon(Symbols.more_vert),
      onSelected: (a) => _onSelected(context, ref, a),
      itemBuilder: (context) => [
        const PopupMenuItem(value: _Action.rename, child: Text('Rename')),
        PopupMenuItem(
          value: _Action.toggleDone,
          child: Text(project.isDone ? 'Mark as active' : 'Mark as done'),
        ),
        const PopupMenuItem(value: _Action.delete, child: Text('Delete')),
      ],
    );
  }
}

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.initial});

  final String initial;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: 'Rename project',
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: Project.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}
