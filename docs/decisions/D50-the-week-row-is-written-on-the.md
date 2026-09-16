## D50 — The week row is written on the first write, never on a view

**Decided.** `ensure_meal_plan(household uuid, week date) returns uuid`,
`security invoker`, guarded by `is_household_member(household)` raising
`42501` before anything else runs. `insert into meal_plans ... on conflict
(household_id, week_start) do update set deleted_at = null returning id`. The
unique index stays total (not partial on `deleted_at is null`). Called only
from `MealPlanRepository`'s write methods, never from `fetchWeek`.

**Why.** The grid must open on any week without writing a row for it —
browsing a year of weeks nobody planned must not insert 52 empty rows.
`do update` rather than `do nothing`: `on conflict do nothing returning id`
returns **no row** on conflict, which is the common case here (most writes
land in a week that already has a plan), so the RPC would return `NULL`
exactly when it matters most. `do update` guarantees a row every time, and as
a consequence also resurrects a soft-deleted week into its same row rather
than being blocked by it — a bonus, not the main reason. The membership guard
comes first so that a non-member is refused with `42501`, not with `23505`
from falling through to the unique constraint on a row they cannot see — the
wrong error code would read as "that already exists" instead of "you are not
allowed here". The `household` parameter is passed in rather than resolved
inside the function because no `current_household()` exists anywhere in this
schema; the only definition of "your household" is the client's own query
(`HouseholdRepository.fetchCurrent`, D52), and this function is not the place
to invent a second one.

**Rejected.** Creating the plan row on first *view* — a write hiding behind a
read, and a year of browsing would still write 52 rows. A partial unique
index `where deleted_at is null` — only usable as an `on conflict` arbiter if
every statement repeats the predicate, and it would let a live and a dead row
coexist for the same week, handing the Phase 2 delta fetch an ambiguous key
for the entity D23 exists to let it evict.
