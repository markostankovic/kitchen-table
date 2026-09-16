## D42 — No machine tier writes to the catalog

**Decided.** Tiers 3, 4 and 5 write no `ingredient_names` rows and create no
ingredients during an import. The write-back happens on the confirm screen,
when a human accepts a line, through `link_ingredient_alias` (D34).

**Why.** `docs/INGREDIENTS.md` says every resolution writes back, and it is
right about why: ingredient strings are Zipf-distributed, so a few hundred
aliases cover most of what anyone will ever write, and that is what stops the
LLM tier being paid for twice. The disagreement is only about *when*.

Writing back during import makes a machine guess global and permanent (D28: one
string, one ingredient, forever) before any human has seen it — and D8 exists
precisely because a human sees every import. Tier 5 would be worse: `za
posluživanje` is a real line in the fixture, and creating an ingredient for it
at import time would enter "for serving" into the catalog as food.

Since the confirm screen accepts by default, the cost curve still drops on the
first import of a new string. It drops one tap later.

**Consequence.** The confirm screen is now the *only* thing that grows the
catalog, which raises the stakes on D8 rather than lowering them. It also
removed a smaller problem rather than solving it: `link_ingredient_alias`
hardcodes `source = 'user'` and needs a non-null `auth.uid()`, so a machine
tier calling it would have meant either lying about provenance — the thing D7
exists to prevent — or a migration to widen it.

**And tier 4 is best effort.** It could originally sink a whole import: a
recipe read perfectly from JSON-LD would fail because an optional improvement to
its ingredient matching was unavailable. Tiers 1–3 are deterministic and already
done by then, so a tier 4 failure now logs, records any tokens it spent, and
returns the deterministic matches. The cook gets a draft with more lines to
confirm by hand, which is the confirm screen's job anyway. Same shape as rule 3:
structure is an enhancement on `raw_text`, and the LLM tier is an enhancement on
the tiers below it.
