## D25 — `household_invites` carries neither `deleted_at` nor `updated_at`

**Decided.** A deliberate exception to CLAUDE.md rule 4, for a table that D24
would otherwise catch (it has a `household_id`). `used_at` is the lifecycle
column, and it is the only one.

**Why.** An invite is append-only: created once, stamped dead once. Rule 4's
intent — no row ever disappears — is already met without `deleted_at`. Adding
it would introduce a second lifecycle axis with no defined interaction with the
first ("soft-deleted but unused"?), and would force the partial unique index to
`where used_at is null and deleted_at is null` — which would let a soft-deleted
code be reissued to a *different* household while a row still claims it.
`deleted_at`'s other job, tombstones for the Phase 2 delta fetch (D23, D12),
does not apply: invites are not a cached entity and a code is meaningless
offline. `updated_at` would be written exactly twice in a row's life, and the
second write already records its own timestamp in `used_at`.

**Rejected.** Adding both columns and marking them vestigial. Rule-literal, but
it buys a wrong index predicate and two columns nothing reads.

**Consequence.** There is no way to revoke a live code; you wait out the 7-day
expiry or it gets used. Adding revocation later means a `revoked_at` column
*and* a rebuild of the partial index predicate, in one migration.
