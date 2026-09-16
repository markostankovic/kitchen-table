## D86 — The editor's display names follow the reader, closing D81's own named consequence

**Decided.** `RecipeEditor.build` now calls
`repository.fetchDetail(recipeId, locale: readingLocale)` with
`readingLocale` read from `appLocaleProvider` via `ref.read` (never
`ref.watch`), instead of relying on `fetchDetail`'s bare `'sr'` default.
`IngredientLineField`'s own `locale:` argument in the edit screen is left
exactly as it was — `draft.originalLocale` — untouched by this decision.

**Why this is D81's consequence, not a new problem.** D81's own title is
"the reader's own locale resolves a display name, everywhere" — a matched
ingredient's chip name is the app reporting which catalog entry it found,
not part of the recipe's own content, so it is the same kind of value
`RecipeDetailScreen` and `ShoppingListEditor.generate()` already corrected
to follow the reader in D81 itself. `RecipeEditor.build`'s own comment had
called this out by name rather than leaving it to be rediscovered, and this
decision is that comment's resolution.

**Why `ref.read`, not `ref.watch`.** `RecipeEditor.build`'s existing comment
already explains the shape this has to respect: watching a provider inside
`build()` re-runs the whole draft load whenever that provider's value
changes, and a language switch mid-edit re-running the load would discard
whatever the cook had already typed — the exact failure the comment warns
against for `recipeDetailProvider`. A locale read once, at the moment the
draft is opened, carries no such risk.

**Why `IngredientLineField`'s own locale is untouched.** That parameter is
a WRITE concern — the search locale for `ingredientMatchesProvider`, and the
locale a newly created alias is written in — not a display concern.
Pointing it at the reader would write a new alias in the reader's language
even while editing a recipe written in the other one, which is a worse bug
than the one being fixed. Display and write are different concerns in this
screen and stay separated.

**Consequence, left alone deliberately.** The ingredient PICKER's own
candidate list (via `ingredientMatchesProvider(_query, locale:
widget.locale)`) still renders in the recipe's own language while an
already-accepted line's chip now renders in the reader's — the two were
already different code paths before this decision, and unifying them is a
matching-behaviour question (does `search_ingredients`' `preferred_locale`
change which candidates are offered, not merely how they are labelled — it
does, as a ranking tie-break) that belongs with the screens-localization
part, not this one.

**Rejected.** Threading the reading locale into the editor's route instead
of reading `appLocaleProvider` directly — D81 named this as one option;
`appLocaleProvider` already exists precisely so a screen does not need a
second channel for "what language is the reader in" (D77), and a route
parameter would be exactly that second channel.
