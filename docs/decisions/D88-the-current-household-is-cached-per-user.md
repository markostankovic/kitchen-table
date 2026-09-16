## D88 — The current household is cached per user, decoded by the same wire decoder, read network-first with a cache fallback

**Decided.** Phase 2 part 7, closing D87. `CurrentHouseholdCache` (`core/db/
app_database.dart`) is a new table keyed on `userId`, storing the raw
`households` row `RemoteHouseholdDataSource.fetchMineRows()` returns.
`HouseholdRepository.fetchCurrent(userId:)` reads network-first with a
cache fallback — `IngredientRepository.fetchUnitCatalog()`'s exact shape
(D70): on success, write the chosen row through; `on NetworkFailure`, read
the cache; a cold cache rethrows. `dto/household_dto.dart`'s
`householdFromWire` is the one decoder for both a fresh response and a
cache hit (D65), replacing the private `_toHousehold` that used to live
only inside the repository.

**Why keyed by user, not a singleton row.** Every other cache table in
this database is per-household or global; this is the first per-user one.
Keying by `userId` makes a wrong-user read impossible by construction —
the property a comment on a singleton row could only assert, not enforce.
The sign-out wipe (`clearHouseholdCache`) still drops this table too, on
`MealPlanWeekCache.uniqueKeys`' own precedent of a redundant guard beside a
structural one: belt-and-suspenders, not the only thing keeping it correct.

**Why the raw row, not `Household.toJson()`.** `Household`'s generated
`toJson` is camelCase and has no caller today; using it here would be the
second path into one model `HouseholdInvite`'s own doc comment says this
project avoids. Storing the wire row verbatim and decoding it with the same
function a network read uses is `recipe_dto.dart`'s precedent, not
`unit_catalog_dto.dart`'s — there is no domain object built up and
re-encoded here, only ever read off the wire and cached as-is.

**Why network-first, not cache-first.** `CreateHouseholdScreen` and
`JoinHouseholdScreen` both `invalidate(currentHouseholdProvider)` and
re-`await` it, expecting a fresh read that reflects the write they just
made; the router's redirect then reads the result synchronously. A
cache-first order would risk serving the household the cook just left
onboarding for.

**Why `create()`/`redeemInvite()` clear the whole cache on success.**
Network-first-with-fallback introduces a failure mode that did not exist
before: household A cached, the cook redeems an invite into household B,
and the confirming re-fetch blips offline — without clearing, the fallback
would silently resurrect A instead of correctly leaving the redirect
stalled in onboarding. Clearing on success closes it; caching remains
correct independent of exactly when the next read happens to fail.

**Rejected.** A singleton row (`UnitCatalogCache`'s shape) — correct only
as long as sign-out is never skipped or raced, where a per-user key is
correct by construction regardless. Reading `Supabase.instance.client.auth
.currentUser?.id` from inside `data/` instead of threading `userId`
through — legal under rule 1, but a second definition of "who is signed
in" next to `currentUserIdProvider`, which exists specifically so nothing
else has to define that.
