import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheet_frame.dart';
import '../../../data/models/project.dart';
import '../providers/projects_providers.dart';
import '../templates.dart';

/// Name a project and pick a template. Returns the new project's id.
class NewProjectSheet extends ConsumerStatefulWidget {
  const NewProjectSheet({required this.spaceId, super.key});

  final String spaceId;

  @override
  ConsumerState<NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends ConsumerState<NewProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  ProjectTemplate _template = ProjectTemplate.client;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  static String? _validate(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Give the project a name.';
    if (value.length > Project.maxNameLength) {
      return 'Keep it under 80 characters.';
    }
    return null;
  }

  Future<void> _create() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final (id, error) = await ref
        .read(projectsControllerProvider.notifier)
        .create(spaceId: widget.spaceId, name: _name.text, template: _template);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } else {
      Navigator.of(context).pop(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: 'New project',
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _name,
            validator: _validate,
            autofocus: true,
            maxLength: Project.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Project name',
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Start from', style: context.text.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final t in ProjectTemplate.values)
          _TemplateOption(
            template: t,
            selected: t == _template,
            onTap: () => setState(() => _template = t),
          ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Create project',
          loading: _saving,
          onPressed: _create,
        ),
      ],
    );
  }
}

class _TemplateOption extends StatelessWidget {
  const _TemplateOption({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final ProjectTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final steps = template.steps.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? colors.accentSoft : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.controlAll,
            side: BorderSide(color: selected ? colors.accent : colors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AnimatedPadding(
              duration: AppMotion.of(context, AppDurations.fast),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(template.icon, color: colors.accent),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.label, style: context.text.titleSmall),
                        Text(
                          steps == 0
                              ? template.description
                              : '${template.description} $steps steps.',
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
