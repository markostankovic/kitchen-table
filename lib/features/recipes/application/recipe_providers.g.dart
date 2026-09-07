// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recipeRepository)
final recipeRepositoryProvider = RecipeRepositoryProvider._();

final class RecipeRepositoryProvider
    extends
        $FunctionalProvider<
          RecipeRepository,
          RecipeRepository,
          RecipeRepository
        >
    with $Provider<RecipeRepository> {
  RecipeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecipeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeRepository create(Ref ref) {
    return recipeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeRepository>(value),
    );
  }
}

String _$recipeRepositoryHash() => r'a8f584a947472af7a2164d18c8ce8d827dafeaab';

/// See the file header of `data/ingredient_catalog_datasource.dart`: this is
/// the recipes-side copy of catalog access that D33 chose to pay for.

@ProviderFor(ingredientCatalogDatasource)
final ingredientCatalogDatasourceProvider =
    IngredientCatalogDatasourceProvider._();

/// See the file header of `data/ingredient_catalog_datasource.dart`: this is
/// the recipes-side copy of catalog access that D33 chose to pay for.

final class IngredientCatalogDatasourceProvider
    extends
        $FunctionalProvider<
          IngredientCatalogDatasource,
          IngredientCatalogDatasource,
          IngredientCatalogDatasource
        >
    with $Provider<IngredientCatalogDatasource> {
  /// See the file header of `data/ingredient_catalog_datasource.dart`: this is
  /// the recipes-side copy of catalog access that D33 chose to pay for.
  IngredientCatalogDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ingredientCatalogDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ingredientCatalogDatasourceHash();

  @$internal
  @override
  $ProviderElement<IngredientCatalogDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IngredientCatalogDatasource create(Ref ref) {
    return ingredientCatalogDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IngredientCatalogDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IngredientCatalogDatasource>(value),
    );
  }
}

String _$ingredientCatalogDatasourceHash() =>
    r'77dfdf720f81c05b019916db321f6f210973551d';

/// Recipes in the caller's household, filtered by [query].
///
/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types. The screen debounces.

@ProviderFor(recipeList)
final recipeListProvider = RecipeListFamily._();

/// Recipes in the caller's household, filtered by [query].
///
/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types. The screen debounces.

final class RecipeListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Recipe>>,
          List<Recipe>,
          FutureOr<List<Recipe>>
        >
    with $FutureModifier<List<Recipe>>, $FutureProvider<List<Recipe>> {
  /// Recipes in the caller's household, filtered by [query].
  ///
  /// Not `keepAlive`: one entry per query string, and the family would grow
  /// without bound as somebody types. The screen debounces.
  RecipeListProvider._({
    required RecipeListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recipeListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeListHash();

  @override
  String toString() {
    return r'recipeListProvider'
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
    return recipeList(ref, query: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeListHash() => r'89abb8396f288e1c3d4390d76b25977a67396acc';

/// Recipes in the caller's household, filtered by [query].
///
/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types. The screen debounces.

final class RecipeListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Recipe>>, String> {
  RecipeListFamily._()
    : super(
        retry: null,
        name: r'recipeListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recipes in the caller's household, filtered by [query].
  ///
  /// Not `keepAlive`: one entry per query string, and the family would grow
  /// without bound as somebody types. The screen debounces.

  RecipeListProvider call({String query = ''}) =>
      RecipeListProvider._(argument: query, from: this);

  @override
  String toString() => r'recipeListProvider';
}

/// One recipe with its lines and steps, names resolved from the catalog.

@ProviderFor(recipeDetail)
final recipeDetailProvider = RecipeDetailFamily._();

/// One recipe with its lines and steps, names resolved from the catalog.

final class RecipeDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecipeDetail>,
          RecipeDetail,
          FutureOr<RecipeDetail>
        >
    with $FutureModifier<RecipeDetail>, $FutureProvider<RecipeDetail> {
  /// One recipe with its lines and steps, names resolved from the catalog.
  RecipeDetailProvider._({
    required RecipeDetailFamily super.from,
    required (String, {String locale}) super.argument,
  }) : super(
         retry: null,
         name: r'recipeDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeDetailHash();

  @override
  String toString() {
    return r'recipeDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<RecipeDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecipeDetail> create(Ref ref) {
    final argument = this.argument as (String, {String locale});
    return recipeDetail(ref, argument.$1, locale: argument.locale);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeDetailHash() => r'5bda84407446561151bbf8df28d1c1522c7cb359';

/// One recipe with its lines and steps, names resolved from the catalog.

final class RecipeDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<RecipeDetail>,
          (String, {String locale})
        > {
  RecipeDetailFamily._()
    : super(
        retry: null,
        name: r'recipeDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One recipe with its lines and steps, names resolved from the catalog.

  RecipeDetailProvider call(String recipeId, {String locale = 'sr'}) =>
      RecipeDetailProvider._(argument: (recipeId, locale: locale), from: this);

  @override
  String toString() => r'recipeDetailProvider';
}

/// The unit lexicon, fetched once.
///
/// `keepAlive` is justified for the same reason the ingredients feature gives:
/// roughly 120 immutable rows that only a migration changes, read on every
/// ingredient line the user touches. Dropping it when the editor closes would
/// mean a round trip every time it reopens, for data that cannot have changed.

@ProviderFor(recipeUnitCatalog)
final recipeUnitCatalogProvider = RecipeUnitCatalogProvider._();

/// The unit lexicon, fetched once.
///
/// `keepAlive` is justified for the same reason the ingredients feature gives:
/// roughly 120 immutable rows that only a migration changes, read on every
/// ingredient line the user touches. Dropping it when the editor closes would
/// mean a round trip every time it reopens, for data that cannot have changed.

final class RecipeUnitCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<UnitCatalog>,
          UnitCatalog,
          FutureOr<UnitCatalog>
        >
    with $FutureModifier<UnitCatalog>, $FutureProvider<UnitCatalog> {
  /// The unit lexicon, fetched once.
  ///
  /// `keepAlive` is justified for the same reason the ingredients feature gives:
  /// roughly 120 immutable rows that only a migration changes, read on every
  /// ingredient line the user touches. Dropping it when the editor closes would
  /// mean a round trip every time it reopens, for data that cannot have changed.
  RecipeUnitCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeUnitCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeUnitCatalogHash();

  @$internal
  @override
  $FutureProviderElement<UnitCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UnitCatalog> create(Ref ref) {
    return recipeUnitCatalog(ref);
  }
}

String _$recipeUnitCatalogHash() => r'8d7bc81acb0b53c92955ddf1bb923dacffe4ac3c';

/// Tier 1, ready to use: the pure parser with its lexicon already injected, so
/// no screen has to know that parsing depends on a fetch (D31).

@ProviderFor(recipeLineParser)
final recipeLineParserProvider = RecipeLineParserProvider._();

/// Tier 1, ready to use: the pure parser with its lexicon already injected, so
/// no screen has to know that parsing depends on a fetch (D31).

final class RecipeLineParserProvider
    extends
        $FunctionalProvider<
          AsyncValue<IngredientLineParser>,
          IngredientLineParser,
          FutureOr<IngredientLineParser>
        >
    with
        $FutureModifier<IngredientLineParser>,
        $FutureProvider<IngredientLineParser> {
  /// Tier 1, ready to use: the pure parser with its lexicon already injected, so
  /// no screen has to know that parsing depends on a fetch (D31).
  RecipeLineParserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeLineParserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeLineParserHash();

  @$internal
  @override
  $FutureProviderElement<IngredientLineParser> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IngredientLineParser> create(Ref ref) {
    return recipeLineParser(ref);
  }
}

String _$recipeLineParserHash() => r'4729364468623cb68300c95cc053bb311f610ca3';

/// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.

@ProviderFor(ingredientMatches)
final ingredientMatchesProvider = IngredientMatchesFamily._();

/// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.

final class IngredientMatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IngredientMatch>>,
          List<IngredientMatch>,
          FutureOr<List<IngredientMatch>>
        >
    with
        $FutureModifier<List<IngredientMatch>>,
        $FutureProvider<List<IngredientMatch>> {
  /// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.
  IngredientMatchesProvider._({
    required IngredientMatchesFamily super.from,
    required (String, {String locale}) super.argument,
  }) : super(
         retry: null,
         name: r'ingredientMatchesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ingredientMatchesHash();

  @override
  String toString() {
    return r'ingredientMatchesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<IngredientMatch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<IngredientMatch>> create(Ref ref) {
    final argument = this.argument as (String, {String locale});
    return ingredientMatches(ref, argument.$1, locale: argument.locale);
  }

  @override
  bool operator ==(Object other) {
    return other is IngredientMatchesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ingredientMatchesHash() => r'1701be85dbc62f0c2b38d29781ec640bfb5bdd36';

/// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.

final class IngredientMatchesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<IngredientMatch>>,
          (String, {String locale})
        > {
  IngredientMatchesFamily._()
    : super(
        retry: null,
        name: r'ingredientMatchesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.

  IngredientMatchesProvider call(String query, {String locale = 'sr'}) =>
      IngredientMatchesProvider._(
        argument: (query, locale: locale),
        from: this,
      );

  @override
  String toString() => r'ingredientMatchesProvider';
}
