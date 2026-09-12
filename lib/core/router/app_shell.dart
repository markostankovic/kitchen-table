import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../net/offline_banner.dart';

/// Bottom-nav shell: Recipes / Plan / List / Settings (docs/ARCHITECTURE.md).
///
/// Each tab is a `StatefulShellBranch`, so switching tabs preserves the
/// navigation stack within a tab rather than resetting it.
///
/// Labels are hardcoded English for now. UI strings move to ARB files in
/// Phase 3 (docs/ROADMAP.md); adding `flutter_localizations` earlier would be
/// scaffolding for a phase that has not started.
///
/// [OfflineBanner] sits above [navigationShell] rather than inside each
/// branch's own `Scaffold` -- one instance, visible on every tab including
/// Settings, which has no cache of its own to be stale but still cannot save
/// a write while offline (Phase 2 part 6b, D76). A `ConsumerWidget` rather
/// than `StatelessWidget`, the one change this class needed to watch
/// [NetworkStatus].
class AppShell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
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
