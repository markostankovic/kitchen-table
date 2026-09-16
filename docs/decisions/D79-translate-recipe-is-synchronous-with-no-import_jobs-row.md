## D79 — `translate-recipe` is synchronous, with no `import_jobs` row

**Decided.** One recipe id and a target locale in; the function reads the
recipe, calls the model, saves the translation and answers 200 — all inside
the request, on `match-ingredients`' shape rather than `import-text`'s.

**Why.** `import_jobs` exists because an import is a multi-stage pipeline
ending in a human confirm screen (D14, D8), and its `kind` is a closed set of
three with import-shaped input columns (`input_url`/`input_text`/
`input_storage_path`). A translation is one model call over prose the
household already owns, with no confirm gate in this part — there is nothing
for a job row to track between "asked" and "done" that the HTTP response
itself cannot carry. `match-ingredients` already establishes the shape:
everything inside the handler, thrown straight out to `withHttp`, a plain
200.

**Consequence.** Idempotent, and on the recipe's own `original_locale` it
makes no model call at all — checked before `checkQuota` even runs, the same
"nothing to do here should never cost a token" property `match-ingredients`
states for its own fully-matched case.

**Rejected.** A fourth `import_jobs.kind` — would have widened a table whose
columns are shaped around three input kinds that all have a *source*, for a
feature whose only input is a recipe id already in the database.
