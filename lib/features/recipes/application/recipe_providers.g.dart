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

String _$recipeRepositoryHash() => r'b2d7549eaac252b13652e02791ce593c6c1ed62d';

/// The household's recipes, matching [query] -- cache immediately, then the
/// network (Phase 2 part 6a, D67's shape widened from one row to many).
///
/// A `Stream`, not a `Future`, on `CurrentShoppingList`'s own precedent:
/// `watchList` emits a cached list immediately, then the network's answer,
/// and a `StreamNotifier` is what lets the second emission be part of the
/// provider's own lifecycle. The value type consumers see
/// (`AsyncValue<List<Recipe>>`) is unchanged from the old `Future`-based
/// provider.
///
/// Still a family, and still not `keepAlive`: one entry per query string,
/// disposed when nothing watches it, exactly as before -- the screen
/// debounces.
///
/// Watches [recipesRevisionProvider] so that any feature can invalidate this
/// without importing it -- which `features/import/` cannot do. `build()`
/// yields an empty list rather than reaching the repository at all when
/// there is no household, so a household-less caller never touches
/// `Supabase.instance.client` (the shell's tab loop relies on exactly this
/// under test, `CurrentShoppingList`'s own reasoning).

@ProviderFor(RecipeList)
final recipeListProvider = RecipeListFamily._();

/// The household's recipes, matching [query] -- cache immediately, then the
/// network (Phase 2 part 6a, D67's shape widened from one row to many).
///
/// A `Stream`, not a `Future`, on `CurrentShoppingList`'s own precedent:
/// `watchList` emits a cached list immediately, then the network's answer,
/// and a `StreamNotifier` is what lets the second emission be part of the
/// provider's own lifecycle. The value type consumers see
/// (`AsyncValue<List<Recipe>>`) is unchanged from the old `Future`-based
/// provider.
///
/// Still a family, and still not `keepAlive`: one entry per query string,
/// disposed when nothing watches it, exactly as before -- the screen
/// debounces.
///
/// Watches [recipesRevisionProvider] so that any feature can invalidate this
/// without importing it -- which `features/import/` cannot do. `build()`
/// yields an empty list rather than reaching the repository at all when
/// there is no household, so a household-less caller never touches
/// `Supabase.instance.client` (the shell's tab loop relies on exactly this
/// under test, `CurrentShoppingList`'s own reasoning).
final class RecipeListProvider
    extends $StreamNotifierProvider<RecipeList, List<Recipe>> {
  /// The household's recipes, matching [query] -- cache immediately, then the
  /// network (Phase 2 part 6a, D67's shape widened from one row to many).
  ///
  /// A `Stream`, not a `Future`, on `CurrentShoppingList`'s own precedent:
  /// `watchList` emits a cached list immediately, then the network's answer,
  /// and a `StreamNotifier` is what lets the second emission be part of the
  /// provider's own lifecycle. The value type consumers see
  /// (`AsyncValue<List<Recipe>>`) is unchanged from the old `Future`-based
  /// provider.
  ///
  /// Still a family, and still not `keepAlive`: one entry per query string,
  /// disposed when nothing watches it, exactly as before -- the screen
  /// debounces.
  ///
  /// Watches [recipesRevisionProvider] so that any feature can invalidate this
  /// without importing it -- which `features/import/` cannot do. `build()`
  /// yields an empty list rather than reaching the repository at all when
  /// there is no household, so a household-less caller never touches
  /// `Supabase.instance.client` (the shell's tab loop relies on exactly this
  /// under test, `CurrentShoppingList`'s own reasoning).
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
  RecipeList create() => RecipeList();

  @override
  bool operator ==(Object other) {
    return other is RecipeListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeListHash() => r'126f99b4ba574c289668069cd7396abf4dc8bbd9';

/// The household's recipes, matching [query] -- cache immediately, then the
/// network (Phase 2 part 6a, D67's shape widened from one row to many).
///
/// A `Stream`, not a `Future`, on `CurrentShoppingList`'s own precedent:
/// `watchList` emits a cached list immediately, then the network's answer,
/// and a `StreamNotifier` is what lets the second emission be part of the
/// provider's own lifecycle. The value type consumers see
/// (`AsyncValue<List<Recipe>>`) is unchanged from the old `Future`-based
/// provider.
///
/// Still a family, and still not `keepAlive`: one entry per query string,
/// disposed when nothing watches it, exactly as before -- the screen
/// debounces.
///
/// Watches [recipesRevisionProvider] so that any feature can invalidate this
/// without importing it -- which `features/import/` cannot do. `build()`
/// yields an empty list rather than reaching the repository at all when
/// there is no household, so a household-less caller never touches
/// `Supabase.instance.client` (the shell's tab loop relies on exactly this
/// under test, `CurrentShoppingList`'s own reasoning).

final class RecipeListFamily extends $Family
    with
        $ClassFamilyOverride<
          RecipeList,
          AsyncValue<List<Recipe>>,
          List<Recipe>,
          Stream<List<Recipe>>,
          String
        > {
  RecipeListFamily._()
    : super(
        retry: null,
        name: r'recipeListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The household's recipes, matching [query] -- cache immediately, then the
  /// network (Phase 2 part 6a, D67's shape widened from one row to many).
  ///
  /// A `Stream`, not a `Future`, on `CurrentShoppingList`'s own precedent:
  /// `watchList` emits a cached list immediately, then the network's answer,
  /// and a `StreamNotifier` is what lets the second emission be part of the
  /// provider's own lifecycle. The value type consumers see
  /// (`AsyncValue<List<Recipe>>`) is unchanged from the old `Future`-based
  /// provider.
  ///
  /// Still a family, and still not `keepAlive`: one entry per query string,
  /// disposed when nothing watches it, exactly as before -- the screen
  /// debounces.
  ///
  /// Watches [recipesRevisionProvider] so that any feature can invalidate this
  /// without importing it -- which `features/import/` cannot do. `build()`
  /// yields an empty list rather than reaching the repository at all when
  /// there is no household, so a household-less caller never touches
  /// `Supabase.instance.client` (the shell's tab loop relies on exactly this
  /// under test, `CurrentShoppingList`'s own reasoning).

  RecipeListProvider call({String query = ''}) =>
      RecipeListProvider._(argument: query, from: this);

  @override
  String toString() => r'recipeListProvider';
}

/// The household's recipes, matching [query] -- cache immediately, then the
/// network (Phase 2 part 6a, D67's shape widened from one row to many).
///
/// A `Stream`, not a `Future`, on `CurrentShoppingList`'s own precedent:
/// `watchList` emits a cached list immediately, then the network's answer,
/// and a `StreamNotifier` is what lets the second emission be part of the
/// provider's own lifecycle. The value type consumers see
/// (`AsyncValue<List<Recipe>>`) is unchanged from the old `Future`-based
/// provider.
///
/// Still a family, and still not `keepAlive`: one entry per query string,
/// disposed when nothing watches it, exactly as before -- the screen
/// debounces.
///
/// Watches [recipesRevisionProvider] so that any feature can invalidate this
/// without importing it -- which `features/import/` cannot do. `build()`
/// yields an empty list rather than reaching the repository at all when
/// there is no household, so a household-less caller never touches
/// `Supabase.instance.client` (the shell's tab loop relies on exactly this
/// under test, `CurrentShoppingList`'s own reasoning).

abstract class _$RecipeList extends $StreamNotifier<List<Recipe>> {
  late final _$args = ref.$arg as String;
  String get query => _$args;

  Stream<List<Recipe>> build({String query = ''});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Recipe>>, List<Recipe>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Recipe>>, List<Recipe>>,
              AsyncValue<List<Recipe>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(query: _$args));
  }
}

/// One recipe with its lines and steps, names resolved from the catalog.
///
/// Stays a plain `Future` (D74): network-first with a cache fallback on
/// `NetworkFailure`, the same one-emission shape
/// `IngredientRepository.fetchUnitCatalog()` uses, not the two-emission
/// stream [RecipeList] uses. See `RecipeRepository.fetchDetail`'s own doc
/// comment for why a single recipe differs from the whole list.

@ProviderFor(recipeDetail)
final recipeDetailProvider = RecipeDetailFamily._();

/// One recipe with its lines and steps, names resolved from the catalog.
///
/// Stays a plain `Future` (D74): network-first with a cache fallback on
/// `NetworkFailure`, the same one-emission shape
/// `IngredientRepository.fetchUnitCatalog()` uses, not the two-emission
/// stream [RecipeList] uses. See `RecipeRepository.fetchDetail`'s own doc
/// comment for why a single recipe differs from the whole list.

final class RecipeDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecipeDetail>,
          RecipeDetail,
          FutureOr<RecipeDetail>
        >
    with $FutureModifier<RecipeDetail>, $FutureProvider<RecipeDetail> {
  /// One recipe with its lines and steps, names resolved from the catalog.
  ///
  /// Stays a plain `Future` (D74): network-first with a cache fallback on
  /// `NetworkFailure`, the same one-emission shape
  /// `IngredientRepository.fetchUnitCatalog()` uses, not the two-emission
  /// stream [RecipeList] uses. See `RecipeRepository.fetchDetail`'s own doc
  /// comment for why a single recipe differs from the whole list.
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
///
/// Stays a plain `Future` (D74): network-first with a cache fallback on
/// `NetworkFailure`, the same one-emission shape
/// `IngredientRepository.fetchUnitCatalog()` uses, not the two-emission
/// stream [RecipeList] uses. See `RecipeRepository.fetchDetail`'s own doc
/// comment for why a single recipe differs from the whole list.

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
  ///
  /// Stays a plain `Future` (D74): network-first with a cache fallback on
  /// `NetworkFailure`, the same one-emission shape
  /// `IngredientRepository.fetchUnitCatalog()` uses, not the two-emission
  /// stream [RecipeList] uses. See `RecipeRepository.fetchDetail`'s own doc
  /// comment for why a single recipe differs from the whole list.

  RecipeDetailProvider call(String recipeId, {String locale = 'sr'}) =>
      RecipeDetailProvider._(argument: (recipeId, locale: locale), from: this);

  @override
  String toString() => r'recipeDetailProvider';
}
