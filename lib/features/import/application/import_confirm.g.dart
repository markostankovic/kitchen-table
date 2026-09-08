// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_confirm.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The confirm screen's state (D8).
///
/// Deliberately the same shape as `RecipeEditor`: an `AsyncNotifier` over a
/// `RecipeDraft`, with one thin delegate per pure mutator. That is what lets
/// the screen reuse `IngredientLineField` verbatim -- which is why D43 moved
/// that widget to `core/` in the first place.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen.

@ProviderFor(ImportConfirm)
final importConfirmProvider = ImportConfirmFamily._();

/// The confirm screen's state (D8).
///
/// Deliberately the same shape as `RecipeEditor`: an `AsyncNotifier` over a
/// `RecipeDraft`, with one thin delegate per pure mutator. That is what lets
/// the screen reuse `IngredientLineField` verbatim -- which is why D43 moved
/// that widget to `core/` in the first place.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen.
final class ImportConfirmProvider
    extends $AsyncNotifierProvider<ImportConfirm, ImportReview> {
  /// The confirm screen's state (D8).
  ///
  /// Deliberately the same shape as `RecipeEditor`: an `AsyncNotifier` over a
  /// `RecipeDraft`, with one thin delegate per pure mutator. That is what lets
  /// the screen reuse `IngredientLineField` verbatim -- which is why D43 moved
  /// that widget to `core/` in the first place.
  ///
  /// Not `keepAlive`: an abandoned review should not outlive its screen.
  ImportConfirmProvider._({
    required ImportConfirmFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'importConfirmProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$importConfirmHash();

  @override
  String toString() {
    return r'importConfirmProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ImportConfirm create() => ImportConfirm();

  @override
  bool operator ==(Object other) {
    return other is ImportConfirmProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$importConfirmHash() => r'd2aab617192175d369216a7abe73cff706655d63';

/// The confirm screen's state (D8).
///
/// Deliberately the same shape as `RecipeEditor`: an `AsyncNotifier` over a
/// `RecipeDraft`, with one thin delegate per pure mutator. That is what lets
/// the screen reuse `IngredientLineField` verbatim -- which is why D43 moved
/// that widget to `core/` in the first place.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen.

final class ImportConfirmFamily extends $Family
    with
        $ClassFamilyOverride<
          ImportConfirm,
          AsyncValue<ImportReview>,
          ImportReview,
          FutureOr<ImportReview>,
          String
        > {
  ImportConfirmFamily._()
    : super(
        retry: null,
        name: r'importConfirmProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The confirm screen's state (D8).
  ///
  /// Deliberately the same shape as `RecipeEditor`: an `AsyncNotifier` over a
  /// `RecipeDraft`, with one thin delegate per pure mutator. That is what lets
  /// the screen reuse `IngredientLineField` verbatim -- which is why D43 moved
  /// that widget to `core/` in the first place.
  ///
  /// Not `keepAlive`: an abandoned review should not outlive its screen.

  ImportConfirmProvider call(String jobId) =>
      ImportConfirmProvider._(argument: jobId, from: this);

  @override
  String toString() => r'importConfirmProvider';
}

/// The confirm screen's state (D8).
///
/// Deliberately the same shape as `RecipeEditor`: an `AsyncNotifier` over a
/// `RecipeDraft`, with one thin delegate per pure mutator. That is what lets
/// the screen reuse `IngredientLineField` verbatim -- which is why D43 moved
/// that widget to `core/` in the first place.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen.

abstract class _$ImportConfirm extends $AsyncNotifier<ImportReview> {
  late final _$args = ref.$arg as String;
  String get jobId => _$args;

  FutureOr<ImportReview> build(String jobId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ImportReview>, ImportReview>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ImportReview>, ImportReview>,
              AsyncValue<ImportReview>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
