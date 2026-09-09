// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mealPlanRepository)
final mealPlanRepositoryProvider = MealPlanRepositoryProvider._();

final class MealPlanRepositoryProvider
    extends
        $FunctionalProvider<
          MealPlanRepository,
          MealPlanRepository,
          MealPlanRepository
        >
    with $Provider<MealPlanRepository> {
  MealPlanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealPlanRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealPlanRepositoryHash();

  @$internal
  @override
  $ProviderElement<MealPlanRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MealPlanRepository create(Ref ref) {
    return mealPlanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MealPlanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MealPlanRepository>(value),
    );
  }
}

String _$mealPlanRepositoryHash() =>
    r'1a9bd928dca104390b4f06a85d212ef6e4649576';

/// The one week currently on screen.
///
/// Not a family keyed on the week: there is exactly one visible week at a
/// time, the same way there is exactly one signed-in user, so a family would
/// have been modelling something that does not exist. That also makes this
/// provider a one-line override in a test -- a family keyed on
/// `PlanWeek.of(DateTime.now())` would be clock-dependent to stub.

@ProviderFor(VisibleWeek)
final visibleWeekProvider = VisibleWeekProvider._();

/// The one week currently on screen.
///
/// Not a family keyed on the week: there is exactly one visible week at a
/// time, the same way there is exactly one signed-in user, so a family would
/// have been modelling something that does not exist. That also makes this
/// provider a one-line override in a test -- a family keyed on
/// `PlanWeek.of(DateTime.now())` would be clock-dependent to stub.
final class VisibleWeekProvider
    extends $NotifierProvider<VisibleWeek, PlanWeek> {
  /// The one week currently on screen.
  ///
  /// Not a family keyed on the week: there is exactly one visible week at a
  /// time, the same way there is exactly one signed-in user, so a family would
  /// have been modelling something that does not exist. That also makes this
  /// provider a one-line override in a test -- a family keyed on
  /// `PlanWeek.of(DateTime.now())` would be clock-dependent to stub.
  VisibleWeekProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleWeekProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleWeekHash();

  @$internal
  @override
  VisibleWeek create() => VisibleWeek();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanWeek value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanWeek>(value),
    );
  }
}

String _$visibleWeekHash() => r'b3787f842dfddcdca5ce0e8cd6a271ec0114f03b';

/// The one week currently on screen.
///
/// Not a family keyed on the week: there is exactly one visible week at a
/// time, the same way there is exactly one signed-in user, so a family would
/// have been modelling something that does not exist. That also makes this
/// provider a one-line override in a test -- a family keyed on
/// `PlanWeek.of(DateTime.now())` would be clock-dependent to stub.

abstract class _$VisibleWeek extends $Notifier<PlanWeek> {
  PlanWeek build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlanWeek, PlanWeek>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlanWeek, PlanWeek>,
              PlanWeek,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The visible week's entries, and the writes that change them.
///
/// `build()` resolves the household id before it ever reaches
/// [mealPlanRepositoryProvider], and returns an empty week rather than
/// constructing a repository call when there is none -- a household-less
/// caller never touches `Supabase.instance.client` (the shell's tab loop
/// relies on exactly this to render the Plan tab under test).
///
/// There is no Save: every action here writes immediately (D53). A meal plan
/// is not one document being composed like a recipe draft -- each entry is
/// independent, and putting a recipe in Thursday lunch is complete on its
/// own. D12 already rules out an offline draft buying anything.

@ProviderFor(MealPlanEditor)
final mealPlanEditorProvider = MealPlanEditorProvider._();

/// The visible week's entries, and the writes that change them.
///
/// `build()` resolves the household id before it ever reaches
/// [mealPlanRepositoryProvider], and returns an empty week rather than
/// constructing a repository call when there is none -- a household-less
/// caller never touches `Supabase.instance.client` (the shell's tab loop
/// relies on exactly this to render the Plan tab under test).
///
/// There is no Save: every action here writes immediately (D53). A meal plan
/// is not one document being composed like a recipe draft -- each entry is
/// independent, and putting a recipe in Thursday lunch is complete on its
/// own. D12 already rules out an offline draft buying anything.
final class MealPlanEditorProvider
    extends $AsyncNotifierProvider<MealPlanEditor, MealPlanWeek> {
  /// The visible week's entries, and the writes that change them.
  ///
  /// `build()` resolves the household id before it ever reaches
  /// [mealPlanRepositoryProvider], and returns an empty week rather than
  /// constructing a repository call when there is none -- a household-less
  /// caller never touches `Supabase.instance.client` (the shell's tab loop
  /// relies on exactly this to render the Plan tab under test).
  ///
  /// There is no Save: every action here writes immediately (D53). A meal plan
  /// is not one document being composed like a recipe draft -- each entry is
  /// independent, and putting a recipe in Thursday lunch is complete on its
  /// own. D12 already rules out an offline draft buying anything.
  MealPlanEditorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealPlanEditorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealPlanEditorHash();

  @$internal
  @override
  MealPlanEditor create() => MealPlanEditor();
}

String _$mealPlanEditorHash() => r'a8ae1deb48eb305a5241546434349db70ccd1122';

/// The visible week's entries, and the writes that change them.
///
/// `build()` resolves the household id before it ever reaches
/// [mealPlanRepositoryProvider], and returns an empty week rather than
/// constructing a repository call when there is none -- a household-less
/// caller never touches `Supabase.instance.client` (the shell's tab loop
/// relies on exactly this to render the Plan tab under test).
///
/// There is no Save: every action here writes immediately (D53). A meal plan
/// is not one document being composed like a recipe draft -- each entry is
/// independent, and putting a recipe in Thursday lunch is complete on its
/// own. D12 already rules out an offline draft buying anything.

abstract class _$MealPlanEditor extends $AsyncNotifier<MealPlanWeek> {
  FutureOr<MealPlanWeek> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MealPlanWeek>, MealPlanWeek>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MealPlanWeek>, MealPlanWeek>,
              AsyncValue<MealPlanWeek>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
