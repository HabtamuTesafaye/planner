import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_page.dart';
import '../widgets/password_field.dart';

/// Shown after opening a reset link: the user is signed in for it and sets
/// a new password. Saving moves on to the app.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      TextInput.finishAutofillContext();
      ref.read(passwordRecoveryProvider.notifier).finish();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Set a new password',
      subtitle: 'Choose a new password for your account.',
      showBack: false,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: PasswordField(
              controller: _password,
              validator: Validators.newPassword,
              isNewPassword: true,
              onSubmitted: _submit,
            ),
          ),
        ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Save password',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
