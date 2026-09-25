import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../net/offline_banner.dart';

/// Bottom-nav shell: Recipes / Plan / List / Settings (docs/ARCHITECTURE.md).
///
/// Each tab is a `StatefulShellBranch`, so switching tabs preserves the
/// navigation stack within a tab rather than resetting it.
///
/// Labels are localized (D77, Phase 3 part 1) -- a `List<NavigationDestination>`
/// built from [AppLocalizations] rather than the `static const` list this
/// class used to carry, since a `const` value cannot read a localized string.
/// Each tab's own AppBar title uses the same key (`navRecipes`, `navPlan`,
/// `navList`, `navSettings`), so a tab and its header never disagree about
/// what language they are in -- everything else on those screens stays
/// English until the parts that own them are localized in turn.
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

  static List<NavigationDestination> _destinations(AppLocalizations loc) =>
      <NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: const Icon(Icons.menu_book),
          label: loc.navRecipes,
        ),
        NavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: loc.navPlan,
        ),
        // List and Settings take the design's glyphs (D118): a bulleted list
        // rather than a checklist, sliders rather than a cog. The list glyph
        // has no filled variant worth using, so both states are the same
        // icon -- the `primary` pill behind it is what marks it selected.
        NavigationDestination(
          icon: const Icon(Icons.format_list_bulleted),
          selectedIcon: const Icon(Icons.format_list_bulleted),
          label: loc.navList,
        ),
        NavigationDestination(
          icon: const Icon(Icons.tune_outlined),
          selectedIcon: const Icon(Icons.tune),
          label: loc.navSettings,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: _destinations(loc),
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
