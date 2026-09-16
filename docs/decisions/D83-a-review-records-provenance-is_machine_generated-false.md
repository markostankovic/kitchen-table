## D83 — A review records provenance -- `is_machine_generated = false`, `reviewed_by` from `auth.uid()` -- and the app shows that it happened without saying who

**Decided.** `review_recipe_translation` sets `is_machine_generated = false`
even though the reviewer may have changed only one word, and stamps
`reviewed_by = auth.uid()` — never a parameter — and `reviewed_at = now()`.
The detail screen's *Machine translation* chip reads
`isShowingMachineTranslation`, which reads that same column, so the chip
disappears the moment a review lands with no code written to make it
disappear. No *Reviewed* chip is added, and the reviewer's name is not shown
anywhere.

**Why provenance follows the last human who stood behind the text, not the
first draft.** `MatchMethod.manual` (D7) is the precedent: accepting the
match the machine already proposed still writes `manual`, "a human decision
… never overwritten by a later machine pass." A human agreeing with a
machine's own words is still a human decision, the same way
`link_ingredient_alias` hardcoding `source = 'user'` (D42) means a human
agreed, not that a human typed the string from scratch.

**Why no `reviewed_by` parameter.** The RLS policy would happily let any
household member write any uuid into that column; a client-supplied
reviewer id is exactly the kind of self-reported provenance D7 exists to
rule out. `auth.uid()` inside the function is what makes the column mean
something rather than merely look like something.

**Why no chip and no name shown.** This app's chips are caveats — *Draft*,
*Machine translation* — never endorsements, and a *Reviewed* badge would be
the first positive-state chip in the project, sitting on the ordinary case
forever once every translation is eventually reviewed. Naming the reviewer
is not merely a design choice deferred — it is priced here so a later part
can choose it knowingly: `recipeDetailEmbed` does not join `profiles` today,
and adding `profiles!reviewed_by(display_name)` would change the shape of
the blob `RecipeCache.data` stores verbatim (D65), which by D78's own
precedent (`AppDatabase.schemaVersion` 3 → 4 for a blob-shape change alone)
costs another schema bump for a line nobody has asked for yet.

**Rejected.** A `reviewedChipLabel` chip driven by `isReviewedTranslation` —
cheap to add, and left out on the "chips are caveats" argument above rather
than on cost. Showing the reviewer's name — priced above, not built,
because the cost is a schema bump this part has no other reason to pay.
