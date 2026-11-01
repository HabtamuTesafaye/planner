import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/form_message.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../router_redirect.dart';
import '../widgets/auth_page.dart';

/// Shown after sign-up while email confirmation is on.
class CheckEmailScreen extends ConsumerStatefulWidget {
  const CheckEmailScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  bool _sending = false;
  String? _error;
  String? _notice;

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendConfirmation(widget.email);
      if (mounted) {
        setState(() => _notice = 'Sent again. It can take a minute.');
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email.isEmpty ? 'your email' : widget.email;
    return AuthPage(
      title: 'Check your email',
      showBack: false,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'We sent a confirmation link to '),
              TextSpan(
                text: email,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                text:
                    '. Open it on this phone and Planner signs you in. '
                    'Opened it somewhere else? Come back and sign in.',
              ),
            ],
          ),
          style: context.text.bodyLarge,
        ),
        FormMessage(message: _error),
        FormMessage(message: _notice, isError: false),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton(
          onPressed: () => context.go(AppRoutes.signIn),
          child: const Text('Go to sign in'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _sending || widget.email.isEmpty ? null : _resend,
          child: const Text('Send the email again'),
        ),
      ],
    );
  }
}
