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

/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types. The screen debounces.
///
/// Watches [recipesRevisionProvider] so that any feature can invalidate this
/// without importing it -- which `features/import/` cannot do.

@ProviderFor(recipeList)
final recipeListProvider = RecipeListFamily._();

/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types. The screen debounces.
///
/// Watches [recipesRevisionProvider] so that any feature can invalidate this
/// without importing it -- which `features/import/` cannot do.

final class RecipeListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Recipe>>,
          List<Recipe>,
          FutureOr<List<Recipe>>
        >
    with $FutureModifier<List<Recipe>>, $FutureProvider<List<Recipe>> {
  /// Not `keepAlive`: one entry per query string, and the family would grow
  /// without bound as somebody types. The screen debounces.
  ///
  /// Watches [recipesRevisionProvider] so that any feature can invalidate this
  /// without importing it -- which `features/import/` cannot do.
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

String _$recipeListHash() => r'354cdb3736d2169451bfafb94db4c28d78f38f44';

/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types. The screen debounces.
///
/// Watches [recipesRevisionProvider] so that any feature can invalidate this
/// without importing it -- which `features/import/` cannot do.

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

  /// Not `keepAlive`: one entry per query string, and the family would grow
  /// without bound as somebody types. The screen debounces.
  ///
  /// Watches [recipesRevisionProvider] so that any feature can invalidate this
  /// without importing it -- which `features/import/` cannot do.

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
