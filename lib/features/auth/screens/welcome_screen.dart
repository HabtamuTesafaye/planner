import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../router_redirect.dart';

/// First screen when signed out. The two actions sit in the bottom half,
/// within thumb reach.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.lg * 2,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Planner',
                          style: text.labelMedium!.copyWith(
                            color: colors.accentText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Semantics(
                          header: true,
                          child: Text(
                            'Three things a day.\nOne shared plan.',
                            style: text.displaySmall,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Daily tasks, outreach and income for a two-person '
                          'team, in one calm place.',
                          style: text.bodyLarge!.copyWith(color: colors.muted),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.xxl),
                        FilledButton(
                          onPressed: () => context.push(AppRoutes.signUp),
                          child: const Text('Create an account'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: () => context.push(AppRoutes.signIn),
                          child: const Text('I already have an account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
