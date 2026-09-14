// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_reviewer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The translation review screen's state and the save that ends it (Phase 3,
/// part 3).
///
/// Keyed on `(recipeId, locale)`, on [RecipeEditor]'s precedent: loads once
/// through the repository rather than watching `recipeDetailProvider`, for
/// the same reason `RecipeEditor.build`'s own comment gives -- `save()`
/// invalidates that provider, and a notifier watching it would answer its
/// own save by discarding whatever the reviewer had just typed.
///
/// Unlike [RecipeEditor], this notifier does NOT inherit D81's deferred
/// `RecipeEditor` caveat (the editor's own hardcoded `'sr'`, fixed
/// separately this part): [locale] is known before the fetch happens,
/// because a review is by definition reading in one locale. The two
/// notifiers look alike enough that this is worth saying rather than
/// leaving a reader to assume the same caveat applies here.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen, the
/// same call `RecipeEditor` makes.

@ProviderFor(TranslationReviewer)
final translationReviewerProvider = TranslationReviewerFamily._();

/// The translation review screen's state and the save that ends it (Phase 3,
/// part 3).
///
/// Keyed on `(recipeId, locale)`, on [RecipeEditor]'s precedent: loads once
/// through the repository rather than watching `recipeDetailProvider`, for
/// the same reason `RecipeEditor.build`'s own comment gives -- `save()`
/// invalidates that provider, and a notifier watching it would answer its
/// own save by discarding whatever the reviewer had just typed.
///
/// Unlike [RecipeEditor], this notifier does NOT inherit D81's deferred
/// `RecipeEditor` caveat (the editor's own hardcoded `'sr'`, fixed
/// separately this part): [locale] is known before the fetch happens,
/// because a review is by definition reading in one locale. The two
/// notifiers look alike enough that this is worth saying rather than
/// leaving a reader to assume the same caveat applies here.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen, the
/// same call `RecipeEditor` makes.
final class TranslationReviewerProvider
    extends
        $AsyncNotifierProvider<TranslationReviewer, TranslationReviewDraft> {
  /// The translation review screen's state and the save that ends it (Phase 3,
  /// part 3).
  ///
  /// Keyed on `(recipeId, locale)`, on [RecipeEditor]'s precedent: loads once
  /// through the repository rather than watching `recipeDetailProvider`, for
  /// the same reason `RecipeEditor.build`'s own comment gives -- `save()`
  /// invalidates that provider, and a notifier watching it would answer its
  /// own save by discarding whatever the reviewer had just typed.
  ///
  /// Unlike [RecipeEditor], this notifier does NOT inherit D81's deferred
  /// `RecipeEditor` caveat (the editor's own hardcoded `'sr'`, fixed
  /// separately this part): [locale] is known before the fetch happens,
  /// because a review is by definition reading in one locale. The two
  /// notifiers look alike enough that this is worth saying rather than
  /// leaving a reader to assume the same caveat applies here.
  ///
  /// Not `keepAlive`: an abandoned review should not outlive its screen, the
  /// same call `RecipeEditor` makes.
  TranslationReviewerProvider._({
    required TranslationReviewerFamily super.from,
    required (String, {String locale}) super.argument,
  }) : super(
         retry: null,
         name: r'translationReviewerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$translationReviewerHash();

  @override
  String toString() {
    return r'translationReviewerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TranslationReviewer create() => TranslationReviewer();

  @override
  bool operator ==(Object other) {
    return other is TranslationReviewerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$translationReviewerHash() =>
    r'b57249c2af6a093f4748d98372393d5568b8c6f5';

/// The translation review screen's state and the save that ends it (Phase 3,
/// part 3).
///
/// Keyed on `(recipeId, locale)`, on [RecipeEditor]'s precedent: loads once
/// through the repository rather than watching `recipeDetailProvider`, for
/// the same reason `RecipeEditor.build`'s own comment gives -- `save()`
/// invalidates that provider, and a notifier watching it would answer its
/// own save by discarding whatever the reviewer had just typed.
///
/// Unlike [RecipeEditor], this notifier does NOT inherit D81's deferred
/// `RecipeEditor` caveat (the editor's own hardcoded `'sr'`, fixed
/// separately this part): [locale] is known before the fetch happens,
/// because a review is by definition reading in one locale. The two
/// notifiers look alike enough that this is worth saying rather than
/// leaving a reader to assume the same caveat applies here.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen, the
/// same call `RecipeEditor` makes.

final class TranslationReviewerFamily extends $Family
    with
        $ClassFamilyOverride<
          TranslationReviewer,
          AsyncValue<TranslationReviewDraft>,
          TranslationReviewDraft,
          FutureOr<TranslationReviewDraft>,
          (String, {String locale})
        > {
  TranslationReviewerFamily._()
    : super(
        retry: null,
        name: r'translationReviewerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The translation review screen's state and the save that ends it (Phase 3,
  /// part 3).
  ///
  /// Keyed on `(recipeId, locale)`, on [RecipeEditor]'s precedent: loads once
  /// through the repository rather than watching `recipeDetailProvider`, for
  /// the same reason `RecipeEditor.build`'s own comment gives -- `save()`
  /// invalidates that provider, and a notifier watching it would answer its
  /// own save by discarding whatever the reviewer had just typed.
  ///
  /// Unlike [RecipeEditor], this notifier does NOT inherit D81's deferred
  /// `RecipeEditor` caveat (the editor's own hardcoded `'sr'`, fixed
  /// separately this part): [locale] is known before the fetch happens,
  /// because a review is by definition reading in one locale. The two
  /// notifiers look alike enough that this is worth saying rather than
  /// leaving a reader to assume the same caveat applies here.
  ///
  /// Not `keepAlive`: an abandoned review should not outlive its screen, the
  /// same call `RecipeEditor` makes.

  TranslationReviewerProvider call(String recipeId, {required String locale}) =>
      TranslationReviewerProvider._(
        argument: (recipeId, locale: locale),
        from: this,
      );

  @override
  String toString() => r'translationReviewerProvider';
}

/// The translation review screen's state and the save that ends it (Phase 3,
/// part 3).
///
/// Keyed on `(recipeId, locale)`, on [RecipeEditor]'s precedent: loads once
/// through the repository rather than watching `recipeDetailProvider`, for
/// the same reason `RecipeEditor.build`'s own comment gives -- `save()`
/// invalidates that provider, and a notifier watching it would answer its
/// own save by discarding whatever the reviewer had just typed.
///
/// Unlike [RecipeEditor], this notifier does NOT inherit D81's deferred
/// `RecipeEditor` caveat (the editor's own hardcoded `'sr'`, fixed
/// separately this part): [locale] is known before the fetch happens,
/// because a review is by definition reading in one locale. The two
/// notifiers look alike enough that this is worth saying rather than
/// leaving a reader to assume the same caveat applies here.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen, the
/// same call `RecipeEditor` makes.

abstract class _$TranslationReviewer
    extends $AsyncNotifier<TranslationReviewDraft> {
  late final _$args = ref.$arg as (String, {String locale});
  String get recipeId => _$args.$1;
  String get locale => _$args.locale;

  FutureOr<TranslationReviewDraft> build(
    String recipeId, {
    required String locale,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<TranslationReviewDraft>, TranslationReviewDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<TranslationReviewDraft>,
                TranslationReviewDraft
              >,
              AsyncValue<TranslationReviewDraft>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, locale: _$args.locale),
    );
  }
}
