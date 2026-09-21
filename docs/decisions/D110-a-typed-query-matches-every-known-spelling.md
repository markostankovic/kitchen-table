# D110 — A typed query matches every known spelling of a tag, by substring
**Status:** active
**Touches:** lib/features/recipes/domain/recipe_filter.dart, lib/features/recipes/data/recipe_repository.dart

**Decided.** The free-text `query` path now matches a recipe when its title
contains the normalized term (unchanged) OR any of its tags does, under
either its own spelling or any known translated spelling: for tag `t`,
`normalize(t).contains(term)`, or `term` is a substring of any entry in
`spellingsByKey[normalize(t)]`. Every locale's spelling is checked, not just
the reader's own. The spelling map (`tagKey -> {normalized spellings}`) is
resolved once per `watchList` call, inside `RecipeRepository`, from
`_local.readTagNames` — local cache only, never the network — and reused for
both the cached and post-sync emissions.

**Why.** Substring, not whole-token: the search box already behaves this way
for titles, and a live-filtering field that does nothing until a word is
finished reads as broken. Every locale, not just the reader's: a bilingual
household types in whichever language is at hand, and D107 already makes
every spelling resolvable regardless of which one a search should prefer.
Resolved inside the repository rather than passed through the provider
family: D102's family stays two primitives plus the query string — adding a
`Map` argument would mint a fresh provider entry per rebuild (Riverpod keys
non-primitive family args on identity). Local cache, not network: `query`
is a Dart-side filter over an already-synced list (D67); a query keystroke
issuing a network call would be a new kind of request the family was never
built for.

**Rejected.** Passing the spelling map through the provider family — breaks
D102's two-primitives rule. Matching only the reader's own locale — cheaper,
but defeats the point of a bilingual household's tag pairs (D107).
Whole-token matching for the query path, to mirror the chip's semantics —
rejected because it would make tag search behave differently from title
search in the same field, with no visible cue why.

**Consequences.** A cold `recipe_tag_names` cache (never fetched, or wiped
at sign-out) degrades silently to as-typed matching only — correct
behaviour, not a bug, but worth remembering when a translated-spelling
search doesn't find a recipe on a freshly signed-in device before
`fetchTagLabels` has run once.
