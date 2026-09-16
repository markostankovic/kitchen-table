## D47 — Model options are per-model, in a table

**Decided.** `_shared/ai.ts` carries a `CAPABILITIES` table beside `MODELS` and
`PRICING`, and `callStructured` adds `thinking` and `fallbacks` only for models
that accept them. Opus 5 gets adaptive thinking and a server-side refusal
fallback; Haiku 4.5 gets neither.

**Why.** `callStructured` used to send `thinking: {type: "adaptive"}` for every
model. Haiku 4.5 predates adaptive thinking and answers it with a 400 —
`adaptive thinking is not supported on this model` — so **tier 4 never worked,
from the day it was written in part 2 until credits made it observable in
part 6.**

What kept it hidden is worth recording, because the mechanism was working as
designed. D42 made tier 4 best-effort: tiers 1-3 are deterministic and already
done, so a tier 4 failure logs, records any tokens spent, and returns the
deterministic matches rather than sinking the import. That is still the right
call — losing a read recipe because an optional improvement was unavailable
would be the wrong trade. But best-effort turns a hard failure into a silent
degradation, and a permanent bug then looks exactly like an occasional one. The
only symptom was that no `match-ingredients` row ever appeared in `ai_usage`,
and nothing was watching for its absence.

**Consequence.** `ai_test.ts` now asserts that every model in `MODELS` has a
`CAPABILITIES` entry, and names the Haiku/adaptive pairing explicitly — the
same shape as the existing "every model has a price" guard. Adding a model is a
row in two tables and a failing test if you forget either.

**The general lesson, since it will recur.** A best-effort path needs something
that notices it is always failing. The absence of a ledger row is a fact the
database already has; Phase 2's admin screen is the natural place to surface it.
