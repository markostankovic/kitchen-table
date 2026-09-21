# D107 — A tag's identity in two languages
**Status:** active
**Touches:** supabase/migrations/20260921100000_recipe_tag_names.sql, lib/features/recipes/domain/recipe_tag.dart, lib/features/recipes/data/recipe_repository.dart

**Decided.** `recipe_tag_names` keys on `tag_key`, the normalized
**original** spelling — exactly `RecipeTag.key`, which is already what
`RecipeRepository._filtered` compares against. One row is one spelling of
one tag in one locale (`tag_key, locale, household_id` — total unique
index, `ingredient_names_unique`'s own shape, `household_id` coalesced so a
nullable column still participates). Resolution for reader locale `loc`
looks up `(tag_key, loc)`; on a hit it wins, on a miss the label falls back
to `RecipeTag.label` (the alphabetically-first original spelling
`vocabularyOf` already picks). `RecipeTag.relabelled` is a resolution step
beside `vocabularyOf`, not a second signature on it — `key` never changes,
only `label`, so a translated chip still filters exactly like the as-typed
one did.

**Why.** `recipes.tags` is `text[]` with no id per tag, so there is no
surrogate key a translation could hang off — the normalized string already
has to be the identity, the same fact that made `ingredient_names` key on
`normalized_name` rather than `ingredient_id` for its alias rows. Keying on
the *original* spelling rather than some canonical form means a reader
never needs to know which locale a tag was first typed in for filtering to
keep working: the key a chip carries is the same key `_filtered` already
receives from a tap, translated label or not.

**Rejected.** A closed, ARB-backed tag vocabulary — already rejected
upstream in the roadmap, before this slice; tags stay free text. Giving
each tag a real id (a `recipe_tags` table `recipes.tags` referenced by
foreign key) — would have meant migrating the array column itself, a much
larger change for no reader-visible benefit this slice needs. `recipe_
translations`' shape (one row per recipe, columns per field) — the nearer-
looking precedent, but wrong: this is vocabulary translation shared across
a household's recipes, not prose translation of one recipe's own fields.

**Consequences.** A tag's translation is household-scoped, not global —
two households can each supply their own pair for the same spelling (or
none), and a `curated`/global row can still exist for anything worth
shipping pre-translated. Part 1b's `translate-tags` Edge Function writes
into the same table this migration already grants it RLS for; no second
migration is needed to open that door.
