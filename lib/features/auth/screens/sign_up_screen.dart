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
import '../widgets/google_button.dart';
import '../widgets/password_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
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
      final outcome = await ref
          .read(authRepositoryProvider)
          .signUp(
            displayName: _name.text,
            email: _email.text,
            password: _password.text,
          );
      TextInput.finishAutofillContext();
      if (!mounted) return;
      if (outcome == SignUpOutcome.confirmEmail) {
        context.go(
          Uri(
            path: AppRoutes.checkEmail,
            queryParameters: {'email': _email.text.trim()},
          ).toString(),
        );
      }
      // When signed in right away, the router moves on by itself.
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Create your account',
      subtitle: 'Your teammate will see your name.',
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  validator: Validators.displayName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  maxLength: Validators.maxNameLength,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _email,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: AppSpacing.lg),
                PasswordField(
                  controller: _password,
                  validator: Validators.newPassword,
                  isNewPassword: true,
                  onSubmitted: _submit,
                ),
              ],
            ),
          ),
        ),
        FormMessage(message: _error),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Create account',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        const OrDivider(),
        const SizedBox(height: AppSpacing.lg),
        const GoogleButton(),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.pushReplacement(AppRoutes.signIn),
          child: const Text('I already have an account'),
        ),
      ],
    );
  }
}
