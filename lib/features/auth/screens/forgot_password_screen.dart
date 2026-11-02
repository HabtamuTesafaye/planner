import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_message.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../widgets/auth_page.dart';

/// Asks for an email and sends a reset link. The reply never says whether
/// an account exists for that email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({this.email = '', super.key});

  /// Pre-filled from the sign-in screen.
  final String email;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
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
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) {
        setState(
          () => _notice =
              'If there is an account for that email, a reset link is on '
              'its way. Open it on this phone.',
        );
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Reset your password',
      subtitle: "We'll email you a link to set a new one.",
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _email,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
        FormMessage(message: _error),
        FormMessage(message: _notice, isError: false),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: _notice == null ? 'Send reset link' : 'Send again',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
