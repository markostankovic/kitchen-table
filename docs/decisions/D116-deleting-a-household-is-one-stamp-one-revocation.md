# D116 — Deleting a household is one stamp, one revocation sweep, and a membership sweep; no child row is touched
**Status:** active
**Touches:** supabase/migrations/20260924100000_delete_household.sql, supabase/functions/redeem-invite/index.ts, lib/features/households/presentation/household_screen.dart

**Decided.** `delete_household()` is owner-only, enforced inside the RPC —
not by narrowing `households_update`, the question D112 explicitly deferred
here. `households_update`'s RLS stays exactly as it is: membership-only,
column-blind, still accepting a `name` write from any member. The RPC body
is the one enforceable place for the owner check and the membership sweep
to happen as one atomic act; narrowing the policy would be a second, weaker
place for the same rule and would break rename, which stays open to any
member on purpose. In order, the RPC stamps `households.deleted_at`,
revokes every live invite for the household through migration 22's own
`revoked_at`/`revoked_by` columns (no schema change), and hard-deletes every
`household_members` row for the household — the owner's own included.
Household-scoped children (recipes, meal plans, shopping lists, import
jobs, translations, tags) are deliberately left unstamped: with no members
left, `is_household_member()` already makes every one of them unreachable,
so cascade-stamping a dozen tables would buy nothing. There is no
`deleted_by` column — `created_by` plus "only the owner can delete" already
answers who.

**Why.** A soft delete of `households` alone would strand every member:
their `household_members` row would survive, so `resolveHousehold()` and
3b's RPCs would keep resolving a household the client can no longer see,
and `redeem-invite`'s single-household rule would lock every ex-member out
of ever joining another household — permanently, for the owner most of all.
Sweeping every membership, not just relinquishing the owner's, is what
turns delete into a real exit instead of a trap.

**Rejected.** Cascading `deleted_at` to every household-scoped child table —
rejected because RLS already makes them unreachable the moment
`household_members` is empty, so a dozen extra `UPDATE`s would change
nothing anyone can observe. A `deleted_by` column — rejected as redundant
with `created_by` plus the owner-only rule; nobody else can ever be the
actor. Narrowing `households_update` to owner-only — rejected per D112's
own deferral: it would be a second, weaker enforcement point for the same
rule, and it would also block rename unless carved out separately.

**Consequences.** Deletion cannot be undone from the app, though every row
is still physically present for a hand-written `update households set
deleted_at = null` plus a re-inserted owner membership. A co-member sitting
on the recipe list when the owner deletes keeps seeing stale rows until
their next `currentHousehold` read — the same already-true-in-3b gap that
being removed by the owner has. The Drift caches for recipes, meal plans
and shopping lists are not purged (`_local.clearAll()` only empties
`currentHouseholdCache`), so those rows sit dead in the local database keyed
to a household id nothing will query again — inherited from 3b's leave
path, not introduced here; worth an idea if it should ever be swept.
`redeem-invite`'s live-invite peek needed one added guard (a left embed of
`households(deleted_at)`, reusing the `invite_revoked` slug) for the one
race the migration's own sweep can't close: a code claimed in the instant
before a delete commits.
