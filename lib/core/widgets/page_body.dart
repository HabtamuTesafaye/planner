import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

/// Standard tab page: safe area, centered content at max 600 dp, a Fraunces
/// title and a scrollable body so large fonts never overflow. Pass
/// [onRefresh] to enable pull to refresh.
class PageBody extends StatelessWidget {
  const PageBody({
    required this.title,
    required this.children,
    this.onRefresh,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
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
    );

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: onRefresh == null
              ? list
              : RefreshIndicator(
                  onRefresh: onRefresh!,
                  color: context.colors.accent,
                  backgroundColor: context.colors.surface,
                  child: list,
                ),
        ),
      ),
    );
  }
}
