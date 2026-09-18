# Architecture

## Layers

Feature-first, three layers plus presentation. No exceptions.

```
lib/
  core/
    env/               # compile-time config, --dart-define
    supabase/          # client init only
    db/                # the Drift cache database, shared across features (D64)
    net/               # NetworkStatus -- reachability, derived from NetworkFailure (D67)
    router/            # go_router config, typed routes
    theme/
    text/              # TextNormalizer (mirrors Postgres normalize_text)
    ingredients/       # the catalog: providers + the line editor (D43)
    household/         # currentHouseholdIdProvider, closing D33 (D52)
    recipes/           # the meal plan's recipe picker, reading recipes/data/ (D53)
    l10n/              # ARB files, generated AppLocalizations, appLocaleProvider (D77)
    refresh/           # cross-feature "this changed" counters
    widgets/           # generic, feature-agnostic
  features/
    auth/
    households/
    recipes/
    ingredients/
    import/
    meal_plan/
    shopping_list/
```

Each feature:

```
features/recipes/
  data/
    recipe_repository.dart
    remote_recipe_datasource.dart      # Supabase
    local_recipe_datasource.dart       # Drift (Phase 2 part 6a) -- also the
                                        # ingredient name cache/sync, D73
    dto/                               # wire shapes, *_dto.dart
  domain/
    recipe.dart                        # freezed, pure Dart
    recipe_ingredient.dart
  application/
    recipe_providers.dart              # @riverpod
  presentation/
    recipe_list_screen.dart
    recipe_detail_screen.dart
    widgets/
```

`features/shopping_list/data/` is the first feature built this way (Phase 2
part 5) — `shopping_list_repository.dart` composes
`remote_shopping_list_datasource.dart` and `local_shopping_list_datasource.dart`
rather than talking to Supabase or Drift itself, and `dto/shopping_list_dto.dart`
is the shared wire decoder both halves read. `features/recipes/data/` is the
second (Phase 2 part 6a), with one addition D73 explains: its
`local_recipe_datasource.dart` also owns the global ingredient-name cache
and resolves `DisplayNameChain` against it, because that RPC has exactly one
caller and the layer boundary forbids putting it in
`features/ingredients/data/` without one. `features/meal_plan/data/` is the
third (Phase 2 part 6b), on the same shape. `features/households/data/` is
the fourth (Phase 2 part 7, D90) — taken for a different reason than the
first three: it is not about offline reading so much as about having a seam
to test a read order against at all, the gap D87 found. `features/ingredients/data/`
itself still caches only `fetchUnitCatalog()`, deliberately not split into a
full Remote/Local pair — see D70, and D90 for why that precedent did not
transfer to households.

### Dependency direction

```
presentation ──▶ application ──▶ data ──▶ (Supabase | Drift)
       │              │            │
       └──────────────┴────────────┴──▶ domain
```

- `domain/` imports nothing but `freezed` / `json_annotation`.
- `data/` is the only place `supabase_flutter` or `drift` may appear, except
  `supabase_flutter` may also appear in `core/supabase/` and `drift` may also
  appear in `core/db/` — each the one sanctioned place a client shared across
  features is allowed to live (D64).
- `presentation/` must never import `data/`.
- Cross-feature imports go through `domain/` only. `meal_plan` may import
  `recipes/domain/recipe.dart`. It may not import `recipes/data/...`.
- `core/` is outside that rule and may depend on features — the checker derives
  layer and feature from `lib/features/<x>/<layer>/` and nothing else. That is
  the sanctioned way to share: when a second feature needs something, it moves
  to `core/` rather than being duplicated or reached across (D43).

### Why this boundary specifically

It is the thing that makes the offline decision reversible. Adding a Drift cache
in Phase 2 is a change inside `recipe_repository.dart` if the boundary held, and
a month of surgery if a widget somewhere calls `supabase.from('recipes')`.

## State management

Riverpod with `riverpod_generator`. Providers are declared as annotated
functions or classes — never as bare `Provider` / `StateProvider` constructors.

```dart
@riverpod
RecipeRepository recipeRepository(Ref ref) =>
    RecipeRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<List<Recipe>> recipeList(Ref ref, {String? query}) =>
    ref.watch(recipeRepositoryProvider).search(query);

@riverpod
class RecipeDraft extends _$RecipeDraft {
  @override
  Recipe build(String recipeId) => ...;
  void updateTitle(String t) => state = state.copyWith(title: t);
}
```

Rules:

- Screens consume `AsyncValue` and handle all three states. No manual
  `isLoading` booleans.
- Repositories throw typed failures (`AppFailure` sealed class in
  `core/error/`). `PostgrestException` is caught and translated inside `data/`.
- `ref.invalidate()` for refresh. No global mutable singletons.
- `keepAlive` only where justified with a comment.

## Routing

`go_router` with `go_router_builder` typed routes. Route classes live in
`core/router/routes.dart`. Auth redirect is centralized there — no per-screen
auth checks.

Shell: bottom nav with Recipes / Plan / List / Settings.

## Client vs Edge Function

**Rule: an Edge Function exists if and only if it needs a secret, needs to be
trusted, or needs to be slow.**

Edge Functions:

| Function | Why |
|---|---|
| `import-url` | fetches third-party pages, then may call an LLM |
| `import-photo` | vision model, API key |
| `import-text` | LLM parse of pasted text |
| `match-ingredients` | LLM tier of matching; costs money and holds the key |
| `translate-recipe` | LLM, API key |
| `suggest-meals` | LLM, API key — not built, and no longer on the roadmap |
| `create-invite` / `redeem-invite` | must be trusted; writes membership |

Client (direct Supabase, protected by RLS):

- All plain CRUD on recipes, meal plans, households
- Search (including trigram / normalized search via RPC)
- Shopping list generation — pure aggregation over rows the client can already
  read. No secret, fast, easier to iterate on. Runs in Dart.
- Exact and fuzzy ingredient matching during manual entry, through the
  `search_ingredients` RPC. It is `security invoker`, so RLS scopes household
  aliases and no `household_id` is passed (D31)
- Ingredient line parsing (tier 1) — pure Dart, no database at all (D31)

Ambiguous cases and the call:

- **Shopping list aggregation → client.** Deterministic and offline-friendly.
- **Ingredient matching → split.** Exact/fuzzy tiers on the client for
  autocomplete responsiveness; the LLM tier server-side because it costs money
  and needs the model key. It does *not* write global alias rows: that moved to
  the confirm screen in 1d part 2, where a human has agreed (D42).
- **Invites → server.** Anything that grants access to household data is not
  client logic.

Shared server code lives in `supabase/functions/_shared/`:

```
_shared/
  http.ts        # CORS, the {error, message} envelope, the handler wrapper
  auth.ts        # resolve caller -> household, assert membership
  invite_code.ts # invite code generation and validation
  schema.ts      # Zod — the single definition of AI-facing shapes
  ai.ts          # model client, retry, JSON-mode helpers
  usage.ts       # checkQuota(householdId) + recordUsage(...)
  normalize.ts   # same normalization as Postgres/Dart (for matching)
  parse_line.ts  # same line parse as Dart, against the same fixture (D31)
  jobs.ts        # the import_jobs lifecycle, shared by all three importers
  match.ts       # tiers 1-4 over a whole recipe, in-process for the importers
  translate.ts   # translate-recipe's prompt and its thin callStructured wrapper
```

`jobs.ts` and `match.ts` were added in 1d part 2 and are not in the original
list. `match.ts` is in `_shared/` rather than inside `match-ingredients/`
because the importers need the pipeline in the same isolate — the alternative
was an HTTP hop from one function to a sibling, paying a round trip and a
second auth check to run code already loaded. `translate.ts` arrived in
Phase 3 part 2, on `read_recipe.ts`'s own precedent (itself missing from this
list, alongside `jsonld.ts` and `url_guard.ts` — this block has not tracked
every addition since 1d).

The first three exist as of Phase 1a; the other five arrived with Phase 1d
part 1. `normalize.ts` and `parse_line.ts` are each one side of a contract whose
other sides already existed — `test/fixtures/normalization.json` and
`test/fixtures/ingredient_lines.json`. Neither was written freehand; both are
ports, and `make test-functions` holds them to the same fixtures the Dart and
SQL sides are held to.

Every function runs **two clients**. A caller-scoped one, carrying the request's
`Authorization` header, does exactly one thing: `auth.getUser()`, which verifies
the JWT against the Auth server rather than trusting a locally decoded `sub`.
Everything else runs on a service-role client, which bypasses RLS — so every
query it issues must carry its own explicit predicate. The trust boundary is the
handler, not the database.

## Type flow

```
supabase/functions/_shared/schema.ts   (Zod, source of truth)
        │  z.toJSONSchema
        ▼
build/schema.json
        │  quicktype --lang dart --use-freezed
        ▼
lib/features/import/domain/parsed_recipe.dart
```

Run via `make types`, which is `tool/gen_types.ts` end to end. Never hand-edit
the generated Dart. If the AI parse contract changes, it changes in `schema.ts`
and nowhere else.

Two details the diagram does not show, both settled in 1d part 1. The first
step is Zod 4's own `z.toJSONSchema` rather than the `zod-to-json-schema`
package, which only existed because Zod 3 could not do it — same transformation,
one fewer dependency. And every schema carries an explicit `title`, because
quicktype otherwise names Dart classes after property names and produces
`Quantity` and `MatchMethod`, which collide with the real domain types in
`features/ingredients/domain/`.

## Offline (Phase 2)

Cache is not always cache-then-network. Drift is a cache, Supabase is the
truth, never the reverse, but the read order depends on whether staleness is
worth showing (D67, D74) — built in part 5 (D64–D71) on the shopping list and
the unit catalog, widened in part 6a (D72–D74) to recipes and the global
ingredient name catalog, in part 6b to meal plans, and in part 7 (D87–D90) to
the caller's own current household — the gate every one of those reads sat
behind, uncached and unbounded, until then.

```
ShoppingListRepository / RecipeRepository (list) / MealPlanRepository
  ├─ Remote*DataSource (Supabase)
  ├─ Local*DataSource  (Drift, core/db/)
  └─ watchLatest()/watchList()/watchWeek(): emit cached immediately → fetch → upsert cache → emit fresh

RecipeRepository.fetchDetail() / IngredientRepository.fetchUnitCatalog()
  └─ network-first; the cache is read only on a NetworkFailure (D70, D74)

HouseholdRepository.fetchCurrent()
  └─ network-first, D70's shape, PLUS a per-request bound: fetchMineRows()
     chains .retry(count: 1, requestTimeout: 5s) so the fallback below
     arrives in ~11s worst case rather than the several minutes an
     unbounded PostgREST call took before (D87, D89)
```

**Every household-scoped read above gates on `currentHouseholdIdProvider`
first** (`await ref.watch(currentHouseholdIdProvider.future)`), so until it
resolves, nothing below it — however well its own cache is populated — gets a
chance to answer. Part 7 closed the two things that made a cold, offline
start unrecoverable: `CurrentHouseholdCache` (`core/db/`), the first
per-user table this database has (keyed on the signed-in user's id, so a
wrong-user read is impossible by construction, not merely avoided), and the
per-request `.retry()` bound above, which is what actually shortens the wait
— a global `Supabase.initialize(postgrestOptions:)` timeout was tried first
and verified not to work: `SupabaseClient.from()` forwards only `schema`
from `PostgrestClientOptions`, never `requestTimeout` or `retryCount` (D89).
`features/households/data/` took the Remote/Local split to get there — the
fourth outing, after shopping_list/recipes/meal_plan — specifically so this
read order could be tested rather than only walked on the emulator (D90).

This was found, not designed for up front: the Phase 3 part 3 emulator walk
force-stopped the app offline and found the Recipes tab hanging for several
minutes before failing — for a recipe whose cache row was confirmed present
and correctly keyed by pulling the on-device SQLite file mid-walk. D87
records the finding; D88–D90 are the fix.

Part 6a also closed D71's own deferral: `SyncWatermarks` (`core/db/`) is a
per-`(entity, scope)` delta-fetch watermark, advanced from the max
`updated_at` of the rows a fetch actually received, never from the local
clock (D72). A missing watermark means "fetch everything" — a slower read,
never a wrong one. `scope` is a household id for household-scoped entities,
or `globalSyncScope` for reference data with none of its own — the
ingredient name catalog today.

Offline display-name resolution needed a second thing the shopping list
never did: `ingredient_display_name()`'s fallback chain, ported to Dart as
`DisplayNameChain` and held to the same shared-fixture discipline as
`normalize_text()`/`TextNormalizer` (rule 6, D72). Its cache and sync live
in `features/recipes/data/`, not `features/ingredients/data/`, because
`ingredient_display_names` has exactly one caller today and the layer
boundary (D33) forbids `recipes/data/` from reaching `ingredients/data/`
directly — D73 names the third-caller signal that would move it to
`core/ingredients/`, on D43's own precedent.

`AppDatabase` lives in `core/db/` (D64), not any one feature's `data/` — a
single SQLite file is inherently shared, and `tool/check_layers.dart`'s drift
rule allows it there on the same exemption `core/supabase/` has for
`supabase_flutter`.

Cache schema is deliberately not a mirror of Postgres. One row per entity with
a `data` JSON column plus extracted columns needed for querying — the exact
map a network response produces, not a rebuilt-and-re-serialized domain
object (D65). Mirroring the full relational schema locally is the maintenance
burden worth avoiding, and the columns a table extracts vary by what the
entity actually is: `ShoppingListCache` carries `householdId` and `updatedAt`
for a household-scoped snapshot; `UnitCatalogCache` carries neither, because
`units`/`unit_names` have no household and no `updated_at` to begin with.
`RecipeCache` and `IngredientNameCache` (part 6a) follow the same rule:
`householdId`/`updatedAt` on the former, a global scope and no household
column on the latter. `CurrentHouseholdCache` (part 7) extracts `userId`
instead of `householdId` — the one table in this file keyed by who is asking
rather than which household the answer belongs to, because the household id
itself is what's being resolved (D88).

**No `deleted_at` in the cache** (D68, a deliberate narrowing of the
original sketch above). A row a network read no longer returns is deleted
locally, not tombstoned — the cache's job is to answer "what would the
server show me right now", and a soft-deleted server row is never shown to
the UI in the first place (D23 keeps it visible to the *repository* only, so
a later delta fetch can evict it).

Delta fetch (`updated_at > last_sync_at` per table) is `SyncWatermarks`
(D72), built in part 6a once recipes gave the design something real to be
right about (D71 deferred it for exactly this reason). `AppDatabase
.schemaVersion` is `5` as of Phase 2 part 7 — `3` from part 6b's
`MealPlanWeekCache`, `4` from Phase 3 part 2's `recipe_translations` riding
inside `RecipeCache.data`'s existing blob (a shape change rather than a
column one, D78), `5` from part 7's `CurrentHouseholdCache` (D88).
`onUpgrade` still drops every table and recreates it rather than
migrating — the cache is disposable by
construction, so a schema change costs one refetch, not a migration.

A cache failure never fails the surrounding read or write (D69):
`cacheOrElse`/`cacheWrite` in `core/db/cache_guard.dart` log and fall back
rather than letting a drift exception reach `runGuarded`.

Writes are online-only and fail loudly with a "you're offline" message.
Reachability itself is `core/net/network_status.dart`'s `NetworkStatus`
(D67) — derived from the same `NetworkFailure` `runGuarded` already
produces, not a separate connectivity check (`connectivity_plus` was asked
about and rejected).

## Localization (Phase 3)

`profiles.locale` is the app's one locale — not a device setting, not a
local-only preference (D77). `core/l10n/app_locale.dart`'s `appLocaleProvider`
derives a `Locale` from it, falling back to Serbian whenever there is no
profile to read (signed out, or still loading), and `main.dart` feeds that
straight to `MaterialApp.router`'s `locale`. Writing a new value goes through
`AuthRepository.updateLocale`, a plain update — `profiles.locale`'s check
constraint and its `profiles_update_own` RLS policy have existed since
migration 2.

**Serbian is always `srLatn`, never a bare `Locale('sr')` (D91).** Verified
against the pinned SDK: `Locale('sr')` alone resolves Flutter's *own*
Material/Cupertino strings — the text-selection toolbar, the back-button
tooltip, a date-range picker's chrome — to their Cyrillic bundle, regardless
of how correct this app's own ARB strings are. `appLocaleProvider` returns
`Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn')`, and
`appSupportedLocales` (not the generated `AppLocalizations.supportedLocales`,
which still carries the scriptless entry) is what every `MaterialApp` —
`main.dart` and every widget test that pumps one directly — is built with.
`profiles.locale` keeps storing the bare code; every reader of
`appLocaleProvider` uses `.languageCode`, unaffected.

```
lib/core/l10n/
  arb/app_sr.arb        # template — CLAUDE.md's Serbian-first
  arb/app_en.arb
  generated/            # flutter gen-l10n output, committed like *.g.dart
  app_locale.dart        # appLocaleProvider, srLatn, appSupportedLocales
```

ARB strings cover the app's chrome (the bottom nav, each tab's own AppBar
title, Settings, sign-in — Phase 3 part 1) and, feature by
feature as each part reaches it, that feature's own screens: recipes and the
`core/` widgets it shares with other features (`core/ingredients/widgets/`,
`core/recipes/widgets/recipe_picker_sheet.dart`) as of part 4. Households and
import are still English, pending parts 5 and 6. Language names themselves
(*Srpski*, *English*) are never translated — a language's own name is not
chrome.

**The failure vocabulary (D92).** `AppFailure` (`core/error/app_failure.dart`,
pure Dart) carries a nullable `FailureCode` alongside its English `message`,
each of the seven sealed variants defaulting its own code the way it already
defaults its message. `core/error/failure_l10n.dart` — a sibling file, the
one allowed to import Flutter, on this file's own precedent — renders a
code through the ARB (`localizedFailureMessage`/`localizedErrorMessage`/the
`AppFailureL10n.localized` extension); a null code means the sentence in
`message` is server prose this client's vocabulary cannot cover (an
unbounded Postgres or GoTrue message, a handful of Edge Function slugs whose
specificity only the server has) and is shown verbatim. Every application/
data throw site and every presentation call site that renders a failure goes
through this — not scoped to one feature, since a code added by half the
app would leave "which codes exist" unanswerable from the code alone.
`test/core/supabase/supabase_failure_test.dart` parses every Edge Function
slug straight out of `supabase/functions/**/*.ts` and asserts
`supabase_failure.dart` has an arm for each, closing the file's own
long-standing claim that the two are "two ends of the same contract" with an
actual test rather than a comment.

`recipe_translations`, `translate-recipe` and the recipe detail screen's own
locale-aware read arrived in Phase 3 part 2; the review flow is part 3. A
recipe's *content* locale is resolved in exactly one place per concern, each
reading `profiles.locale` through `appLocaleProvider` rather than a second
notion of "what language": `RecipeDetail`'s own getters
(`displayTitle`/`displayDescription`/`displaySteps`, falling back to the
original whenever `recipe_translations` has no row for the reading locale)
decide which prose is on screen, and `ingredient_display_names`/
`DisplayNameChain` (unchanged, D1) decide which ingredient and unit names
are. Ingredient lines are never translated per recipe — sending them to
`translate-recipe` would ask a model to redo work the catalog already does
for free, which is D1's whole argument applied to a second feature.

That same rule extends one layer down in part 4: the sample hint in
`ingredient_line_field.dart`, the match chip's "No match"/suggestion labels,
and the ingredient picker's prompts are all looked up by the *recipe's* own
language (`lookupAppLocalizations(Locale(widget.locale))`), never the
reader's chrome locale — content that sits beside catalog names is never
translated per recipe either way. A failure message inside those same
widgets stays on the reader's chrome locale: content follows the recipe,
chrome and failures follow the reader.

## Environments (Phase 4)

Two environments, one codebase: the local Supabase stack and one hosted
project. They are not two configurations of the app — they are the same binary
handed a different `SUPABASE_URL` and anon key at compile time (D95).

```
env/local.json      make run           # the default; iOS and desktop
env/android.json    make run-android   # the same local stack, via 10.0.2.2
env/hosted.json     make run-hosted    # the hosted project
```

Nothing in `lib/` knows which one it got. There is no `isProduction`, no
environment enum, no branch on the URL — `core/env/Env` reads two strings and
`core/supabase/` hands them to `Supabase.initialize`. That is the whole
mechanism, and keeping it that small is the point: an environment the code can
detect is an environment the code will eventually behave differently in.

A release build is the one place this touches native config rather than
`lib/`. Android only merges `android/app/src/main/AndroidManifest.xml` into a
release APK, so `INTERNET` has to be declared there too — the debug and
profile manifests' copies are for the Flutter tool's own use (hot reload,
breakpoints) and never ship. Release signing reads `android/key.properties`
(gitignored; `android/key.properties.example` is the template) and falls
back to the debug keystore when that file is absent, so a fresh clone still
builds. `make install-hosted` does both steps — release APK against
`env/hosted.json`, installed on the attached device.

Everything else is shared and versioned:

- **One migration set.** `supabase/migrations/` is applied to local by
  `make db-reset` and to hosted by `make db-push`. The ingredient catalog rides
  along as generated migrations rather than `seed.sql` (D29), so a fresh hosted
  database comes up with the catalog already in it.
- **One `config.toml`.** Auth settings and email templates are pushed to hosted
  with `make config-push`, never edited in the dashboard. The dashboard has no
  history and no review; a settings change that only exists there is a change
  nobody can find later.
- **One set of Edge Functions**, deployed with `make functions-deploy`.

Sign-in is Google-only (D96). `google_sign_in` obtains an ID token natively and
hands it to `signInWithIdToken`, so there is no browser redirect to come back
from, nothing to register in `AndroidManifest.xml` on either platform, and
`site_url` / `additional_redirect_urls` stay untouched. Its client IDs are
committed constants rather than `env/*.json` keys — the one carve-out from
"env files carry only what differs" — because they are public and identical in
both environments (D98).

Email sign-in used to complicate this: a free tier project on the built-in
email sender rejects any email template, and the CLI sends `[auth]` as a
single payload, so the one template block that made a code readable in Mailpit
failed the entire push. `config.toml` carries no email template any more
(Phase 4 part 4), so `make config-push` pushes the whole `[auth]` block in one
shot — that history is why this section used to warn about it.

Do not resolve any auth drift by editing settings in the dashboard — that is
the thing `config push` exists to prevent.

Secrets split three ways, and the split is the rule that matters:

| Where | What | Why |
|---|---|---|
| `env/*.json` (gitignored) | URL + anon key | public by design, protected by RLS |
| Edge Function secrets | `ANTHROPIC_API_KEY` | never reaches the client (CLAUDE.md rule 2) |
| Password manager | DB password, service-role key | never in the repo at all |

`env/*.example.json` is committed and carries placeholders only. The
`SUPABASE_` prefix is reserved on the platform: `SUPABASE_URL`,
`SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected into deployed
functions automatically, and `supabase secrets set` rejects that prefix.

Where local and hosted genuinely need to differ, the difference goes in a
`[remotes.<alias>]` block in `config.toml` rather than in the dashboard — the
CLI merges it over the base config for that project ref only. There is exactly
one today: `max_frequency`, which is `"1s"` locally so a reset-and-retry loop is
not spent waiting, and `"1m0s"` on hosted so it does not inherit that
convenience if anything ever does send mail.

`config push` replaces the *whole* remote `[auth]` block, not just the keys you
changed, so read its diff before confirming — `make config-push` prints it.

## Enforcement

Conventions in a document get ignored around session forty. These fail the build:

- `analysis_options.yaml`: `strict-casts: true`, `strict-raw-types: true`,
  `strict-inference: true`, selected lints as errors
- `riverpod_lint` declared in the `plugins:` block of `analysis_options.yaml`.
  Its rules run under plain `dart analyze` — there is no separate lint command,
  and `custom_lint` is deliberately not a dependency (D20).
- Import boundary check: a `tool/check_layers.dart` script that fails if
  `presentation/` imports `data/`, or if `supabase_flutter` appears outside
  `data/` and `core/supabase/`. Run in CI and pre-commit. It also enforces the
  rest of rule 1 — `drift` confined to `data/` and `core/db/` (D64), no
  Flutter imports in `domain/`, cross-feature imports through `domain/` only,
  and no raw maps or Postgrest/Auth exceptions escaping `data/` (D21 exempts
  `fromJson`/`toJson`).
  `test/tool/check_layers_test.dart` plants each violation and asserts the
  checker rejects it.
- `dart analyze` must be clean before any commit.

## Deliberately not built

- No `BaseRepository<T>` — every session would extend it differently.
- No use-case/interactor class per operation. Providers calling repositories is
  enough structure for one person.
- No dependency injection framework beyond Riverpod.
- No Realtime, no presence, no conflict resolution.
- No web layer.
