import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Standard tab page: safe area, centered content at max 600 dp, a Fraunces
/// title and a scrollable body so large fonts never overflow.
class PageBody extends StatelessWidget {
  const PageBody({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              Semantics(
                header: true,
                child: Text(title, style: context.text.headlineMedium),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
