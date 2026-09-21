# D115 — An RPC's refusal stays unlocalized on purpose; the UI gates the affordance instead
**Status:** active
**Touches:** supabase/migrations/20260921150000_member_removal_and_invite_revocation.sql, lib/features/households/presentation/household_screen.dart

**Decided.** The three `SECURITY DEFINER` RPCs this slice adds
(`remove_household_member`, `leave_household`, `revoke_invite`) raise plain
`raise exception '...' using errcode = '22023'` prose for every guard
(not the owner, can't remove self, owner can't leave, not a member, wrong
household). That prose reaches the user verbatim as a `ValidationFailure`
with `code == null` (D92) — unlocalized English in a Serbian-first app. No
new `FailureCode` or ARB sentence was added for any of them. Instead, the
household screen gates every affordance that could trigger one: an owner
never sees a Leave button on their own row, a non-owner never sees Remove
on anyone else's, and so on — so none of these refusals is reachable
through normal use. The RPC guards exist only as a backstop for a stale
list or a second device racing the first.

**Why.** Inventing a `FailureCode` and two ARB sentences per guard would be
weight carried for messages nobody using the app normally ever sees. The
one exception in this same slice, `invite_revoked` (D114), earns the full
treatment because it *is* reachable in normal use — someone can be reading
a code the instant another member revokes it, with no affordance to gate.
The distinguishing question for the next slice that adds an RPC guard is
exactly that: can the UI make this refusal unreachable, or is there a race
a gated affordance can't close?

**Rejected.** Custom SQLSTATEs per refusal, to let the client distinguish
them without parsing prose — rejected as unneeded machinery when the prose
is never shown. `42501` for the authorization refusals (not-owner,
wrong-household) — rejected specifically: it maps to `UnauthorizedFailure`,
whose default code is `FailureCode.signInAgain`, so "only the owner can
remove a member" would render as "Please sign in again." `42501` is
reserved for the `auth.uid() is null` guard alone, which is what it
actually means.

**Consequences.** 3c (delete) is the next slice with a destructive RPC
guard and the first with a genuine confirm-dialog precedent (this slice
built the first two, for remove and leave). It should default to this same
gate-the-affordance stance rather than re-deriving it, and only reach for a
localized `FailureCode` if it finds a refusal that a gated UI genuinely
cannot make unreachable.
