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
`features/ingredients/data/` without one. `features/ingredients/data/`
itself still caches only `fetchUnitCatalog()`, deliberately not split into a
full Remote/Local pair — see D70.

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
| `suggest-meals` | LLM, API key (Phase 4) |
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
```

`jobs.ts` and `match.ts` were added in 1d part 2 and are not in the original
list. `match.ts` is in `_shared/` rather than inside `match-ingredients/`
because the importers need the pipeline in the same isolate — the alternative
was an HTTP hop from one function to a sibling, paying a round trip and a
second auth check to run code already loaded.

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
ingredient name catalog. Meal plans are the one entity still uncached.

```
ShoppingListRepository / RecipeRepository (list)
  ├─ Remote*DataSource (Supabase)
  ├─ Local*DataSource  (Drift, core/db/)
  └─ watchLatest()/watchList(): emit cached immediately → fetch → upsert cache → emit fresh

RecipeRepository.fetchDetail() / IngredientRepository.fetchUnitCatalog()
  └─ network-first; the cache is read only on a NetworkFailure (D70, D74)
```

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
column on the latter.

**No `deleted_at` in the cache** (D68, a deliberate narrowing of the
original sketch above). A row a network read no longer returns is deleted
locally, not tombstoned — the cache's job is to answer "what would the
server show me right now", and a soft-deleted server row is never shown to
the UI in the first place (D23 keeps it visible to the *repository* only, so
a later delta fetch can evict it).

Delta fetch (`updated_at > last_sync_at` per table) is `SyncWatermarks`
(D72), built in part 6a once recipes gave the design something real to be
right about (D71 deferred it for exactly this reason). `AppDatabase
.schemaVersion` is `2` as of part 6a; `onUpgrade` still drops every table
and recreates it rather than migrating — the cache is disposable by
construction, so a schema change costs one refetch, not a migration.

A cache failure never fails the surrounding read or write (D69):
`cacheOrElse`/`cacheWrite` in `core/db/cache_guard.dart` log and fall back
rather than letting a drift exception reach `runGuarded`.

Writes are online-only and fail loudly with a "you're offline" message.
Reachability itself is `core/net/network_status.dart`'s `NetworkStatus`
(D67) — derived from the same `NetworkFailure` `runGuarded` already
produces, not a separate connectivity check (`connectivity_plus` was asked
about and rejected).

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
- No web layer until Phase 4.
