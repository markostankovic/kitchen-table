# D114 — Invite revocation: `revoked_at`/`revoked_by`, the rebuilt index, and the `redeem-invite` guards it forces
**Status:** active
**Touches:** supabase/migrations/20260921150000_member_removal_and_invite_revocation.sql, supabase/functions/redeem-invite/index.ts, supabase/tests/rls_invites_test.sql

**Decided.** `household_invites` gains `revoked_at`/`revoked_by`
(mirroring `used_at`/`used_by`'s paired-stamp shape exactly, including the
`(revoked_by is null) = (revoked_at is null)` check constraint), and the
partial unique index (`household_invites_code_unused_idx`) is rebuilt to
`where used_at is null and revoked_at is null`. Any member of the invite's
own household may revoke it, not just the owner — `create-invite`'s
"owner and adult are both trusted adults" stance, mirrored for revocation.
`revoke_invite(invite_id)` is a third `SECURITY DEFINER` RPC alongside
D113's two. This closes `docs/decisions/OPEN.md`'s "Invite revocation"
entry, which D25 opened.

**Why.** D25 named the exact cost when it deferred revocation: a
`revoked_at` column *and* a rebuilt index predicate, in one migration —
not a soft delete, not a fourth lifecycle axis with its own rules.
Revoking releases the code for reuse, on `used_at`'s own precedent: a
killed code should be re-mintable immediately, not squat on its six digits
until it expires. That reopens D25's own named trap deliberately: a dead
(revoked) row keeps its code, so the code can be re-minted for a
*different* household while the old row still carries it. That trap was
already true of `used_at`, is now equally true of `revoked_at`, and is
intended behaviour both times — `rls_invites_test.sql` asserts it directly.

**Rejected.** Owner-only revocation — rejected on the same stance
create-invite already took for minting; there is no reason killing a code
should need more trust than making one. A soft-delete-style `deleted_at` on
`household_invites` — rejected for the reasons D25 already gave for `used_at`
and repeated here: a second overlapping lifecycle axis, and CLAUDE.md rule 4
does not apply since an invite already never disappears.

**Consequences.** `redeem-invite`'s peek (`.is('used_at', null)`) and claim
(`UPDATE ... where used_at is null`) both gained a `.is('revoked_at', null)`
/`and revoked_at is null` clause — without it, a revoked row and a live
re-mint of the same code both match the peek's `.maybeSingle()` and it
throws. `invite_revoked` is a genuinely reachable failure (someone can read
a code the moment it gets revoked), so unlike every other refusal this
slice's RPCs raise, it gets the full `FailureCode`/ARB treatment rather than
unlocalized server prose — see the-refusal-copy-decision in
`docs/active/phase6-part3b.md` (now folded into this entry, since that file
is deleted on close) for why the other refusals stay unlocalized: the UI
gates every other affordance so those RPC guards are unreachable in normal
use, and inventing per-refusal `FailureCode`s for backstops nobody can
trigger would be dead weight.
