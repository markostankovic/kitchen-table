/// The disk cache every recipe photo goes through.
///
/// Keyed by Storage **object path** (`Recipe.imagePath`), never by the signed
/// URL: a URL is re-signed every hour (D48), and a cache keyed by it would
/// miss on every re-sign and on every launch. The path is stable for as long
/// as the photo is.
///
/// Nothing here evicts by hand, and nothing needs to. `uploadImage` always
/// writes a fresh `{household}/{microsecondsSinceEpoch}.{ext}` path and never
/// upserts, so a replaced photo is a new key and the old entry simply ages
/// out. That is also why a long stale period is safe: a path is never reused
/// for different bytes.
///
/// A named instance rather than `DefaultCacheManager`, so recipe photos have
/// their own budget and tests can override this provider with a fake.
/// `core/` rather than the recipes feature, because `recipe_card.dart` (core)
/// renders photos for both the list and the meal plan's picker sheet.
library;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_image_cache.g.dart';

/// `keepAlive`: one cache for the life of the app, like `network_status
/// .dart`'s counter -- a fresh instance per screen would reopen its database.
@Riverpod(keepAlive: true)
BaseCacheManager recipeImageCacheManager(Ref ref) => CacheManager(
  Config(
    'recipeImages',
    stalePeriod: const Duration(days: 60),
    maxNrOfCacheObjects: 500,
  ),
);
