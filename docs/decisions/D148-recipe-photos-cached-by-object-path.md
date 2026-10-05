# D148 — Recipe photos are cached on disk by Storage object path
**Status:** active
**Touches:** lib/core/images/recipe_image_cache.dart, lib/core/recipes/widgets/recipe_photo.dart, lib/core/recipes/widgets/recipe_card.dart, lib/features/recipes/presentation/recipe_detail_screen.dart, lib/features/recipes/presentation/recipe_edit_screen.dart, pubspec.yaml

**Decided.** Phase 8 part 2, 2026-10-05:
1. **Every recipe photo goes through `RecipePhoto`** (`core/recipes/widgets/`),
   built on `cached_network_image` with a named `flutter_cache_manager`
   instance (`recipeImageCacheManagerProvider`, `recipeImages`, 60-day
   stale period, 500 objects). The **cache key is `Recipe.imagePath`**, the
   object path, never the signed URL. Both packages were approved under
   rule 8; neither touches Supabase, so they live in `core/`.
2. **Replacement is the invalidation.** `uploadImage` always writes a new
   `{household}/{microsecondsSinceEpoch}.{ext}` path and never upserts, so a
   new photo is a new key. There is no eviction code.
3. **The no-URL state shows cached photos by path** (extends D131's display
   rule). With a path and no URL, the widget asks the disk cache for the
   path and shows the placeholder only on a miss. It never fetches a bare
   path. And when a URL **goes away for the same path** (a pull emits the
   cached, unsigned list first), it keeps the last URL it had. The provider
   is keyed by path, so that URL is a memory or disk hit even once expired.
4. **The thumbnail decodes at `2 × AppSizes.thumb × dpr` wide.** The detail
   well and the editor preview decode at full size (near screen width; the
   upload is capped at 1200px).

**Why.**
- A URL is re-signed every hour (D48). A cache keyed by it misses on every
  re-sign and every launch, which is the reload the cook saw.
- The 72dp tile is `BoxFit.cover`, and only the width is decoded, so the
  aspect ratio holds. At 1× a landscape photo decodes shorter than the tile
  and is upscaled, blurry. 2× covers up to 2:1 for about 0.5MB, against
  about 4MB at 1200px. This deliberately deviates from the roadmap's
  "thumb × dpr".
- #3's remembered URL comes from the device walk. Dropping to the disk
  lookup on the pull's unsigned emission flashed every thumbnail to its
  monogram for the length of the refresh.

**Rejected.**
- **`DefaultCacheManager`.** It shares its budget with everything, and tests
  could not override it.
- **Eviction on replace.** It isn't needed, because paths are never reused.
- **Fetching the bare path offline.** It isn't a URL, and the bucket is private.
- **Decoding at 1× thumb.** It is blurry on landscape photos.

**Consequences.** A row whose object was deleted out from under it may keep
showing its last cached copy. That is acceptable and rare. Right after a
save, the new path has never been cached and the first emission is unsigned,
so the well shows the placeholder (or the previous emission's photo) until
the signed detail arrives, about 8–15s on the emulator. Seeding the cache
with the uploaded bytes on save would close that gap. The detail's
status-bar style still keys off `imageUrl`: an offline cached photo is only
known after an async lookup, so that case keeps the theme's icons.
