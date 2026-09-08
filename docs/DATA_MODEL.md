# Data model

Reference schema. Written as illustrative SQL — turn it into real numbered
migrations, don't paste it as one file.

Conventions everywhere:
- `id uuid primary key default gen_random_uuid()`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()` maintained by trigger
- `deleted_at timestamptz` on every household-scoped table; **never hard delete**

Extensions: `pg_trgm` only. **`unaccent` is deliberately not installed** — it
maps đ→d, and it is `STABLE` rather than `IMMUTABLE` so it cannot back a
generated column at all. See D19.

---

## Normalization

One function, used by generated columns and by search. Must match
`TextNormalizer` in Dart exactly.

**The implementation lives in `supabase/migrations/20260904210716_init.sql`.**
That file is the definition; this section is the spec it satisfies. An earlier
draft of this document carried an illustrative SQL body — it has been removed
because it did not compile and contradicted D5 (it mapped Latin đ→d via
`translate`, which is 1:1 and cannot emit two characters).

The algorithm, in this order:

1. lowercase
2. Cyrillic → Latin, **digraphs first** — `њ→nj`, `љ→lj`, `џ→dz`, `ђ→dj`,
   `ћ→c`, `ж→z` — then the 1:1 map
   `абвгдезијклмнопрстуфхцчш` → `abvgdezijklmnoprstufhccs`
3. Latin diacritics — `č→c`, `ć→c`, `š→s`, `ž→z`, and **`đ→dj` via `replace`**,
   since it is two characters and cannot ride in `translate`
4. collapse whitespace, trim

Punctuation is deliberately preserved: the ingredient line parser already
splits notes off at the first comma.

`test/fixtures/normalization.json` is the contract, and it is the *only* place
the cases are written down. `tool/gen_normalization_sql.dart` generates
`supabase/tests/normalization_test.sql` from it, so the Postgres and Dart sides
are asserted against the same list. Run both with `make test-sql` and
`flutter test`.

> **Changing `normalize_text` requires a migration that also rebuilds every
> generated column derived from it.** Postgres accepts `CREATE OR REPLACE` on
> the function without recomputing stored generated columns, so the data goes
> stale silently and search starts missing rows that used to match.

---

## Identity and households

```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  locale text not null default 'sr' check (locale in ('sr','en')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table household_members (
  household_id uuid not null references households(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role text not null check (role in ('owner','adult')),
  created_at timestamptz not null default now(),
  primary key (household_id, user_id)
);

create table household_invites (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  code char(6) not null,                    -- digits, for typing
  token uuid not null default gen_random_uuid(),  -- for links
  created_by uuid not null references profiles(id),
  expires_at timestamptz not null,
  used_by uuid references profiles(id),
  used_at timestamptz,
  created_at timestamptz not null default now()
);
create unique index on household_invites (code) where used_at is null;
```

Invites are created and redeemed **only** through Edge Functions. The client
never writes `household_members`.

### RLS pattern

Membership checks must not recurse. Use a `security definer` helper:

```sql
create or replace function is_household_member(hid uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from household_members
    where household_id = hid and user_id = auth.uid()
  );
$$;
```

Then every household-scoped table gets the same policies. **Membership only —
no `deleted_at` clause** (D23): the Phase 2 delta fetch needs to see tombstones
in order to evict them from the cache, so soft-deleted rows are filtered in
`data/`, not here.

```sql
alter table recipes enable row level security;

create policy recipes_select on recipes for select
  using (is_household_member(household_id));
create policy recipes_insert on recipes for insert
  with check (is_household_member(household_id));
create policy recipes_update on recipes for update
  using (is_household_member(household_id));
-- no delete policy: soft delete via update only
```

Child tables (`recipe_ingredients`, `recipe_steps`, `meal_plan_entries`, …)
check membership through their parent with an `exists` subquery.

---

## Ingredient catalog

```sql
create table ingredients (
  id uuid primary key default gen_random_uuid(),
  key text unique                                -- curated seed key (D27)
    check (key is null or key ~ '^[a-z][a-z0-9_]*$'),
  parent_id uuid references ingredients(id),     -- ONE level only (D3)
  category text,                                 -- nullable; aisle grouping later
  default_unit_family text                       -- mass | volume | count
    check (default_unit_family in ('mass','volume','count')),
  is_verified boolean not null default false,    -- false = auto-created tail
  is_pantry_staple boolean not null default false,
  density_g_per_ml numeric,                      -- nullable, deferred (D9)
  piece_weight_g numeric,                        -- nullable, deferred
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table ingredient_names (
  id uuid primary key default gen_random_uuid(),
  ingredient_id uuid not null references ingredients(id) on delete cascade,
  name text not null,
  normalized_name text generated always as (normalize_text(name)) stored,
  locale text not null check (locale in ('sr','en')),
  is_display_name boolean not null default false,
  household_id uuid references households(id) on delete cascade, -- null = global
  source text not null check (source in ('curated','llm','user')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),  -- D28
  deleted_at timestamptz                          -- D28
);

-- Deliberately TOTAL, not partial on `deleted_at is null` (D28). One string
-- resolves to exactly ONE ingredient per locale and scope, globally and
-- forever. Re-seeding a retired alias resurrects and repoints this row rather
-- than creating a second one for the same string.
create unique index ingredient_names_unique
  on ingredient_names (normalized_name, locale, coalesce(household_id, '00000000-0000-0000-0000-000000000000'::uuid));

create index ingredient_names_trgm
  on ingredient_names using gin (normalized_name gin_trgm_ops);

create unique index one_display_name_per_locale
  on ingredient_names (ingredient_id, locale)
  where is_display_name and household_id is null and deleted_at is null;
```

`ingredients` and global `ingredient_names` are readable by all authenticated
users. **In Phase 1b there is no client write path at all** — no INSERT, UPDATE
or DELETE policy on any catalog table, deliberately (D32). Household-scoped
`ingredient_names` rows are *readable* under the normal membership policy; the
write path for them belongs to a later "we call it X in this house" feature
that does not exist. Phase 1c adds a narrow `SECURITY DEFINER` RPC for
"create a new ingredient" rather than a broad INSERT policy.

### Merge

Build this on day one. Duplicates will happen constantly and merging must be
routine, not a migration.

```sql
create table ingredient_merges (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null,
  target_id uuid not null,
  merged_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- merge_ingredients(source_ingredient uuid, target_ingredient uuid,
--                    actor uuid default auth.uid()) returns void
--
-- Implemented in supabase/migrations/*_merge_ingredients.sql. The parameters
-- are NOT named `source` / `target`: `source` is also a column of
-- ingredient_names, and a plpgsql parameter sharing a name with a column in
-- the same statement is an ambiguity error (D30).
--
--   1. guards: distinct, both live, and D3 -- refuse a merge that would make
--      a grandchild
--   2. repoint recipe_ingredients and shopping_list_items, each behind a
--      to_regclass() guard, since neither exists before 1c / Phase 2 (D30)
--   3. household_pantry_prefs: delete the source rows that would violate its
--      (household_id, ingredient_id) primary key, then repoint the rest
--   4. re-parent the source's children onto the target
--   5. ingredient_names: demote the source's display name where the target
--      already has one for that locale, then repoint. NOTHING IS DELETED --
--      per D28's total unique index two ingredients cannot share an alias, so
--      a merge cannot produce a duplicate name row and the "drop the
--      duplicate" step an earlier draft of this document described is
--      unreachable
--   6. soft-delete the source (keeping its key, or the next seed run would
--      resurrect it) and insert the ingredient_merges row
--
-- revoke execute from public, anon AND authenticated -- all three. Supabase
-- grants EXECUTE to anon and authenticated by default privileges, so revoking
-- PUBLIC alone leaves it callable by any signed-in user (D30).
```

---

## Units

```sql
create table units (
  code text primary key,               -- 'g','kg','ml','l','tsp','tbsp','cup','kom'
  family text not null check (family in ('mass','volume','count','other')),
  to_base numeric not null,            -- to g / ml / piece
  is_metric boolean not null default true
);

create table unit_names (
  id uuid primary key default gen_random_uuid(),
  unit_code text not null references units(code),
  locale text not null check (locale in ('sr','en')),
  name text not null,
  normalized_name text generated always as (normalize_text(name)) stored,
  is_display_name boolean not null default false
);

-- The load-bearing one: without it `kš` could resolve to both tsp and tbsp and
-- the parser would take whichever row came back first -- a wrong unit that
-- renders as a confident number. Rule 3 prefers no unit and the raw line.
create unique index unit_names_normalized_locale_idx
  on unit_names (normalized_name, locale);

create unique index unit_names_one_display_per_locale_idx
  on unit_names (unit_code, locale) where is_display_name;
```

`units` and `unit_names` get neither `deleted_at` nor `updated_at`: no
`household_id` (D24), two dozen immutable reference rows that only a migration
writes, refetched wholesale and cached for a session.

Seeded inline by the catalog migration, 22 units and ~120 names. Beyond the
list above: `mg`, `oz`, `lb`, `fl_oz` for Phase 1d's English web imports, and
the count units Serbian recipes actually use — `clove` (čen), `head` (glavica),
`bunch` (veza), `slice` (kriška), `sachet` (kesica), `can` (konzerva).

Two judgement calls worth keeping:

- **`glass` (čaša, 200 ml) is its own unit, not an alias of `cup`** (šolja,
  240 ml). Aliasing them silently loses 40 ml in every shopping-list sum.
- **`k.` and `kaš.` are deliberately not seeded**, though
  `docs/INGREDIENTS.md` lists them under *kašika*. `k.` reads equally as kom or
  kg. A confidently wrong unit is worse than the null unit rule 3 supports.
  `kš` is unambiguous and is seeded.

`test/fixtures/unit_aliases.json` is the contract between the Dart parser and
this table: `tool/gen_unit_alias_sql.dart` turns it into a SQL test asserting
every spelling exists and that none resolves to two different units.

---

## Catalog functions

Built in Phase 1b. Signatures as implemented, not as sketched.

```sql
-- Tiers 2 and 3 of the matcher (D31). One row per ingredient, best match
-- first. security invoker, so RLS scopes household aliases and there is no
-- household_id parameter.
search_ingredients(search_query text,
                   preferred_locale text default 'sr',
                   max_results int default 20)
  returns table (ingredient_id uuid, display_name text, matched_name text,
                 matched_locale text, is_verified boolean,
                 is_household_alias boolean, match_method text,
                 match_confidence numeric, auto_accept boolean)

-- The display-name fallback chain, defined once: requested locale's display
-- name, then any display name, then any name. Global rows only.
ingredient_display_name(iid uuid, loc text default 'sr') returns text

-- See the Merge section above. Operator only.
merge_ingredients(source_ingredient uuid, target_ingredient uuid,
                  actor uuid default auth.uid()) returns void
```

Added in Phase 1c. The catalog's only client write path (D34), plus the set
wrapper the recipe read path needs (D36's migration).

```sql
-- The set form of ingredient_display_name, so recipe detail resolves every
-- matched line in one round trip and the fallback chain keeps one definition.
ingredient_display_names(ids uuid[], loc text default 'sr')
  returns table (ingredient_id uuid, display_name text)

-- "Create a new ingredient" from the line editor. Returns the id of the
-- ingredient that already answers to the string rather than making a second
-- one; that guard is why this is a function and not an INSERT policy.
-- security definer. Locale-scoped only, deliberately (D34).
create_ingredient(ingredient_name text,
                  loc text default 'sr',
                  unit_family text default null) returns uuid

-- Tier-2 write-back on a human decision (D8). Global rows, never
-- household-scoped. Returns FALSE, without raising, when the string is
-- already a live alias for a different ingredient.
link_ingredient_alias(ingredient uuid, alias_name text,
                      loc text default 'sr') returns boolean

-- Replaces a recipe's ingredient lines and steps in one transaction and
-- touches the parent's updated_at. security invoker -- RLS still decides.
-- position comes from array order, not from the JSON (D36).
replace_recipe_lines(recipe uuid,
                     ingredient_lines jsonb default '[]'::jsonb,
                     steps jsonb default '[]'::jsonb) returns void
```

`match_method` is `exact` (the ingredient's display name matched), `alias`
(any other spelling or translation matched), or `fuzzy`. `auto_accept` applies
the 0.75 line from `docs/INGREDIENTS.md` server-side, so no client holds a copy
of that constant (D31).

The three matcher constants — the four-character floor before fuzzy fires, the
0.4 similarity threshold, and 0.75 — exist **only** inside
`search_ingredients`. Do not reintroduce any of them in Dart.

---

## Recipes

```sql
create table recipes (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  title text not null,
  title_normalized text generated always as (normalize_text(title)) stored,
  description text,
  servings int,
  prep_minutes int,
  cook_minutes int,
  original_locale text not null check (original_locale in ('sr','en')),
  source_type text not null
    check (source_type in ('manual','url_import','ocr','ai_generated')),
  source_url text,
  source_attribution text,          -- book title, page, author
  status text not null default 'draft' check (status in ('draft','tested')),
  visibility text not null default 'household'
    check (visibility in ('household')),   -- D16: no public path, yet
  image_path text,                  -- Supabase Storage
  tags text[] not null default '{}',
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index on recipes using gin (title_normalized gin_trgm_ops);

create table recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  position int not null,
  section text,                     -- 'Za fil', 'For the sauce'
  raw_text text not null,           -- HARD RULE: always populated
  ingredient_id uuid references ingredients(id),
  qty_num int,                      -- fractions, never floats (D-rule 5)
  qty_den int check (qty_den is null or qty_den > 0),
  qty_max_num int,                  -- ranges: 2-3 eggs
  qty_max_den int,
  unit_code text references units(code),
  note text,                        -- 'sitno seckan', 'room temperature'
  is_optional boolean not null default false,
  match_method text check (match_method in ('exact','alias','fuzzy','llm','manual')),
  match_confidence numeric,
  matched_at timestamptz
);
create index on recipe_ingredients (recipe_id, position);
create index on recipe_ingredients (ingredient_id);

create table recipe_steps (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  position int not null,
  text text not null,
  timer_seconds int
);

create table recipe_translations (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  locale text not null check (locale in ('sr','en')),
  title text not null,
  description text,
  steps jsonb not null default '[]',   -- [{position, text}]
  is_machine_generated boolean not null default true,
  reviewed_by uuid references profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (recipe_id, locale)
);
```

Note: `recipes` holds the original-language text; `recipe_translations` holds
every other locale. Ingredient lines are **not** translated per recipe — they
render from the catalog, which is the whole point of D1.

---

## Meal planning

```sql
create table meal_plans (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  week_start date not null,            -- Monday
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (household_id, week_start)
);

create table meal_plan_entries (
  id uuid primary key default gen_random_uuid(),
  meal_plan_id uuid not null references meal_plans(id) on delete cascade,
  entry_date date not null,
  slot text not null check (slot in ('breakfast','lunch','dinner','snack')),
  position int not null default 0,
  entry_kind text not null check (entry_kind in ('recipe','leftover','note')),
  recipe_id uuid references recipes(id),
  leftover_of_entry_id uuid references meal_plan_entries(id),
  note text,
  servings int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (entry_kind = 'recipe'   and recipe_id is not null) or
    (entry_kind = 'leftover' and leftover_of_entry_id is not null) or
    (entry_kind = 'note'     and note is not null)
  )
);
create index on meal_plan_entries (meal_plan_id, entry_date, slot);
```

Leftover entries point at the entry they came from, so the shopping list can
skip them (no ingredients bought twice) and the variety check can still see
what was eaten.

**Variety check** is a client-side query, not a table: for a candidate recipe in
a `snack` slot, count entries for the same `recipe_id` in that slot across the
last N days (default 14). Warn above a threshold (default 2).

---

## Shopping list

Generate-and-view (D13). A snapshot, not a live document.

```sql
create table shopping_lists (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  meal_plan_id uuid references meal_plans(id),
  date_from date not null,
  date_to date not null,
  locale text not null check (locale in ('sr','en')),
  generated_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  deleted_at timestamptz
);

create table shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references shopping_lists(id) on delete cascade,
  ingredient_id uuid references ingredients(id),
  display_name text not null,            -- resolved at generation time
  category text,
  position int not null default 0,
  is_pantry_staple boolean not null default false,
  quantities jsonb not null default '[]',
  -- [{ family:'mass', amount: 800, unit:'g' },
  --  { family:'volume', amount: 480, unit:'ml' }]
  unmatched_lines jsonb not null default '[]'  -- raw_text with no ingredient_id
);
```

Aggregation runs on the client (see ARCHITECTURE, client/edge split):

1. Collect `recipe_ingredients` for every non-leftover entry in range.
2. Scale by `servings` where set.
3. Group by `ingredient_id`; lines without one group by `normalize_text(raw_text)`.
4. Within each group, convert to base unit per family and sum. Across families,
   keep separate entries in `quantities` (D9).
5. Mark items where the ingredient is a pantry staple globally, unless a
   household override says otherwise.

```sql
create table household_pantry_prefs (
  household_id uuid not null references households(id) on delete cascade,
  ingredient_id uuid not null references ingredients(id) on delete cascade,
  always_have boolean not null,          -- overrides the global flag both ways
  primary key (household_id, ingredient_id)
);
```

---

## Import jobs

```sql
create table import_jobs (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  created_by uuid not null references profiles(id),
  kind text not null check (kind in ('url','photo','text')),
  input_url text,
  input_storage_path text,               -- for photos
  input_text text,
  status text not null default 'queued'
    check (status in ('queued','processing','needs_review','failed','done')),
  result jsonb,                          -- ParsedRecipe, matching the Zod schema
  error_code text,
  error_message text,
  recipe_id uuid references recipes(id),  -- set once the user confirms and saves
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on import_jobs (household_id, status, created_at desc);
```

Flow: client inserts the job → Edge Function processes it → status becomes
`needs_review` with `result` populated → client shows the confirm screen (D8) →
on save, client writes the recipe and sets `recipe_id` + `done`.

Multiple photos = multiple job rows. The UI shows a queue.

---

## AI usage

```sql
create table ai_usage (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  user_id uuid references profiles(id),
  function_name text not null,
  model text not null,
  input_tokens int,
  output_tokens int,
  cost_micros bigint,
  created_at timestamptz not null default now()
);
create index on ai_usage (household_id, created_at desc);

create table household_ai_limits (
  household_id uuid primary key references households(id) on delete cascade,
  monthly_cost_cap_micros bigint not null default 300000000,  -- ~$300, tune down
  monthly_call_cap int not null default 500
);
```

`_shared/usage.ts` checks both caps before any model call and records after.
Client may read its own household's usage; only the service role writes.
