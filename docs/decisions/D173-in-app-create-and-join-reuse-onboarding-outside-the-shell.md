# D173 — In-app create and join reuse the onboarding screens, as top-level routes outside the shell
**Status:** active
**Touches:** lib/core/router/routes.dart, lib/features/households/presentation/create_household_screen.dart, lib/features/households/presentation/join_household_screen.dart, lib/features/households/presentation/household_landing.dart, lib/features/households/presentation/households_screen.dart, lib/features/households/presentation/household_screen.dart, lib/features/households/domain/invite_redemption.dart, lib/features/households/data/remote_household_datasource.dart, lib/features/households/data/household_repository.dart

**Decided.** `phase9-household-create-join-another`, 2026-10-13. Builds on D137, D169, D171.
1. **Routes.** `CreateAnotherHouseholdRoute` (`/households/new`) and
   `JoinAnotherHouseholdRoute` (`/households/join`) are top-level, outside
   the shell, and are `push`ed from two rows under the Households list.
   They build the same two screens with `another: true`: an app bar with
   `CloseButton`, no mark, title `sm` under the bar, a body naming the
   current household, no cross-link. Onboarding mode is unchanged (D137).
   The redirect needs no entry for them.
2. **`redeemInvite` returns `InviteRedemption`** (freezed, no JSON, built
   in `data/`): `householdId`, `householdName` (`''` if missing),
   `alreadyMember` (`false` if missing). "Already a member" is a quiet
   `card`-filled panel, never `error`. The button becomes **Done** (pops,
   no switch) for the current household, **Switch to X** otherwise.
   Onboarding ignores `alreadyMember` and switches as before.
3. **Landing** (`landInHousehold`, a plain function in
   `households/presentation/`): `switchTo`, `go` to the Recipes root, then
   "Now in X." (`persist: false`). The action is **Invite** after a create:
   it `go`es to `HouseholdRoute(id)`, and does not mint a code. It is
   **Undo** after a join, or after Switch.
4. **"Another home?"** on the Household screen renders only when
   `myHouseholds` has exactly one entry. It is absent while that's loading,
   on an error (D115), and with two or more, when the list already leads
   here. Its button pushes the list.

**Why.** A form under `/settings` stays on the Settings branch's stack after
the landing, because `AppShell` never marks the current tab stale (D171), so
going back to Settings would show a finished form. Outside the shell, the
landing's `go` takes the form with it. One widget with a flag keeps both
modes on one layout. The server already answered 200 `alreadyMember` (peek,
lost response, 23505 race), and the client was dropping it.

**Rejected.**
- Routes nested under `/settings` (the stale-form stack above).
- Separate `CreateAnother…` / `JoinAnother…` screen classes.
- Invite minting a code as a side effect of navigating.
- The card with two or more households: it would only link back to the list.
- The canvas's `KT7-2QM` code format: the field stays 6-digit numeric.

**Consequences.**
- The sr Switch label „Pređite u to domaćinstvo" omits `{name}`, which is
  declared but unused. `arb_parity_test.dart` carries a one-key
  `deliberatelyOmitted` exemption for it.
- Each new in-app household leaves Settings' stack as it was (the list,
  or Household › list), with the new radio filled.
