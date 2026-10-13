# D169 — The current household is a device-local, per-user selection; the membership RPCs take the household
**Status:** active
**Touches:** lib/core/db/device_preferences.dart, lib/features/households/data/household_repository.dart, lib/features/households/application/household_providers.dart, lib/features/households/data/remote_household_datasource.dart, supabase/migrations/20261013120000_household_rpcs_take_a_household.sql, supabase/functions/_shared/auth.ts, supabase/functions/redeem-invite/index.ts, lib/core/supabase/supabase_failure.dart

**Decided.** `multi-household-b`, 2026-10-13. Finishes D168.
1. **The selection lives in `DevicePreferences` (D128)** under
   `selected_household.<userId>`. It is per user, so a second account on the
   phone never inherits it, and it survives sign-out and the drop-and-recreate
   upgrade on purpose. `fetchCurrent` prefers it and falls back to the oldest.
   A stale selection (a household since left or deleted) needs no cleanup,
   because it simply matches no row.
2. **`CurrentHousehold.switchTo(id)` is the one way to change it.** It calls
   `HouseholdRepository.select`, which writes the preference and then clears
   the user's cached row (D88's hazard: if the re-fetch fails offline, the
   cached row is the *old* household, so the switch must surface as an
   error). Create and join switch to the id they get back.
   `currentHouseholdIdProvider` stays the one derived id (D52).
3. **The membership RPCs take the household.** `remove_household_member`,
   `leave_household` and `delete_household` take `target_household` and check
   the caller's role in *that* household (22023 if none). `revoke_invite`
   keeps its signature but checks membership of the invite's own household.
   No RPC orders memberships by age any more.
4. **No fallback anywhere.** `resolveHousehold` is deleted. A function body
   without `householdId` is a 400 `invalid_household`. `redeem-invite` no
   longer rejects a second membership, so `already_in_household` is gone.

**Why.** Only the client knows which household is being looked at, and two
devices on one account may legitimately be looking at different ones. The
selection is a preference of this phone, and `DevicePreferences` is the
existing non-cache table that already survives what the cache doesn't.

**Rejected.**
- A server-side selection column: a second source of truth, and two devices
  would fight over it (D168).
- A new Drift table: `DevicePreferences` already is the upgrade-surviving,
  non-cache table.
- Reusing `CurrentHouseholdCache`'s row as the selection: create and join
  clear it, and redeem's response lacks `created_by` to rebuild it.
- Keeping the zero-argument RPC overloads for old builds: the same lingering
  fallback D168 set out to end.

**Consequences.**
- Any build from before this slice loses leave, delete and remove-member.
  A build from before slice A also loses every import. Only the Galaxy had
  the app, and it was updated the same day.
- A new household-scoped RPC takes the household as a parameter and checks
  membership of it. A new function calls `requireHousehold`.
- `switchTo` reads `currentUserIdProvider`'s current value. In the app the
  router keeps it live. A test that drives `switchTo` without listening to
  `currentHouseholdProvider` sees no user (Riverpod 3 pauses unlistened
  providers).
