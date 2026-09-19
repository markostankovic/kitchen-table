# D101 — Local echo is for a write whose result the screen already knows; anything server-computed still invalidates
**Status:** active
**Touches:** lib/features/recipes/presentation/recipe_detail_screen.dart

**Decided.** `RecipeDetailScreen`'s favorite toggle and rating stars render
the value they just wrote immediately (`setState` on a locally-held pending
value), call `recipesRevisionProvider.notifier.bump()` so the list behind
them refreshes, and deliberately do **not** call
`ref.invalidate(recipeDetailProvider)`. On an `AppFailure` the pending value
reverts and a snackbar shows, exactly as `_confirmDelete`'s snackbar does.
This is the first mutation in the app that does not end in an invalidate.

**Why.** `recipeDetailProvider` is a plain `Future` provider, and its body is
`detail.when(loading: CircularProgressIndicator)` — invalidating after every
tap flips the whole screen to a spinner for a value the screen already knows
correctly, which is fine for a slow, rare action like Translate but jarring
for a one-tap star. The screen wrote the exact value being displayed; there
is nothing left for the server to compute that the UI needs to wait for.

**Rejected.** Invalidating like every other mutation (`_translate`,
`_confirmDelete`) — correct but produces a visible spinner flash over the
whole recipe for no informational gain, since the value shown before and
after the refetch is identical by construction. A dedicated
`StateNotifier`/cache-write path for just these two fields — more machinery
than two `bool`/`int?` fields on one `State` class warrant, and CLAUDE.md's
working style already discourages abstraction ahead of a second use case.

**Consequences.** The boundary going forward: **local echo** is for a write
where the screen supplies the entire new value and the server does no
further computation on it (a toggle, a rating, a soft-delete's own optimistic
half) — invalidate anyway if the server can reject with a *different* value
than the one requested. **Invalidate** stays the default whenever the server
computes something the client doesn't already know (a translation's prose,
a generated id, a trigger-touched `updated_at` the UI displays). A future
mutation should ask which side of that line it's on before copying either
pattern.
