# Architecture

## Layers

Feature-first, three layers plus presentation. No exceptions.

```
lib/
  core/
    env/               # compile-time config, --dart-define
    supabase/          # client init only
    router/            # go_router config, typed routes
    theme/
    text/              # TextNormalizer (mirrors Postgres normalize_text)
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
    local_recipe_datasource.dart       # Drift (Phase 2)
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

### Dependency direction

```
presentation ──▶ application ──▶ data ──▶ (Supabase | Drift)
       │              │            │
       └──────────────┴────────────┴──▶ domain
```

- `domain/` imports nothing but `freezed` / `json_annotation`.
- `data/` is the only place `supabase_flutter` or `drift` may appear.
- `presentation/` must never import `data/`.
- Cross-feature imports go through `domain/` only. `meal_plan` may import
  `recipes/domain/recipe.dart`. It may not import `recipes/data/...`.

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
| `match-ingredients` | LLM tier of matching; writes global alias rows |
| `translate-recipe` | LLM, API key |
| `suggest-meals` | LLM, API key (Phase 4) |
| `create-invite` / `redeem-invite` | must be trusted; writes membership |

Client (direct Supabase, protected by RLS):

- All plain CRUD on recipes, meal plans, households
- Search (including trigram / normalized search via RPC)
- Shopping list generation — pure aggregation over rows the client can already
  read. No secret, fast, easier to iterate on. Runs in Dart.
- Exact and alias-tier ingredient matching during manual entry (autocomplete
  queries `ingredient_names` directly)

Ambiguous cases and the call:

- **Shopping list aggregation → client.** Deterministic and offline-friendly.
- **Ingredient matching → split.** Exact/fuzzy tiers on the client for
  autocomplete responsiveness; the LLM tier server-side because it writes
  global rows and costs money.
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
```

The first three exist as of Phase 1a; the rest arrive with Phase 1d.

Every function runs **two clients**. A caller-scoped one, carrying the request's
`Authorization` header, does exactly one thing: `auth.getUser()`, which verifies
the JWT against the Auth server rather than trusting a locally decoded `sub`.
Everything else runs on a service-role client, which bypasses RLS — so every
query it issues must carry its own explicit predicate. The trust boundary is the
handler, not the database.

## Type flow

```
supabase/functions/_shared/schema.ts   (Zod, source of truth)
        │  zod-to-json-schema
        ▼
build/schema.json
        │  quicktype --lang dart --freezed
        ▼
lib/features/import/domain/parsed_recipe.dart
```

Run via `make types`. Never hand-edit the generated Dart. If the AI parse
contract changes, it changes in `schema.ts` and nowhere else.

## Offline (Phase 2)

Cache-then-network reads only. Drift is a cache, Supabase is the truth, never
the reverse.

```
RecipeRepository
  ├─ RemoteRecipeDataSource (Supabase)
  ├─ LocalRecipeDataSource  (Drift)
  └─ watch(): emit cached immediately → fetch → upsert cache → emit fresh
```

Cache schema is deliberately not a mirror of Postgres. One row per entity with
a `data` JSON column plus extracted columns needed for querying
(`title_normalized`, `household_id`, `updated_at`, `deleted_at`). Mirroring the
full relational schema locally is the maintenance burden worth avoiding.

Delta fetch uses `updated_at > last_sync_at` per table, with `deleted_at` rows
removing entries from the cache. Both columns exist from migration 1 for
exactly this reason.

Writes are online-only and fail loudly with a "you're offline" message.

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
  rest of rule 1 — `drift` confined to `data/`, no Flutter imports in
  `domain/`, cross-feature imports through `domain/` only, and no raw maps or
  Postgrest/Auth exceptions escaping `data/` (D21 exempts `fromJson`/`toJson`).
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
