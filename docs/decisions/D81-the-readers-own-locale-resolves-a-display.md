## D81 — The reader's own locale resolves a display name, everywhere, not `'sr'`

**Decided.** `RecipeDetailScreen` now reads `appLocaleProvider` and passes it
into `recipeDetailProvider`; `ShoppingListEditor.generate()` reads the same
provider and passes it into both `fetchLinesForRecipes` and
`ShoppingListRepository.save`'s `locale` argument, which is what
`shopping_lists.locale` actually stores.

**Why this needed a decision and not just a bug fix.** The bilingual catalog
(D1) has existed since Phase 1b and has only ever been asked for Serbian —
`RecipeRepository.fetchDetail`'s `locale` parameter defaulted to `'sr'` and
nothing in the app had ever passed anything else, and
`shopping_list_providers.dart` wrote the literal string `'sr'` into
`shopping_lists.locale` regardless of the household's setting. Neither was
ever a compile error or a failing test: both are a parameter with a default
value that happened to be right until Phase 3 part 1 made the app's language
switchable. D77 (part 1) put the reader's locale one provider away
(`appLocaleProvider`) precisely so this would be a one-line fix per call
site rather than a new mechanism.

**Consequence, left alone deliberately.** `RecipeEditor.build`'s
`fetchDetail(recipeId)` still defaults to `'sr'` — the editor loads the
recipe's own original text (`recipe.title`, never `displayTitle`), and it
cannot know which locale to ask for until the very fetch that would tell it
returns. The visible symptom — an ingredient chip rendering its Serbian name
while editing an English recipe — is named in `docs/ROADMAP.md` rather than
silently left for a future session to rediscover. Fixing it properly needs
either a second round trip or threading the reading locale into the editor
route, and neither is this part's problem to solve.

**Rejected.** Leaving `shopping_lists.locale` at `'sr'` until a later part —
the column exists precisely so a list generated in one language does not
render half-translated after a locale switch (migration 16's own comment),
and it had been recording a falsehood since the day it shipped.
