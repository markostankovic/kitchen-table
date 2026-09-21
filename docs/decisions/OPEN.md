# Open / deferred

Named but not decided -- known gaps, deferred follow-ups, things worth
revisiting. Moved out of `docs/DECISIONS.md`'s old single file; not
part of the numbered decision sequence.

---


- **`signImageUrls`/`_withImageUrls` are outside `runGuarded`** — found
  during D89's survey, not on D87's path (`_withImageUrls` never runs for a
  recipe served from the cache — `recipe_repository.dart`'s own comment),
  and not fixed there. Wrapping it is a behavior change, not a tightening:
  a `StorageException` becoming a `NetworkFailure` would newly trigger
  `fetchDetail`'s D74 cache fallback, turning "recipe loads, no photo" into
  "recipe served stale". Needs its own decision, not a side effect of
  bounding one unrelated call.
- **`ImportRepository.uploadImportPhoto` still carries its own inline copy
  of "which household"** — found during D88's survey. D52 claimed to close
  D33's last duplicate of that query; this one survived, on a write path,
  online-only, unaffected by the household cache. Named so it is not
  mistaken for closed.
- **`currentHouseholdProvider` never re-resolves within a process.**
  `keepAlive`, so once it settles on an answer — cached or fresh — nothing
  re-fetches until the app restarts. A household resolved from cache while
  offline stays that way even after the network returns. Invalidating it on
  `NetworkStatus` flipping offline→online is the natural follow-up; not
  built, named here (D88, D89).
- **Client vs Edge Function split** — rule of thumb written in
  `docs/ARCHITECTURE.md`. Settled enough to build on.
- **Thin web layer** — deferred, and as of Phase 5's planning no longer on
  the roadmap at all. Leaning Next.js App Router on Vercel against the same
  Supabase project, for public invite links and a shareable read-only recipe
  page. Not decided in detail. Named here so the idea survives the roadmap
  entry that used to carry it.
- **Cross-family unit conversion** — deferred, see D9. `ingredients.density_g_per_ml`
  and `piece_weight_g` still exist and are still never populated. Phase 2 part 4
  shipped the shopping list without them, as D9 said it could: an ingredient
  measured both by mass and by volume in one week renders as two entries on one
  line, which is the documented behaviour, not a gap.
- **Handwritten card OCR quality** — unknown until there's a real card to test.
- **A model call has run, and the entry this replaces was wrong by the time
  it was read.** It used to say no model call had ever executed, for lack
  of Anthropic credit. Phase 1d part 6 ran all three importers against the
  real provider once credits existed (seven calls, $0.14, every one
  recorded in `ai_usage` with real token counts — `docs/ROADMAP.md`'s own
  part 6 notes), and Phase 3 part 3's emulator walk ran `translate-recipe`
  for real (`Palacinke` → `Pancakes`, then reviewed to `Crepes`). Left here
  as a reminder to re-read a claim like this before repeating it, not
  deleted outright.
- **The iOS share extension** — see the 1d notes in `docs/ROADMAP.md`. Android
  shares work; iOS needs a Share Extension target, an app group and
  entitlements. SPM is already enabled and the project uses the scene lifecycle,
  both of which matter to whoever does it.
- **Import photos are never pruned.** A completed or dismissed job leaves its
  object in `import-uploads`. Keeping it is deliberate — a failed job can be
  re-run against the same photograph — but nothing collects them. Belongs with
  Phase 2's Storage work, which has to think about lifecycle anyway.
- **`to_taste` is seeded as a unit but the parser never emits it** — see D31.
  Where recipes actually write `po ukusu`, at the end of a line, it is a note
  and an optional marker, which is what lets `so po ukusu` resolve to *so*.
  The unit code exists for imports that carry an explicit "to taste" field.
  Revisit if 1d's importers turn out to need it.
- **The GIN trigram index is not used by `search_ingredients`** — see D31.
  `similarity()` cannot use it; only the `%` operator can, and `%` was rejected.
  Irrelevant at a few hundred aliases. Revisit if the catalog reaches the tens
  of thousands, at which point the change is `set_limit()` plus dropping
  `STABLE`, not a new index.
- **Nothing notices a permanently-failing best-effort path** — see D47. Tier 4
  failed silently for three parts because the only symptom was a row that never
  appeared in `ai_usage`. Phase 2's admin screen already plans to show
  `match_method` distribution; a tier that stops appearing in it is the signal.
- **Phase 2's admin screen needs two grants that do not exist** — a read policy
  on `ingredient_merges` (D32 gives it none) and, if merges are to be triggered
  from the app, `grant execute on merge_ingredients to authenticated` (D30
  revokes it from all three client roles). Both are deliberate omissions, not
  oversights.
- **Auditable membership revocation** — see D24. Members can now be removed
  (D113, Phase 6 part 3b), and it stays deferred: `remove_household_member()`
  is still a hard delete with no trace. Likely answer is a
  `household_member_removals` log table written by that same RPC, not a
  schema change to `household_members` itself. Revisit if anyone actually
  asks "who removed whom."
- **Invite revocation** — closed by D114 (Phase 6 part 3b): `revoked_at`/
  `revoked_by`, the rebuilt partial index, and the `redeem-invite` guards it
  forced.
- **Invite redemption rate limiting** — see D26. Deferred deliberately, with
  the upgrade path named there.
- **Thumbnails on the week grid's own tiles, and copying or clearing a whole
  week** — see D53. The picker gets thumbnails for free from
  `_withImageUrls`; the grid's tiles deliberately do not, and no second
  caller needs it yet. Copying/clearing a week is where `meal_plans.deleted_at`
  gets its first human-triggered writer and D50's resurrection path gets
  exercised outside the SQL suite — still unbuilt after Phase 2 part 3, which
  closed the other three items this note used to list (leftover entries,
  the snack variety check, within-slot reordering — D55–D58).
- **The Drift cache and the offline signal are done; the admin screen is
  not.** See D64–D76. Phase 2 part 6a added the `last_sync_at`-style
  watermark D71 deferred (`SyncWatermarks`, D72) and used it to cache
  recipes and the global ingredient name catalog (D72–D74). Part 6b closed
  the last uncached entity — meal plans, household-scoped across every week
  rather than per week (D75) — and added the global offline banner
  alongside the shopping list's and meal plan's own "showing your saved
  copy" lines (D76), meeting Phase 2's offline Done-when in full. Still
  unbuilt: the admin screen's `match_method`/cache-health surfacing.
- **A generated list is never compared against the plan it came from** — see
  Phase 2 part 4's own closing note, unchanged by this part. Editing the week
  after generating still leaves a list that is quietly stale on the server
  side of the question; this part only made the *client* side of staleness
  (no connection, showing a saved copy) visible, which is a different
  question answered a different way.
- **D92's live failure-message walk closed in Phase 4 part 2**, on a
  physical Galaxy S25 rather than an emulator whose radio toggles never
  actually sever its route to the local stack. Real airplane mode
  (`adb shell svc wifi disable` + `svc data disable` -- Android 16's shell no
  longer permits the `AIRPLANE_MODE` broadcast) confirmed: the global offline
  banner and the shopping list's narrower "showing your saved copy" line
  both render, a write attempt against `save_imported_recipe` surfaces
  **"Nema veze sa internetom."** from a real `SocketException` rather than a
  generic error, and the banner clears on the next successful read after
  reconnecting, not on the radio event itself. A genuine Wi-Fi→cellular
  transition, which an emulator cannot produce at all, was exercised too.
  Closed.
