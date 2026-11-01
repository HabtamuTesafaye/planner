import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../router_redirect.dart';

/// First screen when signed out. The mark draws itself, then the words and
/// actions arrive in order. The two actions sit in the bottom half, within
/// thumb reach.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _points = [
    (Symbols.task_alt, 'Three tasks a day, no more.'),
    (Symbols.handshake, 'Every lead and follow-up, shared.'),
    (Symbols.payments, "This month's income against your target."),
  ];

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    // Words start once the mark is mostly drawn.
    const after = Duration(milliseconds: 350);

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
                        const SizedBox(height: AppSpacing.xl),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: BrandMark(size: 56, animate: true),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FadeSlideIn(
                          delay: after,
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Three things a day.\nOne shared plan.',
                              style: text.displaySmall,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FadeSlideIn(
                          delay: after,
                          index: 1,
                          child: Text(
                            'A calm planner for a two-person team.',
                            style: text.bodyLarge!.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        for (final (i, (icon, label)) in _points.indexed)
                          FadeSlideIn(
                            delay: after,
                            index: 2 + i,
                            child: _Point(icon: icon, label: label),
                          ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.xxl),
                        FadeSlideIn(
                          delay: after,
                          index: 5,
                          child: FilledButton(
                            onPressed: () => context.push(AppRoutes.signUp),
                            child: const Text('Create an account'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FadeSlideIn(
                          delay: after,
                          index: 6,
                          child: OutlinedButton(
                            onPressed: () => context.push(AppRoutes.signIn),
                            child: const Text('I already have an account'),
                          ),
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

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: context.colors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.text.bodyLarge)),
        ],
      ),
    );
  }
}
