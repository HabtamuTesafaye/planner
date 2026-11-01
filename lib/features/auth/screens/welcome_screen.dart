import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../router_redirect.dart';
import '../widgets/google_button.dart';
import '../widgets/today_preview.dart';

/// First screen when signed out. The mark draws itself, then the words, a
/// live preview of Today, and the actions arrive in order. The two actions sit in the bottom half, within
/// thumb reach.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                          child: BrandMark(
                            size: AppSizes.brandMarkSmall,
                            animate: true,
                          ),
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
                            'Projects, outreach and income for you and your '
                            'team, in one calm place.',
                            style: text.bodyLarge!.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const FadeSlideIn(
                          delay: after,
                          index: 2,
                          child: TodayPreview(),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.xxl),
                        FadeSlideIn(
                          delay: after,
                          index: 3,
                          child: FilledButton(
                            onPressed: () => context.push(AppRoutes.signUp),
                            child: const Text('Create an account'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const FadeSlideIn(
                          delay: after,
                          index: 4,
                          child: GoogleButton(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FadeSlideIn(
                          delay: after,
                          index: 5,
                          child: TextButton(
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
