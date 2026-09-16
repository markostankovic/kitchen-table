## D35 — Photo upload moves to Phase 2; `recipes.image_path` ships now

**Decided.** Phase 1c builds no Storage bucket, no policies on
`storage.objects`, and no picker. The `image_path` column ships in the recipes
migration anyway, and is written by nothing and displayed by nothing.

**Why.** Photo upload is a genuinely separate slice — a bucket, RLS on
`storage.objects` scoped by household, a path convention, and a new third-party
package (rule 8) — and none of it is needed for the sentence that defines the
phase: type in a recipe you know by heart and have every line match or
deliberately create an ingredient. Shipping the column now means that slice is a
feature later rather than a migration against existing rows.

`docs/ROADMAP.md` listed photo upload under 1c until this was written down.
