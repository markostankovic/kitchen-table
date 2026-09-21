# D113 — Membership removal is a `SECURITY DEFINER` RPC, owner-only, and the owner may not leave
**Status:** active
**Touches:** supabase/migrations/20260921150000_member_removal_and_invite_revocation.sql, supabase/tests/rls_household_test.sql

**Decided.** Removing a member and leaving a household both go through
`SECURITY DEFINER` RPCs (`remove_household_member(target_user)`,
`leave_household()`) rather than a DELETE policy on `household_members`.
Removal is owner-only; leaving is open to anyone except the owner. The
"last member may not leave" question the roadmap raised collapses into one
check: since only the owner removes, and the owner can neither be removed
nor leave, the owner row always survives, so guarding on role alone is
sufficient and a separate last-member count is unreachable.

**Why.** Mirrors `create_household()`'s own reasoning: an RPC, not a
policy, because every invariant (owner-only, can't-remove-self,
owner-can't-leave) needs to live in one enforceable place rather than
spread across a USING clause that PostgREST's row-level semantics can't
express (a DELETE policy has no way to say "unless you are the owner
removing yourself" against a row that has no signal for "myself"). It also
answers D24's own deferred question — "auditable membership revocation" —
by name: **it stays deferred.** Removal is still a hard delete with no
audit trail. Nothing about this slice adds one; the two are orthogonal
(this decides who may remove and when, not whether the removal leaves a
trace).

**Rejected.** A DELETE policy with a `USING` clause checking role and
target — rejected because it can express "owner may delete any row in
their household" but not "except the owner's own row," which needs a
same-row auth.uid() comparison PostgREST evaluates per-row anyway, at which
point the policy is just as opaque as an RPC without the RPC's single
comment explaining all three invariants together. A separate
"last member" count distinct from the owner check — rejected as dead code,
per the collapse above.

**Consequences.** `household_members` still has no write policy of any
kind (D26's stance intact). Auditable removal remains open in
`docs/decisions/OPEN.md` for whoever wants a trail later — likely a
`household_member_removals` log table written by this same RPC, not a
schema change to `household_members` itself.
