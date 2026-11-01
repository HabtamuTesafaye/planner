import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/connectivity.dart';
import '../../data/reminders/reminder_service.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/money/providers/money_providers.dart';
import '../../features/outreach/providers/outreach_providers.dart';
import '../../features/projects/providers/projects_providers.dart';
import '../../features/space/providers/progress_providers.dart';
import '../../features/space/providers/space_providers.dart';
import '../../features/today/providers/today_providers.dart';
import '../theme/theme_context.dart';
import 'floating_nav_bar.dart';
import 'offline_banner.dart';

/// Bottom-tab shell: Today, Projects, Outreach, Money, Space. Also shows
/// the offline banner, refreshes live data when the connection returns,
/// and keeps the daily reminder in sync with the profile setting.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    NavItem(icon: Symbols.edit_note, label: 'Today'),
    NavItem(icon: Symbols.folder_open, label: 'Projects'),
    NavItem(icon: Symbols.handshake, label: 'Outreach'),
    NavItem(icon: Symbols.payments, label: 'Money'),
    NavItem(icon: Symbols.workspaces, label: 'Space'),
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Back online: reload everything that may have missed updates.
    ref.listenManual(isOnlineProvider, (was, now) {
      if (was == false && now) {
        ref
          ..invalidate(mySpacesProvider)
          ..invalidate(myTasksProvider)
          ..invalidate(weeklyGoalProvider)
          ..invalidate(projectsProvider)
          ..invalidate(projectItemsProvider)
          ..invalidate(contactsProvider)
          ..invalidate(incomeEntriesProvider)
          ..invalidate(monthlyTargetProvider)
          ..invalidate(spaceTasksProvider);
      }
    });
    // Daily reminder follows the profile (also after sign-in on a new phone).
    ref.listenManual(
      currentProfileProvider.select((p) => p.value?.reminderTime),
      (_, time) => unawaited(ref.read(reminderServiceProvider).sync(time)),
      fireImmediately: true,
    );
  }

  void _onSelect(int index) {
    final shell = widget.navigationShell;
    if (index != shell.currentIndex) {
      unawaited(HapticFeedback.selectionClick());
    }
    // Tapping the active tab returns it to its first page.
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(isOnlineProvider);
    return Scaffold(
      // Same color as the top of each tab's wash, so the status bar area
      // and the page read as one surface.
      backgroundColor: context.colors.accentSoft,
      body: Column(
        children: [
          SafeArea(bottom: false, child: OfflineBanner(visible: !online)),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        items: AppShell._items,
        selectedIndex: widget.navigationShell.currentIndex,
        onSelect: _onSelect,
      ),
    );
  }
}
