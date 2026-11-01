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
import 'offline_banner.dart';

/// Bottom-tab shell: Today, Projects, Outreach, Money, Space. Also shows
/// the offline banner, refreshes live data when the connection returns,
/// and keeps the daily reminder in sync with the profile setting.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Symbols.edit_note),
      selectedIcon: Icon(Symbols.edit_note, weight: 500),
      label: 'Today',
    ),
    NavigationDestination(
      icon: Icon(Symbols.folder_open),
      selectedIcon: Icon(Symbols.folder_open, weight: 500),
      label: 'Projects',
    ),
    NavigationDestination(
      icon: Icon(Symbols.handshake),
      selectedIcon: Icon(Symbols.handshake, weight: 500),
      label: 'Outreach',
    ),
    NavigationDestination(
      icon: Icon(Symbols.payments),
      selectedIcon: Icon(Symbols.payments, weight: 500),
      label: 'Money',
    ),
    NavigationDestination(
      icon: Icon(Symbols.workspaces),
      selectedIcon: Icon(Symbols.workspaces, weight: 500),
      label: 'Space',
    ),
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
      body: Column(
        children: [
          SafeArea(bottom: false, child: OfflineBanner(visible: !online)),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onSelect,
          destinations: AppShell._destinations,
        ),
      ),
    );
  }
}
