// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_picker_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(plannableRecipeSource)
final plannableRecipeSourceProvider = PlannableRecipeSourceProvider._();

final class PlannableRecipeSourceProvider
    extends
        $FunctionalProvider<
          RecipeRepository,
          RecipeRepository,
          RecipeRepository
        >
    with $Provider<RecipeRepository> {
  PlannableRecipeSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannableRecipeSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannableRecipeSourceHash();

  @$internal
  @override
  $ProviderElement<RecipeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeRepository create(Ref ref) {
    return plannableRecipeSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeRepository>(value),
    );
  }
}

String _$plannableRecipeSourceHash() =>
    r'0542b81900bde91b9e76eb17edf6056b6847992c';

/// Recipes the cook can drop into a slot, searchable the same way the recipe
/// list is -- diacritic- and case-insensitive, via `title_normalized`.
///
/// Watches [recipesRevisionProvider] so a recipe created moments ago (from
/// this screen or the recipes tab) shows up without a manual refresh.

@ProviderFor(plannableRecipes)
final plannableRecipesProvider = PlannableRecipesFamily._();

/// Recipes the cook can drop into a slot, searchable the same way the recipe
/// list is -- diacritic- and case-insensitive, via `title_normalized`.
///
/// Watches [recipesRevisionProvider] so a recipe created moments ago (from
/// this screen or the recipes tab) shows up without a manual refresh.

final class PlannableRecipesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Recipe>>,
          List<Recipe>,
          FutureOr<List<Recipe>>
        >
    with $FutureModifier<List<Recipe>>, $FutureProvider<List<Recipe>> {
  /// Recipes the cook can drop into a slot, searchable the same way the recipe
  /// list is -- diacritic- and case-insensitive, via `title_normalized`.
  ///
  /// Watches [recipesRevisionProvider] so a recipe created moments ago (from
  /// this screen or the recipes tab) shows up without a manual refresh.
  PlannableRecipesProvider._({
    required PlannableRecipesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'plannableRecipesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plannableRecipesHash();

  @override
  String toString() {
    return r'plannableRecipesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Recipe>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Recipe>> create(Ref ref) {
    final argument = this.argument as String;
    return plannableRecipes(ref, query: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlannableRecipesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannableRecipesHash() => r'113da3079fdb9fff6ad29aefcb251af04d2476ba';

/// Recipes the cook can drop into a slot, searchable the same way the recipe
/// list is -- diacritic- and case-insensitive, via `title_normalized`.
///
/// Watches [recipesRevisionProvider] so a recipe created moments ago (from
/// this screen or the recipes tab) shows up without a manual refresh.

final class PlannableRecipesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Recipe>>, String> {
  PlannableRecipesFamily._()
    : super(
        retry: null,
        name: r'plannableRecipesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recipes the cook can drop into a slot, searchable the same way the recipe
  /// list is -- diacritic- and case-insensitive, via `title_normalized`.
  ///
  /// Watches [recipesRevisionProvider] so a recipe created moments ago (from
  /// this screen or the recipes tab) shows up without a manual refresh.

  PlannableRecipesProvider call({String query = ''}) =>
      PlannableRecipesProvider._(argument: query, from: this);

  @override
  String toString() => r'plannableRecipesProvider';
}
