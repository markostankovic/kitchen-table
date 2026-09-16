## D87 — `currentHouseholdIdProvider` has no offline path, and every household-scoped screen inherits that gap silently

**Decided.** Recorded, not fixed here. The Phase 3 part 3 emulator walk —
translate a recipe, review it, force-stop, disable the emulator's network,
relaunch cold — found that the Recipes tab did not render the cached recipe
it had every reason to have: `RecipeList.build()` (and `CurrentShoppingList
.build()`, and `MealPlanEditor`'s own build, by the same shape) all open with
`await ref.watch(currentHouseholdIdProvider.future)` before touching their
own cache at all. `currentHouseholdIdProvider` calls
`HouseholdRepository.fetchCurrent()` — a plain network read, no cache, no
client-side timeout. Offline, that call does not fail fast: on this walk it
took several minutes to finally throw `NetworkFailure`, and until it did,
every household-scoped screen sat on a spinner, however well its own cache
was populated underneath it.

**It was not the recipe cache.** Pulled directly off the device
(`/data/data/com.kitchentable.kitchen_table/files/kitchen_table_cache.sqlite`)
mid-walk: the `recipe_cache` row for the recipe translated and reviewed
earlier in the same walk was present, correctly keyed to the real household
id, and so was its `sync_watermarks` row. `RecipeRepository.watchList`'s own
cache-then-network shape (D67, widened D74) was never reached to prove or
disprove itself — the household gate in front of it never let it run.

**Why this was never caught before.** Every offline "Done when" from part 5
onward (D67, D74, D75) was verified by walking the emulator ALREADY signed
into an already-resolved household, generally within the same session that
had just been online — `currentHouseholdIdProvider`, `keepAlive`, had
already resolved and stayed resolved for the rest of that walk. This is the
first walk to force a COLD start with no network from the very first frame,
which is exactly the scenario a phone that lost signal overnight is in.

**Consequence.** Every offline "Done when" this project has claimed met
(D67, D74, D75, and Phase 2 part 6b's own) is truthful for a warm session --
reopening a screen, or relaunching with a household already resolved -- and
unverified for a genuinely cold, offline-from-first-frame one. That is a
narrower claim than "recipes/meal plans/shopping list are readable offline"
reads as, and this entry is what keeps the gap from being read as closed.

**Rejected.** Fixing it inside this part — this is a Phase 2 architectural
gap (household resolution was never on Phase 2's own offline list to begin
with: recipes, meal plans, the shopping list and the ingredient catalog were
D71/D72/D73/D75's whole scope, and `currentHouseholdIdProvider` predates all
of them, D33/D52). A real fix needs a decision this entry does not make for
whoever picks it up: cache the current household id itself (cheap, and it
rarely changes), or wrap the fetch in a bounded client-side timeout so a
black-holed connection fails in seconds rather than minutes, or both. Either
is a new decision, not a two-line patch inside a part about translation
review.
