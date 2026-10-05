// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_image_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive`: one cache for the life of the app, like `network_status
/// .dart`'s counter -- a fresh instance per screen would reopen its database.

@ProviderFor(recipeImageCacheManager)
final recipeImageCacheManagerProvider = RecipeImageCacheManagerProvider._();

/// `keepAlive`: one cache for the life of the app, like `network_status
/// .dart`'s counter -- a fresh instance per screen would reopen its database.

final class RecipeImageCacheManagerProvider
    extends
        $FunctionalProvider<
          BaseCacheManager,
          BaseCacheManager,
          BaseCacheManager
        >
    with $Provider<BaseCacheManager> {
  /// `keepAlive`: one cache for the life of the app, like `network_status
  /// .dart`'s counter -- a fresh instance per screen would reopen its database.
  RecipeImageCacheManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeImageCacheManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeImageCacheManagerHash();

  @$internal
  @override
  $ProviderElement<BaseCacheManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BaseCacheManager create(Ref ref) {
    return recipeImageCacheManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BaseCacheManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BaseCacheManager>(value),
    );
  }
}

String _$recipeImageCacheManagerHash() =>
    r'3c81997c2642629ed07007471e878828922258c8';
