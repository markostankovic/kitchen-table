## D34 — `create_ingredient` and `link_ingredient_alias` are RPCs, not policies

**Decided.** The narrow write path D32 promised, delivered in Phase 1c.
`create_ingredient(ingredient_name, loc, unit_family) returns uuid` and
`link_ingredient_alias(ingredient, alias_name, loc) returns boolean`, both
`security definer`, both granted to `authenticated` and `service_role` with
`anon` explicitly revoked. Rows they write get `is_verified = false` and
`key = null` — keys belong to the seed (D27).

**Why a function.** `create_ingredient` returns the id of the ingredient that
already answers to the string rather than making a second one, and that guard is
the entire reason this is not an INSERT policy. The guard mirrors
`ingredient_names_unique` exactly: narrower and it raises a constraint violation
instead of returning a row, wider and it refuses creations that would have been
fine.

**Why `boolean`, not `void`.** A string can already be a live global alias for a
different ingredient, and hijacking it would silently change what that word
means for every household. So `link_ingredient_alias` refuses — but it must not
raise, or one household's unusual wording would fail somebody's recipe save. It
returns false, the line still saves, and only the global write-back is declined.

**Known gap, deliberate.** Neither looks across locales. Widening them would
assert that a string naming an ingredient in one language names the same one in
the other, which is false often enough to matter — Serbian *pita* is a pie,
English *pita* is bread. Cross-locale duplicates are what `merge_ingredients` is
for, and `docs/INGREDIENTS.md` is explicit that merging is routine. The SQL test
asserts the gap, so closing it later is a visible change.

**Rejected.** An INSERT policy on `ingredient_names` — see D32, which rejected
the same thing a phase earlier for the same reason.
