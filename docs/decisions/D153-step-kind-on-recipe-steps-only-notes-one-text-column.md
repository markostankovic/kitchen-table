# D153 — Step kind lives on recipe_steps only; notes are one text column
**Status:** active
**Touches:** supabase/migrations/20261006100000_recipe_structure.sql, supabase/functions/_shared/{schema,translate,read_recipe,jsonld}.ts, supabase/functions/translate-recipe/index.ts, lib/features/recipes/domain/{recipe_step,recipe_detail,recipe_draft,translation_review_draft}.dart, lib/features/recipes/data/, lib/features/import/{domain/parsed_recipe_draft,data/import_repository}.dart

**Decided.** Round `2026-10-06-round-2-recipe-structure`, slice 4, 2026-10-06:
1. **`recipe_steps.kind`** (`step` | `heading` | `note`, default `step`) is the
   only place a row's kind is stored. A heading or note is a row of the same
   ordered list and takes a `position`. `recipe_translations.steps` stays
   `[{position, text}]`, and `RecipeDetail.displaySteps` overlays the source
   kind by position.
2. **`translate-recipe` sends kind as context** (`[heading]` / `[note]` tags)
   but `ModelTranslationStep` never returns it.
3. **A timer only on a step** (`kind = 'step' or timer_seconds is null`).
   Blank headings and notes hit the existing text check, so drafts drop them
   like blank steps.
4. **Notes are one nullable `text` column** on `recipes` and on
   `recipe_translations`, not a list. Blank → null. The markdown subset lives
   in the text; nothing parses it yet.
5. **Changed signatures are dropped and recreated, not overloaded.**
   `save_recipe_translation` and `review_recipe_translation` take a trailing
   `new_notes text default null`, so a five-argument call still resolves. Both
   functions' revoke/grant is re-applied on the new signature.
   `replace_recipe_lines` and `save_imported_recipe` keep theirs: kind and
   notes ride in the jsonb.
6. **A review writes notes back**: `notes = nullif(btrim(new_notes), '')`.
   Notes not sent are cleared, so `TranslationReviewDraft` carries them even
   though the review screen doesn't edit them yet.
7. **`RecipeStepKind.fromWire(null)` is `step`**, for old
   `import_jobs.result` rows and old cache blobs. An unknown string throws.

**Why.** One authority for structure: a translation is prose over it, so
`alignSteps` and the review's position guard (D80) work unchanged and a
reviewer can't turn a step into a heading. The model is never asked for
structure it can't change (D41's instinct). Overloading would make every
existing five-argument call ambiguous. A review is a whole-document write
(D78), so notes are written back like the rest of the document rather than
special-cased.

**Rejected.**
- `kind` inside the translation's steps jsonb: that gives structure two
  authorities that can disagree.
- Notes as a list or a child table: the brief is free text with markdown
  lists, and a child table would need D24's touch-the-parent rule for
  nothing.
- An overloaded six-argument function beside the old one.
- A review that leaves notes alone when `new_notes` is null: a reviewer
  could then never clear them.
- A new Drift table: D65's verbatim blob already carries the new keys.

**Consequences.** Every rewriting path must send kind and notes, or it
silently drops them. That holds today because both drafts carry them. A
translation made before a cook adds a heading keeps the default kind for any
position the source no longer has, and is never re-offered (D85). Hosted
needs `supabase db push` plus `make functions-deploy` before slices 5–6 can
be walked.
