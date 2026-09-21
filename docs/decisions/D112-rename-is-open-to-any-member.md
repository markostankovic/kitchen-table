# D112 — Rename is open to any member, and the client writes only `name`
**Status:** active
**Touches:** lib/features/households/data/remote_household_datasource.dart, lib/features/households/data/household_repository.dart, supabase/tests/rls_household_test.sql

**Decided.** Renaming a household stays open to any member, not just the
owner. `households_update`'s RLS already checks membership only, not role
(`supabase/migrations/20260906204711_identity_households.sql:194-198`), so
any `adult` could already rename or soft-delete the household before this
slice -- the UI had simply never offered it. This slice ships no migration
and no new policy: it only builds the client write and adds the
member-level RLS assertion (`rls_household_test.sql`) the suite was missing,
covering both an `adult` and the `owner`. The client itself writes only
`name` -- `RemoteHouseholdDataSource.rename` sends a single-column
`.update({'name': name})`, never the twelve-arg shape a DTO encoder would
imply.

**Why.** Matches the stance `create-invite` already took: "owner and adult
are both trusted adults." Rename is non-destructive, so there is nothing
here that needs the extra friction owner-only would add. Owner-only is left
for 3c (delete), where a destructive action makes the distinction matter.

**Rejected.** A migration narrowing `households_update` to owner-only, or to
a `name`-only column set -- both are policy changes with no behavioural
requirement driving them yet; 3c may want either, but not on this slice's
say-so. A `household_dto.dart` `toWire()` encoder, per `docs/ROADMAP.md`
part 3a's own guess -- unnecessary, since the write is a single narrow
column on `setFavorite`/`setRating`'s precedent
(`lib/features/recipes/data/remote_recipe_datasource.dart:416-430`), not a
full-row update.

**Consequences.** `households_update` stays column-blind: it would also
accept a client-supplied `deleted_at` or `created_by`, which only matters
once something writes those columns from the client, which nothing does
yet. `fetchMineRows`'s explicit column list already included `name`, so the
confirming re-fetch needed no change either, contrary to the roadmap's other
guess. An offline confirming re-fetch after a successful rename serves the
old cached name until the next successful read (`HouseholdRepository.rename`
deliberately does not `_local.clearAll()`, unlike `create`/`redeemInvite` --
D88 -- since there is no household change to guard against here).
