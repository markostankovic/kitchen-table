## D80 — What `translate-recipe` asks a model for, and what it never sees

**Decided.** Ingredient lines are never sent to the model and never
mentioned in its prompt. Serbian output is required to be Latin script only,
stated as an explicit rule rather than assumed. Every source step is
translated 1:1 and comes back carrying the SAME position number as its
source; `_shared/translate.ts`'s `alignSteps` validates the returned
position multiset against the source's own and refuses — as a billed
`AiFailure`, not a silent reorder — on any mismatch.

**Why no ingredient lines.** They are never translated per recipe (D1) —
they render from the bilingual catalog at read time. Sending them to
`translate-recipe` would invite the model to produce a second, worse answer
to a question `ingredient_display_name()` already answers exactly, and it
would be paying for a translation `search_ingredients`/`ingredient_names`
already gives away for the cost of a join.

**Why Latin script is a stated rule rather than an assumption.** D4 already
settled Latin-only for storage and display, but nothing about that decision
constrains what a language model volunteers when simply asked for "Serbian" —
it will produce fluent Cyrillic on request, and nothing downstream of the
model call would catch it before it reached `recipe_translations.title`.

**Why position is asked for at all, when D41 says not to ask a model to redo
work code already does.** D41's argument is about re-deriving a value a
deterministic pass already computes exactly (a quantity, a unit code, a
match). Position here is not that: it is an alignment key over prose the
model itself is producing, and nothing deterministic could supply it instead
— only the model knows which translated sentence corresponds to which
source step. Asking for it and validating it is what turns a step the model
silently merged or dropped into a loud, billed failure instead of a
translated method quietly missing a line.

**Rejected.** Aligning translated steps to source steps by array order
instead of an explicit position field — indistinguishable from a merge or a
drop unless the counts happen to differ, and a model that merges two short
steps into one produces an array of the "right" apparent shape with the
wrong content silently attached to the wrong position.
