import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../router_redirect.dart';
import '../widgets/auth_page.dart';
import '../widgets/password_field.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  AppErrorKind? _errorKind;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      TextInput.finishAutofillContext();
      // The router moves on once the session arrives.
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _errorKind = e.kind;
          _error = e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await ref.read(authRepositoryProvider).resendConfirmation(_email.text);
      if (mounted) {
        setState(() => _notice = 'Sent. Check your inbox (and spam).');
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsConfirmation = _errorKind == AppErrorKind.emailNotConfirmed;
    return AuthPage(
      title: 'Sign in',
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.username,
                  ],
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: AppSpacing.lg),
                PasswordField(
                  controller: _password,
                  validator: Validators.password,
                  isNewPassword: false,
                  onSubmitted: _submit,
                ),
              ],
            ),
          ),
        ),
        FormMessage(
          message: _error,
          action: needsConfirmation && _error != null
              ? TextButton(
                  onPressed: _resend,
                  child: const Text('Send the email again'),
                )
              : null,
        ),
        FormMessage(message: _notice, isError: false),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Sign in', loading: _loading, onPressed: _submit),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.pushReplacement(AppRoutes.signUp),
          child: const Text('Create an account'),
        ),
      ],
    );
  }
}
