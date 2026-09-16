## D85 — Re-translating a reviewed translation is not offered, and the UI is the only guard

**Decided.** `RecipeDetail.canTranslate` requires `translation == null`
(unchanged since D78) and is never narrowed further by review state, so once
any translation exists — reviewed or not — the *Translate to …* overflow
item is gone for good on that recipe/locale pair. There is no
`review_recipe_translation`-side or `save_recipe_translation`-side guard
against a machine pass overwriting a human's review; migration 17's own
`on conflict` clause still resets it, deliberately, the way D78 always
intended.

**Why the UI is allowed to be the only guard.** `translate-recipe` and
`save_recipe_translation` are internal, `security invoker` and reachable
only through a caller who is already a household member — there is no path
by which a stray or hostile write could land there that RLS was not already
going to allow the same person to make through the ordinary route. The
thing being prevented is an accidental tap costing a human's edit, not an
unauthorized write, and an accidental tap is exactly what removing the menu
item from the itemBuilder prevents.

**Rejected.** A `review_recipe_translation`-adjacent guard on
`save_recipe_translation` refusing to overwrite a reviewed row — would have
made an ordinary re-translation of an UNREVIEWED machine draft (the common
case D78 was written for) indistinguishable in code from the rare case of
protecting a review, and would have needed its own bypass for a household
that genuinely wants to discard a bad review and start over, a need nobody
has expressed yet. Offering *Translate again* behind a confirmation dialog
once a translation exists but has not yet been reviewed — a real product
question, deliberately left open rather than decided here: `canReview`
already covers "there is something to review" without it, and adding a
second, narrower `canRetranslate` getter is a small, separate decision for
whoever picks this up next.
