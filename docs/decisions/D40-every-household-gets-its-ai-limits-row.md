## D40 — Every household gets its AI limits row from a trigger

**Decided.** A trigger on `households` inserts a `household_ai_limits` row, and
the migration backfills existing households idempotently.

**Why.** So the column defaults are the only definition of what the caps start
at. The alternative was `coalesce(limits.cap, 500)` in `_shared/usage.ts`,
which is a second copy of a number that must agree with the first — and the
kind that disagrees silently, six months later, in the direction of spending
more.

A trigger rather than an edit to `create_household()`: that function is in an
applied migration and applied migrations are not edited, and a trigger also
catches the paths `create_household()` is not on.
