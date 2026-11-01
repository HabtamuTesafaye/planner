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
    this.top,
    this.subtitle,
    this.largeTitle = false,
    this.bottomPadding = AppSpacing.xxl,
    this.itemCount = 0,
    this.itemBuilder,
    this.footer = const [],
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final RefreshCallback? onRefresh;

  /// Optional widget above the title, for example the space switcher.
  final Widget? top;

  /// Muted line under the title.
  final String? subtitle;

  /// Fraunces display size instead of the screen-title size (Today's date).
  final bool largeTitle;

  /// Space under the content, larger when a floating button covers it.
  final double bottomPadding;

  /// Optional long list under [children], built lazily (only visible rows
  /// are built), so screens stay fast with hundreds of items.
  final int itemCount;
  final IndexedWidgetBuilder? itemBuilder;

  /// Widgets after the lazy list.
  final List<Widget> footer;

  /// Optional widget at the end of the title row (for example a progress
  /// ring on Today).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final header = [
      if (top != null) ...[top!, const SizedBox(height: AppSpacing.xs)],
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: largeTitle
                        ? context.text.displayMedium
                        : context.text.headlineMedium,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: context.text.titleMedium!.copyWith(
                      color: context.colors.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
      ...children,
    ];
    final builder = itemBuilder;
    final list = CustomScrollView(
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            top == null ? AppSpacing.xl : AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList.list(children: header),
        ),
        if (builder != null && itemCount > 0)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList.builder(
              itemCount: itemCount,
              itemBuilder: builder,
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            bottomPadding,
          ),
          sliver: SliverList.list(children: footer),
        ),
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
