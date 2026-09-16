## D75 — The meal plan delta is household-scoped across all weeks, and a cache miss under a live watermark means "empty," not "unknown"

**Decided.** `entity = 'meal_plans'`, `scope = householdId` — one watermark
for the whole household, covering every week it has ever written into, not
one per `(household_id, week_start)`. `RemoteMealPlanDataSource
.fetchChangedSince` fetches every `meal_plans` row (with its embedded
`meal_plan_entries`) whose `updated_at` is after the watermark, or every row
the household has ever written into when the watermark is null — the same
shape D72 already gave recipes.

The note this decision replaces (D64–D74's closing summary, and the part 6a
sketch in `docs/ROADMAP.md`) proposed keying the watermark per week instead.
That is corrected here, on the same footing D49 corrected the original
`meal_plans` sketch and D58 corrected the trailing variety window.

**Why.**

- A per-week scope needs a two-step head-then-body fetch to be a delta at
  all: read the plan row's `updated_at` first, then its entries only if that
  moved. A week holds at most 28 small entries, so the head request buys
  almost nothing while costing a second round trip on the changed path.
- The Plan tab's whole interaction is paging between weeks. A
  household-scoped sync warms every changed week in one trip, so paging stays
  instant and correct offline for every week ever synced — including weeks
  never opened on this phone, which a per-week scope can never cache, because
  nothing would ever have asked the server about them.
- It gives the cache an authoritative negative. Once
  `LocalMealPlanDataSource.readWeeksWatermark` is non-null, a full fetch has
  happened for this household, so a cache miss for the requested week is
  "this week is genuinely empty" (D50's lazily-created plan row), not "we
  never looked." `MealPlanRepository.watchWeek` checks the watermark itself,
  separately from the per-week cache read, exactly so it can draw this
  distinction — a per-week scope has no watermark of its own to consult and
  would have to render "unknown" as "empty" and hope it is right.

**Cost, accepted.** The cold fetch (`since == null`) pulls the household's
whole meal-plan history. `meal_plans` holds one row per week ever *written
into* — browsing writes nothing (D50) — so a family planning weekly for a
year is on the order of 52 rows. It happens once per install; after that the
delta is almost always empty.

**Rejected.** Bounding the cold fetch to a window of weeks around today. It
breaks the watermark itself: a row outside the window with a higher
`updated_at` than anything inside it would still be skipped, the watermark
would still advance past it (the max is computed over what the fetch
*received*, not what exists), and when the window later slides to include
that week it can never be fetched again — silently, forever. An unbounded
first fetch of a small table is the cheaper correctness, the same trade D71
already made for recipes and the ingredient name catalog.
