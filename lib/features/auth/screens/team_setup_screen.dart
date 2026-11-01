import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/join_code.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../team/providers/team_providers.dart';
import '../widgets/auth_page.dart';

enum _Mode { create, join }

/// After sign-up: create a team, or join a teammate's with their code.
/// One action at a time.
class TeamSetupScreen extends ConsumerStatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  ConsumerState<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends ConsumerState<TeamSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  _Mode _mode = _Mode.create;
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
    final repo = ref.read(teamRepositoryProvider);
    try {
      if (_mode == _Mode.create) {
        await repo.createTeam(_name.text);
      } else {
        await repo.joinTeam(_code.text);
      }
      // Reload the team; the router then opens the app.
      ref.invalidate(currentTeamProvider);
      await ref.read(currentTeamProvider.future);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AppException catch (e, s) {
      Log.error('Sign out failed', e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = _mode == _Mode.create;
    return AuthPage(
      title: 'Set up your team',
      subtitle: 'Start a new team, or join your teammate with their code.',
      showBack: false,
      children: [
        SegmentedButton<_Mode>(
          segments: const [
            ButtonSegment(value: _Mode.create, label: Text('New team')),
            ButtonSegment(value: _Mode.join, label: Text('Join with code')),
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
                    key: const ValueKey('team-name'),
                    controller: _name,
                    validator: Validators.teamName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    maxLength: Validators.maxNameLength,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Team name',
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
                      helperText: '8 letters and numbers, from your teammate',
                    ),
                  ),
          ),
        ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: creating ? 'Create team' : 'Join team',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: _loading ? null : _signOut,
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
