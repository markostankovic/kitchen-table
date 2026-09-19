// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_writer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mealPlanWriteSink)
final mealPlanWriteSinkProvider = MealPlanWriteSinkProvider._();

final class MealPlanWriteSinkProvider
    extends
        $FunctionalProvider<
          MealPlanRepository,
          MealPlanRepository,
          MealPlanRepository
        >
    with $Provider<MealPlanRepository> {
  MealPlanWriteSinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealPlanWriteSinkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealPlanWriteSinkHash();

  @$internal
  @override
  $ProviderElement<MealPlanRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MealPlanRepository create(Ref ref) {
    return mealPlanWriteSink(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MealPlanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MealPlanRepository>(value),
    );
  }
}

String _$mealPlanWriteSinkHash() => r'04ea923c920df562f1d47faa51b5b979a2ae89f9';

/// Writes one meal plan entry from a screen that holds no visible week.
///
/// `keepAlive`, and never watched by its caller -- see the file header for
/// why an `autoDispose` notifier is the wrong shape here.

@ProviderFor(MealPlanWriter)
final mealPlanWriterProvider = MealPlanWriterProvider._();

/// Writes one meal plan entry from a screen that holds no visible week.
///
/// `keepAlive`, and never watched by its caller -- see the file header for
/// why an `autoDispose` notifier is the wrong shape here.
final class MealPlanWriterProvider
    extends $NotifierProvider<MealPlanWriter, void> {
  /// Writes one meal plan entry from a screen that holds no visible week.
  ///
  /// `keepAlive`, and never watched by its caller -- see the file header for
  /// why an `autoDispose` notifier is the wrong shape here.
  MealPlanWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealPlanWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealPlanWriterHash();

  @$internal
  @override
  MealPlanWriter create() => MealPlanWriter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$mealPlanWriterHash() => r'a95f0624ff468d21772d539f4479a01b34f68fe1';

/// Writes one meal plan entry from a screen that holds no visible week.
///
/// `keepAlive`, and never watched by its caller -- see the file header for
/// why an `autoDispose` notifier is the wrong shape here.

abstract class _$MealPlanWriter extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
