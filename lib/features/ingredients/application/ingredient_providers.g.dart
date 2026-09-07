// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ingredientRepository)
final ingredientRepositoryProvider = IngredientRepositoryProvider._();

final class IngredientRepositoryProvider
    extends
        $FunctionalProvider<
          IngredientRepository,
          IngredientRepository,
          IngredientRepository
        >
    with $Provider<IngredientRepository> {
  IngredientRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ingredientRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ingredientRepositoryHash();

  @$internal
  @override
  $ProviderElement<IngredientRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IngredientRepository create(Ref ref) {
    return ingredientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IngredientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IngredientRepository>(value),
    );
  }
}

String _$ingredientRepositoryHash() =>
    r'621c8496f1803ee2ebade409cfa77ca02fe57a0e';

/// The unit lexicon, fetched once.
///
/// `keepAlive` is justified: it is roughly 120 immutable rows that only a
/// migration ever changes, and it is read on every ingredient line the user
/// touches. Re-fetching it whenever the last listener drops would mean a round
/// trip every time the line editor is reopened, for data that cannot have
/// changed.

@ProviderFor(unitCatalog)
final unitCatalogProvider = UnitCatalogProvider._();

/// The unit lexicon, fetched once.
///
/// `keepAlive` is justified: it is roughly 120 immutable rows that only a
/// migration ever changes, and it is read on every ingredient line the user
/// touches. Re-fetching it whenever the last listener drops would mean a round
/// trip every time the line editor is reopened, for data that cannot have
/// changed.

final class UnitCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<UnitCatalog>,
          UnitCatalog,
          FutureOr<UnitCatalog>
        >
    with $FutureModifier<UnitCatalog>, $FutureProvider<UnitCatalog> {
  /// The unit lexicon, fetched once.
  ///
  /// `keepAlive` is justified: it is roughly 120 immutable rows that only a
  /// migration ever changes, and it is read on every ingredient line the user
  /// touches. Re-fetching it whenever the last listener drops would mean a round
  /// trip every time the line editor is reopened, for data that cannot have
  /// changed.
  UnitCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unitCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unitCatalogHash();

  @$internal
  @override
  $FutureProviderElement<UnitCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UnitCatalog> create(Ref ref) {
    return unitCatalog(ref);
  }
}

String _$unitCatalogHash() => r'4b3b45a442dc2d68404311fd2db53916b1e70f2f';

/// Tier 1, ready to use.
///
/// The parser itself is pure and takes its lexicon by injection; this is the
/// one place the two are put together, so no screen has to know that parsing
/// depends on a fetch at all.

@ProviderFor(ingredientLineParser)
final ingredientLineParserProvider = IngredientLineParserProvider._();

/// Tier 1, ready to use.
///
/// The parser itself is pure and takes its lexicon by injection; this is the
/// one place the two are put together, so no screen has to know that parsing
/// depends on a fetch at all.

final class IngredientLineParserProvider
    extends
        $FunctionalProvider<
          AsyncValue<IngredientLineParser>,
          IngredientLineParser,
          FutureOr<IngredientLineParser>
        >
    with
        $FutureModifier<IngredientLineParser>,
        $FutureProvider<IngredientLineParser> {
  /// Tier 1, ready to use.
  ///
  /// The parser itself is pure and takes its lexicon by injection; this is the
  /// one place the two are put together, so no screen has to know that parsing
  /// depends on a fetch at all.
  IngredientLineParserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ingredientLineParserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ingredientLineParserHash();

  @$internal
  @override
  $FutureProviderElement<IngredientLineParser> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IngredientLineParser> create(Ref ref) {
    return ingredientLineParser(ref);
  }
}

String _$ingredientLineParserHash() =>
    r'9b146a54ef4b79ecc382cc99322bedb72c826044';

/// Tiers 2 and 3, for autocomplete.
///
/// Not `keepAlive`: one entry per query string, and the family would otherwise
/// grow without bound as somebody types. Callers debounce.

@ProviderFor(ingredientSearch)
final ingredientSearchProvider = IngredientSearchFamily._();

/// Tiers 2 and 3, for autocomplete.
///
/// Not `keepAlive`: one entry per query string, and the family would otherwise
/// grow without bound as somebody types. Callers debounce.

final class IngredientSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<IngredientMatch>>,
          List<IngredientMatch>,
          FutureOr<List<IngredientMatch>>
        >
    with
        $FutureModifier<List<IngredientMatch>>,
        $FutureProvider<List<IngredientMatch>> {
  /// Tiers 2 and 3, for autocomplete.
  ///
  /// Not `keepAlive`: one entry per query string, and the family would otherwise
  /// grow without bound as somebody types. Callers debounce.
  IngredientSearchProvider._({
    required IngredientSearchFamily super.from,
    required (String, {String locale}) super.argument,
  }) : super(
         retry: null,
         name: r'ingredientSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ingredientSearchHash();

  @override
  String toString() {
    return r'ingredientSearchProvider'
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
    return ingredientSearch(ref, argument.$1, locale: argument.locale);
  }

  @override
  bool operator ==(Object other) {
    return other is IngredientSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ingredientSearchHash() => r'00191acf4311d24d1f29da48d54efbde7c846a21';

/// Tiers 2 and 3, for autocomplete.
///
/// Not `keepAlive`: one entry per query string, and the family would otherwise
/// grow without bound as somebody types. Callers debounce.

final class IngredientSearchFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<IngredientMatch>>,
          (String, {String locale})
        > {
  IngredientSearchFamily._()
    : super(
        retry: null,
        name: r'ingredientSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tiers 2 and 3, for autocomplete.
  ///
  /// Not `keepAlive`: one entry per query string, and the family would otherwise
  /// grow without bound as somebody types. Callers debounce.

  IngredientSearchProvider call(String query, {String locale = 'sr'}) =>
      IngredientSearchProvider._(argument: (query, locale: locale), from: this);

  @override
  String toString() => r'ingredientSearchProvider';
}
