# D131 — The recipe list signs photo URLs on its online emission only, and reads translated titles from the cached embed
**Status:** active
**Touches:** lib/features/recipes/data/recipe_repository.dart, lib/features/recipes/data/local_recipe_datasource.dart, lib/features/recipes/domain/recipe.dart, lib/features/recipes/domain/recipe_filter.dart, lib/core/recipes/widgets/recipe_card.dart

**Decided.**
1. **`watchList`'s fresh (online) emission goes through `_withImageUrls`**,
   so every photo is signed in one `createSignedUrls` round trip. The cached
   first emission stays unsigned and shows the monogram. `_withImageUrlsOrNot`
   catches any signing failure and returns the list unsigned, because a
   photo is never worth failing the list over.
2. **`Recipe` gains `titleByLocale`** (`Map<String, String>`, default empty),
   filled by `LocalRecipeDataSource.readAll` from the `recipe_translations`
   embed that the list's delta fetch already caches (D65, D78). It is not
   written back. `Recipe.displayTitle(locale)` is the translation or the
   original, the same rule as `RecipeDetail.displayTitle`.
3. **`RecipeCard` shows `displayTitle(l10n.localeName)`** for both the
   title and the monogram letter. The meal-plan recipe picker, which uses the
   same card, follows for free.
4. **`RecipeFilter` also matches every translated title**, so "stuffed"
   finds `Punjene paprike`.

**Why.**
- The list always showed monograms and original titles. The data was already
  on the phone: `image_path` and the translations embed both ride in the
  cached row. Only the read path dropped them.
- Signing only the online emission keeps D65's cache-first shape: the
  offline list renders at once, and the online one, which needs the network
  anyway, carries the photos.

**Rejected.**
- Persisting signed URLs in the cache. They expire (D48), so a cached one
  goes stale and fails.
- Carrying the full `List<RecipeTranslation>` on `Recipe`. The list only
  needs titles, and `RecipeDetail` already owns the full set.
- A thumbnail-cache package (rule 8).

**Consequences.**
- Signed URLs differ every time they are signed, so `Image.network` downloads
  each thumbnail again on every list refresh. This is acceptable at household
  scale. If it becomes noticeable, the fix is a longer TTL or keying the image
  cache on `imagePath`.
- Meal-plan entries still show `recipeTitle` from their own embed, in the
  original language (D53). The walk saw `Kajgana` under English. That fix is
  separate.
