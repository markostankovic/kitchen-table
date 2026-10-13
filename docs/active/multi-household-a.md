# Slice: multi-household-a — Edge Functions take an explicit household

## Goal
First of three slices that let one account belong to several households
(B: client selection + switching, C: UI from a Claude Design round, brief at
`docs/design/BRIEF_multiple_households.md`). This slice removes every
"oldest household wins" pick on the **request path to Edge Functions**: the
five functions that today resolve the household from the caller's oldest
membership take a `householdId` in the body instead, checked with the
existing `assertMember`. The client sends the id it already uses everywhere
else (`currentHouseholdIdProvider`, or the household being shown). Nothing
user-visible changes; with one household per user the behaviour is identical.
`redeem-invite`'s `already_in_household` guard **stays** — dropping it is
slice B, once the client can choose.

## Constraints already resolved (do not re-derive)
- **Transitional fallback (new decision, D168).** A request *without*
  `householdId` falls back to the existing `resolveHousehold()` (oldest
  membership), so an APK already installed on a family phone keeps working
  after the functions deploy, whichever ships first. A request *with* one is
  checked by `assertMember` and never falls back. `resolveHousehold`'s doc
  comment becomes "legacy fallback for clients that send no `householdId`;
  delete in slice B". Do not delete it here.
- **"The client may not name a household it doesn't belong to"** — the
  reason create-invite / import-text / translate-tags give in their header
  comments for resolving server-side. `assertMember` (403 `not_a_member`) is
  what now upholds it; rewrite those header comments to say so rather than
  deleting the principle.
- **D31** — functions run reads on the service client (bypasses RLS), so
  every query carries its own predicate. The membership check is the trust
  boundary; it must happen before quota, job row, or any read keyed on the id.
- **D46** — the `import-uploads` bucket's policies read the
  `{household_id}/` path prefix through `is_household_member`. import-photo
  keeps its prefix check, now against the requested-and-verified id.
- **D52** — `currentHouseholdIdProvider` (`lib/core/household/current_household.dart`)
  is the one client-side "which household". Do not add another query for it.
  `ImportRepository.uploadImportPhoto` currently has its *own* oldest-household
  query (`households … order('created_at').limit(1)`) — a missed copy;
  remove it.
- **D109** — `translateTagsBestEffort` is fired unawaited from
  `RecipeEditor.save()` and must never throw. Keep that.
- **D107** — tag names are one row per `(tag_key, locale, household)`; the
  household translate-tags works on must be the saved recipe's.
- **CLAUDE.md rule 1** — Supabase stays in `data/`. Repositories take the id
  as a parameter; callers in `application/` / `presentation/` read the
  provider (precedent: `recipe_editor.dart:190`).
- **CLAUDE.md rule 2** — unchanged: the functions still hold the keys.
- Bodies stay hand-built camelCase (`householdId`), on `ImportRepository`'s
  convention for Edge Function bodies — not Zod/`make types`.

## Files to touch

Server (`supabase/functions/`):
- `_shared/http.ts` — add `readOptionalJsonBody(req)`: empty body → `{}`,
  otherwise the same checks as `readJsonBody`. Needed because create-invite
  and translate-tags take no body today and old clients still send none.
- `_shared/auth.ts` — add
  `requireHousehold(service, userId, body): Promise<{ householdId; role }>`:
  - `body.householdId` absent/undefined → `resolveHousehold` (legacy); null
    result → 404 `no_household` (the message the functions use today).
  - present but not a UUID-shaped string → 400 `invalid_household`.
  - otherwise `assertMember` → `{ householdId, role }`.
  Update `resolveHousehold`'s doc comment (see D168 above; its "revisit both
  together" note is the reason this slice exists).
- `_shared/auth_test.ts` (new) — `requireHousehold` with a minimal fake
  `SupabaseClient` covering the `.from().select().eq()….maybeSingle()` chain:
  member → returns id/role; non-member → 403 `not_a_member`; malformed id →
  400; absent id → legacy path (oldest); absent id + no membership → 404.
  Plus `readOptionalJsonBody`: empty → `{}`, array → 400.
- `import-text/index.ts`, `import-url/index.ts`, `import-photo/index.ts` —
  read the body first, then `requireHousehold(service, userId, body)` in place
  of `resolveHousehold`; everything after uses its `householdId`. import-photo
  keeps `prefix !== householdId` → 400 `invalid_storage_path`.
- `create-invite/index.ts`, `translate-tags/index.ts` —
  `readOptionalJsonBody` then `requireHousehold`. Header comments updated.

Client (`lib/`):
- `features/import/data/import_repository.dart` — `createFromText`,
  `createFromUrl`, `createFromPhoto` take `{required String householdId}` and
  send it; `uploadImportPhoto` takes it too and drops its own households
  query. Update the library doc ("no household lookup") to describe the new
  shape.
- `features/import/presentation/import_paste_screen.dart`,
  `import_url_screen.dart`, `import_photo_screen.dart` — read
  `currentHouseholdIdProvider.future`; null → the existing
  `NotFoundFailure(code: FailureCode.noHousehold)` path the screens already
  render. Photo screen reads it once and passes it to both upload and create.
- `features/recipes/data/remote_recipe_datasource.dart` — `translateTags(String householdId)`
  sends `{'householdId': …}`; doc comment updated.
- `features/recipes/data/recipe_repository.dart` —
  `translateTagsBestEffort(String householdId)`.
- `features/recipes/application/recipe_editor.dart` — pass
  `saved.householdId` (the saved recipe's own household, D107).
- `features/households/data/remote_household_datasource.dart` +
  `household_repository.dart` — `createInvite(String householdId)`.
- `features/households/presentation/household_screen.dart` — pass the shown
  household's id (`h.id`), not the provider's: in slice C the managed
  household may not be the selected one.
- Tests' fakes: `test/features/households/household_screen_test.dart`,
  `household_repository_offline_test.dart`,
  `test/features/recipes/recipe_repository_offline_test.dart` — update
  signatures; assert the id is forwarded where a fake can record it.

## Pattern to follow
`supabase/functions/_shared/jobs.ts` `loadJobForCaller` (≈ line 116): take an
id, check it with `assertMember` on the service client, then proceed — that is
exactly the new `requireHousehold`. Client side, `recipe_editor.dart` ≈ line
188 is the pattern for reading `currentHouseholdIdProvider.future` and
throwing `noHousehold` on null.

## Acceptance
- `make check` clean (except the known `seed-check` red on main). That covers
  `lint-functions` (deno check/lint/fmt) and `test-functions`, which now
  includes `auth_test.ts`.
- `dart analyze` clean, `flutter test` green.
- `grep -rn "resolveHousehold" supabase/functions` shows only `auth.ts`
  (definition + `requireHousehold`'s legacy branch).
- `grep -rn "order('created_at')" lib/features/import` returns nothing.
- `Makefile`'s `functions-deploy` target omits `translate-tags` (it lists
  create-invite, redeem-invite, import-text/url/photo, match-ingredients,
  translate-recipe). Add it. Then deploy to hosted (`make functions-deploy`),
  then `make install-hosted` and on the device:
  paste, URL and photo imports each produce a job; saving a recipe with a new
  tag still pairs it; creating an invite code works. Before installing the
  new APK, confirm the *old* installed build still imports (legacy path).

## To record on completion
New phase journal — this is not part of Phase 8's design round; `/close-slice`
starts `docs/journal/phase-9.md` ("multiple households") unless STATE says
otherwise. New decision **D168**: explicit `householdId` on Edge Function
bodies, checked by `assertMember`, with a legacy `resolveHousehold` fallback
for bodies without one, to be removed in slice B. `docs/STATE.md`'s Next:
slice B (client selection + switching, drops `already_in_household`) and the
design brief awaiting Claude Design.
