## D7 — Match provenance on every recipe_ingredient row

**Decided.** `match_method` (exact / alias / fuzzy / llm / manual),
`match_confidence`, `matched_at`.

**Why.** This is the genuinely expensive-to-retrofit thing. Without it you can
never re-run improved matching over old rows, because you can't distinguish a
human-confirmed link from an old machine guess. With it, backfill is a safe,
repeatable background job.
