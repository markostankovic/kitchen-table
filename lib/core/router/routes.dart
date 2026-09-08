/// Typed route definitions (docs/ARCHITECTURE.md, "Routing").
///
/// Routes are declared once here and generated into `$appRoutes` by
/// `go_router_builder`. Navigate with the generated helpers -- for example
/// `const RecipesRoute().go(context)` -- never with a raw path string, so a
/// renamed route is a compile error rather than a runtime 404.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';
import '../../features/auth/presentation/settings_screen.dart';
import '../../features/households/presentation/create_household_screen.dart';
import '../../features/households/presentation/household_screen.dart';
import '../../features/households/presentation/join_household_screen.dart';
import '../../features/meal_plan/presentation/meal_plan_screen.dart';
import '../../features/recipes/presentation/recipe_detail_screen.dart';
import '../../features/recipes/presentation/recipe_edit_screen.dart';
import '../../features/recipes/presentation/recipe_list_screen.dart';
import '../../features/shopping_list/presentation/shopping_list_screen.dart';
import 'app_shell.dart';

part 'routes.g.dart';

// Onboarding routes sit outside the shell, so the bottom nav does not render
// while signing in or naming a household.

@TypedGoRoute<SignInRoute>(path: SignInRoute.path)
class SignInRoute extends GoRouteData with $SignInRoute {
  const SignInRoute();

  static const String path = '/sign-in';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SignInScreen();
}

@TypedGoRoute<VerifyOtpRoute>(path: VerifyOtpRoute.path)
class VerifyOtpRoute extends GoRouteData with $VerifyOtpRoute {
  const VerifyOtpRoute({required this.email});

  /// Carried as a query parameter, so a resend has the address without
  /// re-asking for it.
  final String email;

  static const String path = '/sign-in/verify';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      VerifyOtpScreen(email: email);
}

@TypedGoRoute<CreateHouseholdRoute>(path: CreateHouseholdRoute.path)
class CreateHouseholdRoute extends GoRouteData with $CreateHouseholdRoute {
  const CreateHouseholdRoute();

  static const String path = '/create-household';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CreateHouseholdScreen();
}

@TypedGoRoute<JoinHouseholdRoute>(path: JoinHouseholdRoute.path)
class JoinHouseholdRoute extends GoRouteData with $JoinHouseholdRoute {
  const JoinHouseholdRoute();

  static const String path = '/join-household';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const JoinHouseholdScreen();
}

@TypedStatefulShellRoute<AppShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<RecipesBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<RecipesRoute>(
          path: RecipesRoute.path,
          routes: <TypedRoute<RouteData>>[
            // `new` is declared BEFORE `:recipeId` deliberately -- see the
            // comment on RecipeDetailRoute.
            TypedGoRoute<RecipeNewRoute>(path: 'new'),
            TypedGoRoute<RecipeDetailRoute>(
              path: ':recipeId',
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<RecipeEditRoute>(path: 'edit'),
              ],
            ),
          ],
        ),
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
        TypedGoRoute<SettingsRoute>(
          path: SettingsRoute.path,
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<HouseholdRoute>(path: 'household'),
          ],
        ),
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

/// The editor with no recipe behind it yet.
///
/// Declared before [RecipeDetailRoute] in the branch above, because go_router
/// matches in order: after it, `/recipes/new` would load a recipe whose id is
/// "new".
class RecipeNewRoute extends GoRouteData with $RecipeNewRoute {
  const RecipeNewRoute();

  static const String path = '/recipes/new';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RecipeEditScreen();
}

/// Nested under the recipes tab, so it keeps the bottom nav and the back
/// stack.
///
/// When a literal segment is added under `/recipes` -- `new`, for the edit
/// screen -- it must be declared BEFORE this one, or go_router matches
/// `/recipes/new` here and tries to load a recipe whose id is "new".
class RecipeDetailRoute extends GoRouteData with $RecipeDetailRoute {
  const RecipeDetailRoute(this.recipeId);

  final String recipeId;

  static const String path = '/recipes/:recipeId';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      RecipeDetailScreen(recipeId: recipeId);
}

/// The editor over an existing recipe, nested under its detail page so Back
/// returns there.
class RecipeEditRoute extends GoRouteData with $RecipeEditRoute {
  const RecipeEditRoute(this.recipeId);

  final String recipeId;

  static const String path = '/recipes/:recipeId/edit';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      RecipeEditScreen(recipeId: recipeId);
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

/// Nested under Settings, so it keeps the bottom nav and the back stack.
class HouseholdRoute extends GoRouteData with $HouseholdRoute {
  const HouseholdRoute();

  static const String path = '/settings/household';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const HouseholdScreen();
}
