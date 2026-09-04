import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav shell: Recipes / Plan / List / Settings (docs/ARCHITECTURE.md).
///
/// Each tab is a `StatefulShellBranch`, so switching tabs preserves the
/// navigation stack within a tab rather than resetting it.
///
/// Labels are hardcoded English for now. UI strings move to ARB files in
/// Phase 3 (docs/ROADMAP.md); adding `flutter_localizations` earlier would be
/// scaffolding for a phase that has not started.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<NavigationDestination> _destinations =
      <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Recipes',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Plan',
    ),
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: 'List',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: _destinations,
        onDestinationSelected: (int index) => navigationShell.goBranch(
          index,
          // Tapping the active tab returns it to its root, the platform
          // convention on both iOS and Android.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
