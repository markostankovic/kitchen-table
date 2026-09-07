// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $signInRoute,
  $verifyOtpRoute,
  $createHouseholdRoute,
  $joinHouseholdRoute,
  $appShellRoute,
];

RouteBase get $signInRoute => GoRouteData.$route(
  path: '/sign-in',
  hasOverriddenOnExit: false,
  factory: $SignInRoute._fromState,
);

mixin $SignInRoute on GoRouteData {
  static SignInRoute _fromState(GoRouterState state) => const SignInRoute();

  @override
  String get location => GoRouteData.$location('/sign-in');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $verifyOtpRoute => GoRouteData.$route(
  path: '/sign-in/verify',
  hasOverriddenOnExit: false,
  factory: $VerifyOtpRoute._fromState,
);

mixin $VerifyOtpRoute on GoRouteData {
  static VerifyOtpRoute _fromState(GoRouterState state) =>
      VerifyOtpRoute(email: state.uri.queryParameters['email']!);

  VerifyOtpRoute get _self => this as VerifyOtpRoute;

  @override
  String get location => GoRouteData.$location(
    '/sign-in/verify',
    queryParams: {'email': _self.email},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $createHouseholdRoute => GoRouteData.$route(
  path: '/create-household',
  hasOverriddenOnExit: false,
  factory: $CreateHouseholdRoute._fromState,
);

mixin $CreateHouseholdRoute on GoRouteData {
  static CreateHouseholdRoute _fromState(GoRouterState state) =>
      const CreateHouseholdRoute();

  @override
  String get location => GoRouteData.$location('/create-household');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $joinHouseholdRoute => GoRouteData.$route(
  path: '/join-household',
  hasOverriddenOnExit: false,
  factory: $JoinHouseholdRoute._fromState,
);

mixin $JoinHouseholdRoute on GoRouteData {
  static JoinHouseholdRoute _fromState(GoRouterState state) =>
      const JoinHouseholdRoute();

  @override
  String get location => GoRouteData.$location('/join-household');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $appShellRoute => StatefulShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/recipes',
          hasOverriddenOnExit: false,
          factory: $RecipesRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: ':recipeId',
              hasOverriddenOnExit: false,
              factory: $RecipeDetailRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/plan',
          hasOverriddenOnExit: false,
          factory: $MealPlanRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/list',
          hasOverriddenOnExit: false,
          factory: $ShoppingListRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/settings',
          hasOverriddenOnExit: false,
          factory: $SettingsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'household',
              hasOverriddenOnExit: false,
              factory: $HouseholdRoute._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $RecipesRoute on GoRouteData {
  static RecipesRoute _fromState(GoRouterState state) => const RecipesRoute();

  @override
  String get location => GoRouteData.$location('/recipes');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RecipeDetailRoute on GoRouteData {
  static RecipeDetailRoute _fromState(GoRouterState state) =>
      RecipeDetailRoute(state.pathParameters['recipeId']!);

  RecipeDetailRoute get _self => this as RecipeDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/recipes/${Uri.encodeComponent(_self.recipeId)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MealPlanRoute on GoRouteData {
  static MealPlanRoute _fromState(GoRouterState state) => const MealPlanRoute();

  @override
  String get location => GoRouteData.$location('/plan');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ShoppingListRoute on GoRouteData {
  static ShoppingListRoute _fromState(GoRouterState state) =>
      const ShoppingListRoute();

  @override
  String get location => GoRouteData.$location('/list');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HouseholdRoute on GoRouteData {
  static HouseholdRoute _fromState(GoRouterState state) =>
      const HouseholdRoute();

  @override
  String get location => GoRouteData.$location('/settings/household');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
