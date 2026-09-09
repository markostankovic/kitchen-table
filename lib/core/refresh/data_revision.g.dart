// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_revision.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bumped whenever a recipe is created, edited or deleted.
///
/// `keepAlive` because it outlives every screen that watches it -- that is the
/// entire point. It is an int, so keeping it costs nothing.

@ProviderFor(RecipesRevision)
final recipesRevisionProvider = RecipesRevisionProvider._();

/// Bumped whenever a recipe is created, edited or deleted.
///
/// `keepAlive` because it outlives every screen that watches it -- that is the
/// entire point. It is an int, so keeping it costs nothing.
final class RecipesRevisionProvider
    extends $NotifierProvider<RecipesRevision, int> {
  /// Bumped whenever a recipe is created, edited or deleted.
  ///
  /// `keepAlive` because it outlives every screen that watches it -- that is the
  /// entire point. It is an int, so keeping it costs nothing.
  RecipesRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipesRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipesRevisionHash();

  @$internal
  @override
  RecipesRevision create() => RecipesRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$recipesRevisionHash() => r'c43db65874b576d2061ce1d5e53e428304dac62d';

/// Bumped whenever a recipe is created, edited or deleted.
///
/// `keepAlive` because it outlives every screen that watches it -- that is the
/// entire point. It is an int, so keeping it costs nothing.

abstract class _$RecipesRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Bumped whenever a meal plan entry is added, moved, edited or removed.
///
/// One consumer today -- `MealPlanEditor` re-reading the visible week after
/// its own writes -- but the reason this lives here rather than inside
/// `features/meal_plan/application/` is the same one `RecipesRevision` was
/// moved here for: a later Phase 2 part's shopping list aggregates a week's
/// entries and will need to know when that week has changed, and
/// `features/shopping_list/` may not import `features/meal_plan/application/`.

@ProviderFor(MealPlanRevision)
final mealPlanRevisionProvider = MealPlanRevisionProvider._();

/// Bumped whenever a meal plan entry is added, moved, edited or removed.
///
/// One consumer today -- `MealPlanEditor` re-reading the visible week after
/// its own writes -- but the reason this lives here rather than inside
/// `features/meal_plan/application/` is the same one `RecipesRevision` was
/// moved here for: a later Phase 2 part's shopping list aggregates a week's
/// entries and will need to know when that week has changed, and
/// `features/shopping_list/` may not import `features/meal_plan/application/`.
final class MealPlanRevisionProvider
    extends $NotifierProvider<MealPlanRevision, int> {
  /// Bumped whenever a meal plan entry is added, moved, edited or removed.
  ///
  /// One consumer today -- `MealPlanEditor` re-reading the visible week after
  /// its own writes -- but the reason this lives here rather than inside
  /// `features/meal_plan/application/` is the same one `RecipesRevision` was
  /// moved here for: a later Phase 2 part's shopping list aggregates a week's
  /// entries and will need to know when that week has changed, and
  /// `features/shopping_list/` may not import `features/meal_plan/application/`.
  MealPlanRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealPlanRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealPlanRevisionHash();

  @$internal
  @override
  MealPlanRevision create() => MealPlanRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$mealPlanRevisionHash() => r'1ff51fa8477ac5a02d202ae1648ed4816bb9221a';

/// Bumped whenever a meal plan entry is added, moved, edited or removed.
///
/// One consumer today -- `MealPlanEditor` re-reading the visible week after
/// its own writes -- but the reason this lives here rather than inside
/// `features/meal_plan/application/` is the same one `RecipesRevision` was
/// moved here for: a later Phase 2 part's shopping list aggregates a week's
/// entries and will need to know when that week has changed, and
/// `features/shopping_list/` may not import `features/meal_plan/application/`.

abstract class _$MealPlanRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
