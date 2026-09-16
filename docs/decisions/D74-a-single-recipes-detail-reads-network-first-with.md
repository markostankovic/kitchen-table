## D74 — A single recipe's detail reads network-first with a cache fallback; the whole list reads cache-then-network

**Decided.** `RecipeRepository.fetchDetail` tries the network and falls
back to the cache only on a `NetworkFailure` — one emission, the same shape
`IngredientRepository.fetchUnitCatalog()` uses (D70). `RecipeRepository
.watchList` (the whole household's recipes) is a two-emission stream, cache
then network — the same shape `ShoppingListRepository.watchLatest` uses
(D67). The two reads of the same underlying cache disagree on purpose.

**Why.** D67's argument for cache-then-network is that a household's own
data "changes on someone else's say-so" and is worth showing stale rather
than not at all while a fresh answer is fetched in the background — true of
the whole list (another device may have added a recipe moments ago) in
exactly the way it is true of the shopping list. D70's argument for
network-first is that showing a stale answer before a fresh one buys
nothing when there is nothing to gain from the staleness. A single
recipe's detail sits closer to D70's case than D67's: it is fetched
on-demand exactly when the cook opens it, an edit to it while they are
mid-read is rare, and Phase 2's actual requirement — readable with no
network at all — is fully met by a fallback, not by an extra emission
nobody is likely to see update.

Network-first also keeps `recipeDetailProvider`'s public shape a plain
`Future<RecipeDetail>`, unchanged since before this part: every existing
override in `recipe_screens_test.dart` (`recipeDetailProvider('r1')
.overrideWith((Ref ref) async => detail)`) keeps working verbatim.
`recipeListProvider` becoming a `StreamNotifier` family did need a stub
rewritten (`_StubRecipeList`, on `shopping_list_screen_test.dart`'s
`_StubList` precedent) — a real, contained cost this decision avoids paying
twice.

**Rejected.**
- A two-emission stream for `fetchDetail` too, for symmetry with
  `watchList` — pays for a second emission and a provider-shape change with
  no case in the app that benefits from seeing a stale detail before a
  fresh one.
- Network-first for `watchList` as well — the whole list is exactly the
  entity D67 already argued should show stale data rather than none, and
  reversing that for consistency with `fetchDetail` would undo D67's own
  reasoning for no reason specific to recipes.
