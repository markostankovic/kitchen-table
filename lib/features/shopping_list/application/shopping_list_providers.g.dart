// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shoppingListRepository)
final shoppingListRepositoryProvider = ShoppingListRepositoryProvider._();

final class ShoppingListRepositoryProvider
    extends
        $FunctionalProvider<
          ShoppingListRepository,
          ShoppingListRepository,
          ShoppingListRepository
        >
    with $Provider<ShoppingListRepository> {
  ShoppingListRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingListRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingListRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShoppingListRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShoppingListRepository create(Ref ref) {
    return shoppingListRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListRepository>(value),
    );
  }
}

String _$shoppingListRepositoryHash() =>
    r'ad4bf7d438385fe5a5a03587a609edc99282e73a';

/// The date range the next list will cover.
///
/// Starts as the current week, which is the range a cook wants nine times out
/// of ten. Not a family, on `VisibleWeek`'s precedent (D54): there is exactly
/// one range being shopped for at a time, so a family would model something
/// that does not exist, and a non-family is a one-line override in a test.
///
/// Deliberately NOT derived from `visibleWeekProvider`. Paging the Plan tab to
/// look at next month should not silently change what the List tab is about to
/// generate -- the two tabs answer different questions, and a range that moves
/// under the cook because they glanced elsewhere is the kind of surprise a
/// snapshot document should not have.

@ProviderFor(ShoppingRange)
final shoppingRangeProvider = ShoppingRangeProvider._();

/// The date range the next list will cover.
///
/// Starts as the current week, which is the range a cook wants nine times out
/// of ten. Not a family, on `VisibleWeek`'s precedent (D54): there is exactly
/// one range being shopped for at a time, so a family would model something
/// that does not exist, and a non-family is a one-line override in a test.
///
/// Deliberately NOT derived from `visibleWeekProvider`. Paging the Plan tab to
/// look at next month should not silently change what the List tab is about to
/// generate -- the two tabs answer different questions, and a range that moves
/// under the cook because they glanced elsewhere is the kind of surprise a
/// snapshot document should not have.
final class ShoppingRangeProvider
    extends $NotifierProvider<ShoppingRange, ({DateTime from, DateTime to})> {
  /// The date range the next list will cover.
  ///
  /// Starts as the current week, which is the range a cook wants nine times out
  /// of ten. Not a family, on `VisibleWeek`'s precedent (D54): there is exactly
  /// one range being shopped for at a time, so a family would model something
  /// that does not exist, and a non-family is a one-line override in a test.
  ///
  /// Deliberately NOT derived from `visibleWeekProvider`. Paging the Plan tab to
  /// look at next month should not silently change what the List tab is about to
  /// generate -- the two tabs answer different questions, and a range that moves
  /// under the cook because they glanced elsewhere is the kind of surprise a
  /// snapshot document should not have.
  ShoppingRangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shoppingRangeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shoppingRangeHash();

  @$internal
  @override
  ShoppingRange create() => ShoppingRange();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({DateTime from, DateTime to}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({DateTime from, DateTime to})>(
        value,
      ),
    );
  }
}

String _$shoppingRangeHash() => r'934e054d48ca9cee9565f114617bc8cbf07f5288';

/// The date range the next list will cover.
///
/// Starts as the current week, which is the range a cook wants nine times out
/// of ten. Not a family, on `VisibleWeek`'s precedent (D54): there is exactly
/// one range being shopped for at a time, so a family would model something
/// that does not exist, and a non-family is a one-line override in a test.
///
/// Deliberately NOT derived from `visibleWeekProvider`. Paging the Plan tab to
/// look at next month should not silently change what the List tab is about to
/// generate -- the two tabs answer different questions, and a range that moves
/// under the cook because they glanced elsewhere is the kind of surprise a
/// snapshot document should not have.

abstract class _$ShoppingRange
    extends $Notifier<({DateTime from, DateTime to})> {
  ({DateTime from, DateTime to}) build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({DateTime from, DateTime to}),
              ({DateTime from, DateTime to})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({DateTime from, DateTime to}),
                ({DateTime from, DateTime to})
              >,
              ({DateTime from, DateTime to}),
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The household's current list, and the actions that change it.
///
/// `build()` returns null rather than constructing a repository call when
/// there is no household, so a household-less caller never touches
/// `Supabase.instance.client` -- the shell's tab loop relies on exactly this
/// to render the List tab under test.
///
/// Watches [mealPlanRevisionProvider] as well as its own: a list is a snapshot
/// of a plan, and the plan changing is the single most useful reason to tell
/// the cook their list is out of date.

@ProviderFor(CurrentShoppingList)
final currentShoppingListProvider = CurrentShoppingListProvider._();

/// The household's current list, and the actions that change it.
///
/// `build()` returns null rather than constructing a repository call when
/// there is no household, so a household-less caller never touches
/// `Supabase.instance.client` -- the shell's tab loop relies on exactly this
/// to render the List tab under test.
///
/// Watches [mealPlanRevisionProvider] as well as its own: a list is a snapshot
/// of a plan, and the plan changing is the single most useful reason to tell
/// the cook their list is out of date.
final class CurrentShoppingListProvider
    extends $AsyncNotifierProvider<CurrentShoppingList, ShoppingList?> {
  /// The household's current list, and the actions that change it.
  ///
  /// `build()` returns null rather than constructing a repository call when
  /// there is no household, so a household-less caller never touches
  /// `Supabase.instance.client` -- the shell's tab loop relies on exactly this
  /// to render the List tab under test.
  ///
  /// Watches [mealPlanRevisionProvider] as well as its own: a list is a snapshot
  /// of a plan, and the plan changing is the single most useful reason to tell
  /// the cook their list is out of date.
  CurrentShoppingListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentShoppingListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentShoppingListHash();

  @$internal
  @override
  CurrentShoppingList create() => CurrentShoppingList();
}

String _$currentShoppingListHash() =>
    r'62f6b78c290cddb9af95e6277dcf32509cf3987f';

/// The household's current list, and the actions that change it.
///
/// `build()` returns null rather than constructing a repository call when
/// there is no household, so a household-less caller never touches
/// `Supabase.instance.client` -- the shell's tab loop relies on exactly this
/// to render the List tab under test.
///
/// Watches [mealPlanRevisionProvider] as well as its own: a list is a snapshot
/// of a plan, and the plan changing is the single most useful reason to tell
/// the cook their list is out of date.

abstract class _$CurrentShoppingList extends $AsyncNotifier<ShoppingList?> {
  FutureOr<ShoppingList?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ShoppingList?>, ShoppingList?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ShoppingList?>, ShoppingList?>,
              AsyncValue<ShoppingList?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
