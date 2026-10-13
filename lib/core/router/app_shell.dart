import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/households/application/household_providers.dart';
import '../../features/meal_plan/application/meal_plan_providers.dart';
import '../../features/recipes/application/recipe_providers.dart';
import '../../features/shopping_list/application/shopping_list_providers.dart';
import '../household/current_household.dart';
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
///
/// Switching to a different tab re-reads that tab's data (D149), so a change
/// another household member made on their phone shows up without a pull.
/// [_refreshBranch] invalidates the selected branch's top-level providers
/// before `goBranch`; each is a cached read (D67), so the screen keeps its
/// content and updates in place. Re-tapping the current tab only pops it to
/// its root -- pull already refreshes in place.
///
/// After a household switch, every *other* tab goes back to its root the
/// next time it is opened (phase9-household-switcher), so no screen from
/// the old household -- a recipe, a household's detail -- survives under a
/// tab. [_stale] collects them when the household id changes, and arriving
/// on one passes `initialLocation: true`. go_router has no public API to
/// reset a background branch, and looping `goBranch` over every branch at
/// switch time does not work: successive `router.go` calls in one frame
/// coalesce. The current tab is never reset: from the switch sheet it is
/// already at its root (the header lives only on tab roots), and from the
/// Households list it should stay on the list (D170). A
/// `ConsumerStatefulWidget` now, to hold that set.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();

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

}

class _AppShellState extends ConsumerState<AppShell> {
  /// Branches to send to their root on their next visit, after a household
  /// switch.
  final Set<int> _stale = <int>{};

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    // `.value`, not the AsyncValue: `switchTo`'s invalidate passes through a
    // loading state that keeps the old value.
    ref.listen<AsyncValue<String?>>(currentHouseholdIdProvider, (
      AsyncValue<String?>? prev,
      AsyncValue<String?> next,
    ) {
      final String? before = prev?.value;
      final String? after = next.value;
      if (before == null || after == null || before == after) return;
      for (int i = 0; i < navigationShell.route.branches.length; i++) {
        if (i != navigationShell.currentIndex) _stale.add(i);
      }
    });
    // A tab reached some other way -- Manage households' `go` -- has been
    // visited, so is no longer stale.
    _stale.remove(navigationShell.currentIndex);

    return Scaffold(
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: AppShell._destinations(loc),
        onDestinationSelected: (int index) {
          final bool reTap = index == navigationShell.currentIndex;
          // `remove` first, so it always runs.
          final bool reset = _stale.remove(index) || reTap;
          if (!reTap) _refreshBranch(ref, index);
          navigationShell.goBranch(
            index,
            // Tapping the active tab returns it to its root, the platform
            // convention on both iOS and Android; so does arriving on a tab
            // after a household switch.
            initialLocation: reset,
          );
        },
      ),
    );
  }

  /// Re-reads the top-level data of the branch at [index] (D149).
  ///
  /// `ref.invalidate`, never a `core/refresh/` revision `.bump()`: a bump
  /// means "a write happened" and fans out to other tabs, and a tab switch
  /// is not a write.
  ///
  /// - Recipes: the whole [recipeListProvider] family, since the shell does
  ///   not know the screen's query, tag or favourites filter. Not
  ///   `tagLabelsProvider` -- it is network-only, so re-reading it offline
  ///   would lose the labels.
  /// - Plan: [mealPlanEditorProvider], the visible week only.
  /// - List: [currentShoppingListProvider], a re-read only. A pull there
  ///   means *generate* (D147), which is a write; a tab switch never is.
  /// - Settings: [householdMembersProvider], which feeds the member count
  ///   (the whole family), and [myHouseholdsProvider], which feeds the count
  ///   of other households. Not `currentHouseholdProvider` -- it is keepAlive and the root of
  ///   every tab's household id.
  static void _refreshBranch(WidgetRef ref, int index) {
    switch (index) {
      case 0:
        ref.invalidate(recipeListProvider);
      case 1:
        ref.invalidate(mealPlanEditorProvider);
      case 2:
        ref.invalidate(currentShoppingListProvider);
      case 3:
        ref.invalidate(householdMembersProvider);
        ref.invalidate(myHouseholdsProvider);
    }
  }
}
