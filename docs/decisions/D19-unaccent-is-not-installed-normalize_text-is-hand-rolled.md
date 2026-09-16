## D19 — `unaccent` is not installed; `normalize_text` is hand-rolled

**Decided.** The `unaccent` extension is not created. `normalize_text()` is
built from `lower` / `replace` / `translate` / `regexp_replace` only, which
keeps it `IMMUTABLE`. See `supabase/migrations/20260904210716_init.sql`.

**Why.** D5 already rejected `unaccent` on correctness grounds (it maps đ→d,
splitting *đuveč* from someone typing *djuvec*). There is a second, harder
reason that is easy to miss and worth writing down: `unaccent()` is `STABLE`,
not `IMMUTABLE`, because its behaviour depends on a mutable dictionary. Any
function that calls it is therefore also non-`IMMUTABLE` — and a
non-`IMMUTABLE` function **cannot back a generated column at all**. That kills
`ingredient_names.normalized_name` and `recipes.title_normalized` outright, not
just their accuracy.

**Rejected.** `unaccent` in any form, including "just for the ASCII fallback".
`docs/DATA_MODEL.md` originally listed it as a helper inside `normalize_text`;
that is not implementable.
