// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ingredientCatalog)
final ingredientCatalogProvider = IngredientCatalogProvider._();

final class IngredientCatalogProvider
    extends
        $FunctionalProvider<
          IngredientRepository,
          IngredientRepository,
          IngredientRepository
        >
    with $Provider<IngredientRepository> {
  IngredientCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ingredientCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ingredientCatalogHash();

  @$internal
  @override
  $ProviderElement<IngredientRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IngredientRepository create(Ref ref) {
    return ingredientCatalog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IngredientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IngredientRepository>(value),
    );
  }
}

String _$ingredientCatalogHash() => r'60c5c8c0bb9f97b67253e252dac6f7015a34f263';

/// The unit lexicon, fetched once per session.
///
/// `keepAlive` because it is roughly 120 immutable rows that only a migration
/// changes, and every ingredient line in the app parses against it.

@ProviderFor(unitCatalog)
final unitCatalogProvider = UnitCatalogProvider._();

/// The unit lexicon, fetched once per session.
///
/// `keepAlive` because it is roughly 120 immutable rows that only a migration
/// changes, and every ingredient line in the app parses against it.

final class UnitCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<UnitCatalog>,
          UnitCatalog,
          FutureOr<UnitCatalog>
        >
    with $FutureModifier<UnitCatalog>, $FutureProvider<UnitCatalog> {
  /// The unit lexicon, fetched once per session.
  ///
  /// `keepAlive` because it is roughly 120 immutable rows that only a migration
  /// changes, and every ingredient line in the app parses against it.
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

String _$unitCatalogHash() => r'93528af2a4f95c7661c09b26f033ddbad89884ff';

/// Tier 1, ready to use: the pure parser with its lexicon already injected, so
/// no screen has to know that parsing depends on a fetch (D31).

@ProviderFor(lineParser)
final lineParserProvider = LineParserProvider._();

/// Tier 1, ready to use: the pure parser with its lexicon already injected, so
/// no screen has to know that parsing depends on a fetch (D31).

final class LineParserProvider
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
  LineParserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lineParserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lineParserHash();

  @$internal
  @override
  $FutureProviderElement<IngredientLineParser> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IngredientLineParser> create(Ref ref) {
    return lineParser(ref);
  }
}

String _$lineParserHash() => r'1926aabb32aa53241e48b52f7aa6600acf40cbb7';

/// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.
///
/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types.

@ProviderFor(ingredientMatches)
final ingredientMatchesProvider = IngredientMatchesFamily._();

/// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.
///
/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types.

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
  ///
  /// Not `keepAlive`: one entry per query string, and the family would grow
  /// without bound as somebody types.
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

String _$ingredientMatchesHash() => r'71e6a7fdb11eace40af55ae107db735ca012e11e';

/// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.
///
/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types.

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
  ///
  /// Not `keepAlive`: one entry per query string, and the family would grow
  /// without bound as somebody types.

  IngredientMatchesProvider call(String query, {String locale = 'sr'}) =>
      IngredientMatchesProvider._(
        argument: (query, locale: locale),
        from: this,
      );

  @override
  String toString() => r'ingredientMatchesProvider';
}
