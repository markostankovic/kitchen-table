## D13 — Shopping list is generate-and-view

**Decided.** Generating a list produces a snapshot. No per-item checked state,
no sync of shopping progress.

**Why.** User's call. Consequence: zero offline writes, which removes the
outbox, idempotency handling, and last-write-wins reasoning entirely.
