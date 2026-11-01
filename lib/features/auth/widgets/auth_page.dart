import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';

/// Layout for the sign-in, sign-up and setup screens: optional back
/// button, Fraunces title, short subtitle, scrollable body that stays above
/// the keyboard, centered at max 600 dp on large screens.
class AuthPage extends StatelessWidget {
  const AuthPage({
    required this.title,
    required this.children,
    this.subtitle,
    this.showBack = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBack && context.canPop())
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: context.pop,
                        tooltip: 'Back',
                        icon: const Icon(Symbols.arrow_back),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.xl),
                  const SizedBox(height: AppSpacing.lg),
                  FadeSlideIn(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: context.text.headlineMedium),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    FadeSlideIn(
                      index: 1,
                      child: Text(
                        subtitle!,
                        style: context.text.bodyLarge!.copyWith(
                          color: context.colors.muted,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FadeSlideIn(
                    index: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
