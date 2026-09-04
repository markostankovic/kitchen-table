/// Typed route definitions (docs/ARCHITECTURE.md, "Routing").
///
/// Routes are declared once here and generated into `$appRoutes` by
/// `go_router_builder`. Navigate with the generated helpers -- for example
/// `const RecipesRoute().go(context)` -- never with a raw path string, so a
/// renamed route is a compile error rather than a runtime 404.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/households/presentation/settings_screen.dart';
import '../../features/meal_plan/presentation/meal_plan_screen.dart';
import '../../features/recipes/presentation/recipe_list_screen.dart';
import '../../features/shopping_list/presentation/shopping_list_screen.dart';
import 'app_shell.dart';

part 'routes.g.dart';

@TypedStatefulShellRoute<AppShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<RecipesBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<RecipesRoute>(path: RecipesRoute.path),
      ],
    ),
    TypedStatefulShellBranch<MealPlanBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<MealPlanRoute>(path: MealPlanRoute.path),
      ],
    ),
    TypedStatefulShellBranch<ShoppingListBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ShoppingListRoute>(path: ShoppingListRoute.path),
      ],
    ),
    TypedStatefulShellBranch<SettingsBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SettingsRoute>(path: SettingsRoute.path),
      ],
    ),
  ],
)
class AppShellRoute extends StatefulShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) =>
      AppShell(navigationShell: navigationShell);
}

class RecipesBranch extends StatefulShellBranchData {
  const RecipesBranch();
}

class MealPlanBranch extends StatefulShellBranchData {
  const MealPlanBranch();
}

class ShoppingListBranch extends StatefulShellBranchData {
  const ShoppingListBranch();
}

class SettingsBranch extends StatefulShellBranchData {
  const SettingsBranch();
}

class RecipesRoute extends GoRouteData with $RecipesRoute {
  const RecipesRoute();

  static const String path = '/recipes';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RecipeListScreen();
}

class MealPlanRoute extends GoRouteData with $MealPlanRoute {
  const MealPlanRoute();

  static const String path = '/plan';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MealPlanScreen();
}

class ShoppingListRoute extends GoRouteData with $ShoppingListRoute {
  const ShoppingListRoute();

  static const String path = '/list';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ShoppingListScreen();
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  static const String path = '/settings';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}
