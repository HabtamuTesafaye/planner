import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/join_code.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/space_repository.dart';
import '../../auth/widgets/auth_page.dart';
import '../providers/space_providers.dart';

enum NewSpaceMode { create, join }

/// Create a team space, or join one with a code. Opened from the space
/// switcher; on success it switches to the new space and closes.
class NewSpaceScreen extends ConsumerStatefulWidget {
  const NewSpaceScreen({this.initialMode = NewSpaceMode.create, super.key});

  final NewSpaceMode initialMode;

  @override
  ConsumerState<NewSpaceScreen> createState() => _NewSpaceScreenState();
}

class _NewSpaceScreenState extends ConsumerState<NewSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  late NewSpaceMode _mode = widget.initialMode;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(spaceRepositoryProvider);
    try {
      final space = _mode == NewSpaceMode.create
          ? await repo.createSpace(_name.text)
          : await repo.joinSpace(_code.text);
      await refreshAndSelect(ref, space.id);
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = _mode == NewSpaceMode.create;
    return AuthPage(
      title: creating ? 'New team space' : 'Join a space',
      subtitle: creating
          ? 'A shared space for projects, outreach and income. '
                'Invite people with its code.'
          : 'Ask a member for the 8-character code.',
      children: [
        SegmentedButton<NewSpaceMode>(
          segments: const [
            ButtonSegment(value: NewSpaceMode.create, label: Text('New')),
            ButtonSegment(
              value: NewSpaceMode.join,
              label: Text('Join with code'),
            ),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: _loading
              ? null
              : (s) => setState(() {
                  _mode = s.first;
                  _error = null;
                }),
        ),
        const SizedBox(height: AppSpacing.xl),
        Form(
          key: _formKey,
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppDurations.normal),
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            child: creating
                ? TextFormField(
                    key: const ValueKey('space-name'),
                    controller: _name,
                    validator: Validators.teamName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    maxLength: Validators.maxNameLength,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Space name',
                      counterText: '',
                    ),
                  )
                : TextFormField(
                    key: const ValueKey('join-code'),
                    controller: _code,
                    validator: Validators.joinCode,
                    inputFormatters: const [JoinCodeInputFormatter()],
                    keyboardType: TextInputType.visiblePassword,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: const TextStyle(
                      letterSpacing: 2,
                      fontFeatures: AppTextStyles.tabular,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Invite code',
                      helperText: '8 letters and numbers',
                    ),
                  ),
          ),
        ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: creating ? 'Create space' : 'Join space',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
