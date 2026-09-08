// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_editor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The recipe editor's state and the save that ends it.
///
/// The shape `docs/ARCHITECTURE.md` names for editing: an in-memory notifier,
/// no persistence (D12 rejects offline writes). Every mutator delegates to a
/// pure method on [RecipeDraft] and assigns the result, so the logic worth
/// testing lives in `domain/` and this class stays thin enough to be worth not
/// mocking.
///
/// Keyed on the recipe id, or null for one that does not exist yet. Not
/// `keepAlive`: an abandoned editor should not outlive its screen.

@ProviderFor(RecipeEditor)
final recipeEditorProvider = RecipeEditorFamily._();

/// The recipe editor's state and the save that ends it.
///
/// The shape `docs/ARCHITECTURE.md` names for editing: an in-memory notifier,
/// no persistence (D12 rejects offline writes). Every mutator delegates to a
/// pure method on [RecipeDraft] and assigns the result, so the logic worth
/// testing lives in `domain/` and this class stays thin enough to be worth not
/// mocking.
///
/// Keyed on the recipe id, or null for one that does not exist yet. Not
/// `keepAlive`: an abandoned editor should not outlive its screen.
final class RecipeEditorProvider
    extends $AsyncNotifierProvider<RecipeEditor, RecipeDraft> {
  /// The recipe editor's state and the save that ends it.
  ///
  /// The shape `docs/ARCHITECTURE.md` names for editing: an in-memory notifier,
  /// no persistence (D12 rejects offline writes). Every mutator delegates to a
  /// pure method on [RecipeDraft] and assigns the result, so the logic worth
  /// testing lives in `domain/` and this class stays thin enough to be worth not
  /// mocking.
  ///
  /// Keyed on the recipe id, or null for one that does not exist yet. Not
  /// `keepAlive`: an abandoned editor should not outlive its screen.
  RecipeEditorProvider._({
    required RecipeEditorFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'recipeEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recipeEditorHash();

  @override
  String toString() {
    return r'recipeEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecipeEditor create() => RecipeEditor();

  @override
  bool operator ==(Object other) {
    return other is RecipeEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recipeEditorHash() => r'9a215943ad3f6d9ba74c73496b9d9606705426a7';

/// The recipe editor's state and the save that ends it.
///
/// The shape `docs/ARCHITECTURE.md` names for editing: an in-memory notifier,
/// no persistence (D12 rejects offline writes). Every mutator delegates to a
/// pure method on [RecipeDraft] and assigns the result, so the logic worth
/// testing lives in `domain/` and this class stays thin enough to be worth not
/// mocking.
///
/// Keyed on the recipe id, or null for one that does not exist yet. Not
/// `keepAlive`: an abandoned editor should not outlive its screen.

final class RecipeEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          RecipeEditor,
          AsyncValue<RecipeDraft>,
          RecipeDraft,
          FutureOr<RecipeDraft>,
          String?
        > {
  RecipeEditorFamily._()
    : super(
        retry: null,
        name: r'recipeEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The recipe editor's state and the save that ends it.
  ///
  /// The shape `docs/ARCHITECTURE.md` names for editing: an in-memory notifier,
  /// no persistence (D12 rejects offline writes). Every mutator delegates to a
  /// pure method on [RecipeDraft] and assigns the result, so the logic worth
  /// testing lives in `domain/` and this class stays thin enough to be worth not
  /// mocking.
  ///
  /// Keyed on the recipe id, or null for one that does not exist yet. Not
  /// `keepAlive`: an abandoned editor should not outlive its screen.

  RecipeEditorProvider call(String? recipeId) =>
      RecipeEditorProvider._(argument: recipeId, from: this);

  @override
  String toString() => r'recipeEditorProvider';
}

/// The recipe editor's state and the save that ends it.
///
/// The shape `docs/ARCHITECTURE.md` names for editing: an in-memory notifier,
/// no persistence (D12 rejects offline writes). Every mutator delegates to a
/// pure method on [RecipeDraft] and assigns the result, so the logic worth
/// testing lives in `domain/` and this class stays thin enough to be worth not
/// mocking.
///
/// Keyed on the recipe id, or null for one that does not exist yet. Not
/// `keepAlive`: an abandoned editor should not outlive its screen.

abstract class _$RecipeEditor extends $AsyncNotifier<RecipeDraft> {
  late final _$args = ref.$arg as String?;
  String? get recipeId => _$args;

  FutureOr<RecipeDraft> build(String? recipeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RecipeDraft>, RecipeDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RecipeDraft>, RecipeDraft>,
              AsyncValue<RecipeDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
