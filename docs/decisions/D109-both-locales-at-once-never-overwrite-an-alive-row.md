# D109 — Both locales at once, never overwrite an alive row, fired unawaited
**Status:** active
**Touches:** supabase/functions/translate-tags/index.ts, lib/features/recipes/application/recipe_editor.dart, lib/features/recipes/data/recipe_repository.dart

**Decided.** `translate-tags` asks the model for a tag's Serbian *and*
English spelling together, never one locale at a time — there is no
language-detection step, and a tag missing only one locale still gets both
back, with the already-alive one simply not written. "Already paired" means
both an alive `sr` row and an alive `en` row exist for a `tag_key`; anything
else (no row, or a soft-deleted one) is work. An alive row — `curated`,
`user`, or an earlier `llm` pair — is never overwritten; only a missing slot
is inserted and only a soft-deleted one is revived. `RecipeEditor.save()` is
the only trigger, and it fires `translateTagsBestEffort()` unawaited, not
awaited: `revision` and `repository` are captured into locals before the
call so the callback never touches `ref` after the editor disposes.

**Why.** A single combined ask is one model call instead of two, and it
means a tag that already has, say, a curated `sr` spelling still gets an
`en` one minted without a second round trip once support for that existed.
Never overwriting an alive row is what keeps a `curated` or hand-reviewed
`user` pair permanent — D85 already rejected re-translating a *reviewed*
recipe translation for the same reason, and a household's own correction to
a tag deserves the same protection. Firing unawaited (rather than
`RecipeEditor.save()`'s own `await`ed image-cleanup call) is what keeps a
model call off the save's own latency — D48's "must not delay or block an
otherwise-successful save" applied all the way, not just to rollback.

**Rejected.** Wiring `ImportConfirm.saveImported` as a second trigger —
`features/import/` may not reach `RecipeRepository`, and the function diffs
a household's *whole* vocabulary rather than just the triggering recipe, so
the next editor save already delivers the same pairs at no extra cost.
Detecting which locale a tag was typed in and translating only the other —
rejected in the same planning session that produced D107: the reader-side
resolution rule already treats both rows as arriving from the same "llm"
pass, and a detection step would be a second place that could disagree with
it.

**Consequences.** A tag typed and immediately re-typed differently (a typo
fixed by hand) creates a second `tag_key` with its own pair to mint, not a
correction to the first — unchanged from D107's own key choice, just
inherited here. A household that never opens the editor after adding a tag
elsewhere (there is no such path today) never gets a pair minted for it,
since the editor's `save()` is the only trigger.
