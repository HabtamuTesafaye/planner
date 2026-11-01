import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/theme_context.dart';
import 'offline_banner.dart';

/// Bottom-tab shell: Today, Outreach, Money, Team.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Symbols.edit_note),
      selectedIcon: Icon(Symbols.edit_note, weight: 500),
      label: 'Today',
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
      icon: Icon(Symbols.group),
      selectedIcon: Icon(Symbols.group, weight: 500),
      label: 'Team',
    ),
  ];

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab returns it to its first page.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Wired to connectivity in Phase 7.
          const SafeArea(bottom: false, child: OfflineBanner(visible: false)),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelect,
          destinations: _destinations,
        ),
      ),
    );
  }
}
