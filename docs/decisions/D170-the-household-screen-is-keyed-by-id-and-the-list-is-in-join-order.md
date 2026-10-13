# D170 — The Household screen is keyed by household id; the household list is in join order and reads its own query
**Status:** active
**Touches:** lib/features/households/presentation/household_screen.dart, lib/features/households/presentation/households_screen.dart, lib/features/households/presentation/widgets/household_row.dart, lib/features/households/application/household_providers.dart, lib/features/households/data/remote_household_datasource.dart, lib/core/household/current_household.dart, lib/core/router/routes.dart

**Decided.** `phase9-household-list`, 2026-10-13. Builds on D169 and D52.
1. **The Household screen takes a household id** (`/settings/household/:householdId`).
   Its header comes from `householdByIdProvider(id)` (derived from
   `myHouseholdsProvider`), and `householdMembersProvider` /
   `liveInvitesProvider` are families keyed by id. It can show a household
   that isn't current; the destructive button follows the caller's role in
   *that* household (D115). An id that isn't one of yours renders
   `noHouseholdYet`.
2. **After a leave or delete it lands by what was current:** no household
   left → the router's onboarding redirect; the current one → `/settings`
   (D5, now in the next household); any other → `/settings/households`.
3. **The Households list is in join order** (`household_members.created_at`),
   from its own query, `fetchMembershipRows` — the caller's rows with
   `households!inner(...)` and a nested `household_members(user_id)` counted
   client-side (no PostgREST aggregates). D169's oldest-household fallback
   (`fetchMineRows`) is untouched. Network-only, no cache (D88).
4. **Settings learns the rest through D52's record**, which grows to
   `({id, name, memberCount, otherHouseholdCount})`. It still hands out no
   households-feature type. `otherHouseholdCount` is 0 on an `AppFailure`,
   so offline the row takes the one-household look rather than failing.
   With 0 others the row opens the Household screen by `go` (Back → Settings);
   with more it opens the list, which `push`es the Household screen
   (Back → list). The two routes are siblings under Settings.
5. **`HouseholdRow` stays feature-private** in
   `households/presentation/widgets/` with an `onManage`-less mode, until the
   switcher sheet (a second feature's consumer) promotes it to
   `core/household/widgets/`.
6. **Every `postgrest-dart` `.order()` that matters passes `ascending: true`.**
   Its default is descending; raw PostgREST's is ascending, so a curl check
   shows the opposite of the app. Found on the walk; `fetchMembershipRows`,
   `fetchMineRows` (so D169's fallback is truly the oldest) and `fetchMembers`
   were fixed.

**Why.** The list's gear has to manage a household you aren't in right now,
so "the current household's screen" had to become "household X's screen".
Join order is what a person remembers ("the one I joined last"), and
reusing `fetchMineRows`' order would have tied the list to D169's fallback
rule, which is about something else.

**Rejected.**
- Switching to a household to manage it: a gear that silently moves every
  tab is a surprise the design rules out.
- Ordering the list by household age, or reusing `fetchMineRows`: changes
  D169's fallback or couples two unrelated orders.
- Settings importing `features/households/` for the count: D52 is the one
  crossing.
- `HouseholdRow` in `core/` now: one consumer today.

**Consequences.**
- A new household-scoped read on this screen keys off `widget.householdId`,
  never `currentHouseholdProvider`.
- Before a leave/delete the screen reads `currentHouseholdProvider`, not
  `currentHouseholdIdProvider`: nothing on the screen watches the latter, so
  a cold `read` returned loading (Riverpod 3).
- A household left open in another tab's detail screen survives a switch
  made from the list, until `phase9-household-switcher` pops tabs to root.
