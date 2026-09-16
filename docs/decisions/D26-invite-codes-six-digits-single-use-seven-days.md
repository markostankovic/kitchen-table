## D26 — Invite codes: six digits, single-use, seven days, service-role only

**Decided.** `create-invite` and `redeem-invite` are Edge Functions holding the
service role key, per ARCHITECTURE.md's "anything granting access to household
data is not client logic". The client never writes `household_invites` or
`household_members`; neither table has a write policy at all.

Codes are six digits from `crypto.getRandomValues` with rejection sampling
(a bare `% 1e6` favours low codes; `Math.random()` is seeded per-isolate).
Minting inserts and retries on `23505` rather than pre-checking, which would be
TOCTOU regardless. Any member may invite — `owner` and `adult` are both trusted
adults. Redemption is a conditional `UPDATE ... where used_at is null`, not
SELECT-then-UPDATE, which would let one code grant two memberships.

The `token uuid` column exists but is never read or returned. It is there so
Phase 4's public invite links do not need a migration.

**Redeeming into a second household is rejected** with 409. The schema permits
multiple memberships, but the app does not: `fetchCurrent()` returns
`mine.first`, so a second membership would silently decide which household you
see by creation order. Allowing it needs a household switcher, which is not on
the roadmap.

**Why no rate limiting yet.** A 10^6 space is sweepable in ~28 hours at 10
req/s, inside the 7-day window. What actually contains it is density: 1–5 codes
are live at any moment, so a sweep yields a hit only if it overlaps a live code,
and `verify_jwt` forces the attacker to hold a real session first. Single-use
means a successful guess burns the code, so the real invitee notices. That is
proportionate for a family app and no more. **Upgrade path if this ever leaves
the family:** an `invite_redemption_attempts (user_id, attempted_at)` table with
a ~10/hour cap checked in `redeem-invite`.

**Known limitation.** Claiming the invite and inserting the membership are two
PostgREST calls, not a transaction. The failure path releases the claim, but an
isolate killed between the two burns the code with no membership created;
recovery is to ask for a new one. The fix, if it ever matters, is a direct
postgres connection and a real transaction — not a `SECURITY DEFINER` RPC,
which would split the trust boundary across two places.
