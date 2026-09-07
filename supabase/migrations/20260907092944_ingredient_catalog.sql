-- Migration 4 -- the ingredient catalog (Phase 1b, first slice).
--
-- The tables behind docs/INGREDIENTS.md: language-neutral ingredient concepts,
-- their names in every locale and spelling, the unit lexicon the line parser
-- matches against, and the merge audit log. No seed data for ingredients here
-- -- that arrives as a generated migration in the next slice (D29). The units
-- ARE seeded here, inline, because they are ~24 fixed rows whose to_base
-- values each need an explanation more than they need a CSV.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D27 (ingredients.key), D28 (ingredient_names
-- lifecycle columns), D32 (no write policies on the catalog in Phase 1b).

-- ---------------------------------------------------------------------------
-- units
-- ---------------------------------------------------------------------------
-- Reference data, not household-scoped: no household_id, so D24 does not reach
-- it, and it gets neither deleted_at nor updated_at. Twenty-odd immutable rows
-- that only a migration ever writes, refetched wholesale by the client and
-- cached for a session. Do not "fix" the missing lifecycle columns -- there is
-- no writer that could maintain them and nothing that would read them.
--
-- Codes are stable ASCII and language-neutral. Every Serbian string lives in
-- unit_names, which is what the parser actually matches against.

create table units (
  code text primary key,
  family text not null check (family in ('mass','volume','count','other')),
  -- Converts to the family's base: grams, millilitres, or one piece. The
  -- shopping list sums within a family and never across one (D9).
  to_base numeric not null check (to_base > 0),
  -- Only consulted for mass and volume, where it decides whether a summed
  -- quantity renders as `500 g` or `1 lb`. Meaningless for count and other.
  is_metric boolean not null default true,
  -- family 'other' is the escape hatch for measures that are not quantities at
  -- all (prstohvat, po ukusu). There is nothing to convert, so pin to_base to
  -- 1 rather than leaving a number that looks like it means something.
  constraint units_other_family_has_no_scale
    check (family <> 'other' or to_base = 1)
);

comment on table units is
  'Unit lexicon. Codes are language-neutral; names live in unit_names. '
  'Seeded by migration only.';

-- ---------------------------------------------------------------------------
-- unit_names
-- ---------------------------------------------------------------------------
-- docs/DATA_MODEL.md gives this table no key at all. It needs one, and it
-- needs the unique index below far more.

create table unit_names (
  id uuid primary key default gen_random_uuid(),
  unit_code text not null references units(code),
  locale text not null check (locale in ('sr','en')),
  name text not null,
  normalized_name text generated always as (normalize_text(name)) stored,
  is_display_name boolean not null default false
);

-- The load-bearing one. Without it `kš` could silently resolve to both tsp and
-- tbsp, and the parser would pick whichever the planner returned first --
-- a wrong unit that renders as a confident number. Rule 3 prefers a null unit
-- and the raw line over a plausible lie.
create unique index unit_names_normalized_locale_idx
  on unit_names (normalized_name, locale);

-- Exactly one name per unit per locale is the one shown back to the user.
create unique index unit_names_one_display_per_locale_idx
  on unit_names (unit_code, locale) where is_display_name;

create index unit_names_unit_code_idx on unit_names (unit_code);

comment on table unit_names is
  'Every spelling and inflection that resolves to a unit. Serbian is heavily '
  'inflected and recipes are abbreviated, so aliases are seeded generously.';

-- ---------------------------------------------------------------------------
-- Unit seed
-- ---------------------------------------------------------------------------
-- Base units are g, ml and one piece. Everything else states its multiple.

insert into units (code, family, to_base, is_metric) values
  -- mass
  ('mg',       'mass',   0.001,          true),
  ('g',        'mass',   1,              true),
  ('kg',       'mass',   1000,           true),
  -- Imperial mass: nothing Serbian uses these, but Phase 1d imports English
  -- recipes off the web and a parsed `8 oz` must land somewhere real.
  ('oz',       'mass',   28.349523125,   false),
  ('lb',       'mass',   453.59237,      false),
  -- volume
  ('ml',       'volume', 1,              true),
  ('dl',       'volume', 100,            true),
  ('l',        'volume', 1000,           true),
  -- Spoons and cups are volume by convention, not by metrology. These are the
  -- values docs/DATA_MODEL.md fixes; they are conventions, not measurements,
  -- and changing one silently changes every historical shopping list.
  ('tsp',      'volume', 5,              false),   -- kašičica
  ('tbsp',     'volume', 15,             false),   -- kašika
  ('cup',      'volume', 240,            false),   -- šolja
  -- A čaša is NOT a šolja. Serbian recipes use both, and a čaša is ~200 ml
  -- against a šolja's ~240. Aliasing them onto one code would quietly lose
  -- 40 ml in every sum, which is exactly the error a shopping list cannot
  -- afford to make invisibly.
  ('glass',    'volume', 200,            false),   -- čaša
  ('fl_oz',    'volume', 29.5735295625,  false),
  -- count: everything here is one piece of something, and the something is
  -- carried by the name, not the scale.
  ('kom',      'count',  1,              false),
  ('clove',    'count',  1,              false),   -- čen (belog luka)
  ('head',     'count',  1,              false),   -- glavica
  ('bunch',    'count',  1,              false),   -- veza
  ('slice',    'count',  1,              false),   -- kriška, parče
  ('sachet',   'count',  1,              false),   -- kesica
  ('can',      'count',  1,              false),   -- konzerva
  -- other: not a quantity. The shopping list carries these through as a note
  -- and never sums them.
  ('pinch',    'other',  1,              false),   -- prstohvat
  ('to_taste', 'other',  1,              false);   -- po ukusu

-- `po ukusu` is seeded as a unit here AND appears in docs/INGREDIENTS.md's list
-- of optional markers. That is not a contradiction: the parser strips it as a
-- marker when it trails the line, and resolves it as a unit when it stands
-- where a quantity would. Whichever fires, raw_text still renders (rule 3).
--
-- Deliberately NOT seeded: `k.` and `kaš.`, which INGREDIENTS.md lists under
-- kašika. `k.` reads equally as kom or kg, and `kaš.` as kašičica. An ambiguous
-- abbreviation resolved to a confident wrong unit is worse than no unit at all.
-- `kš` is unambiguous and is seeded.

insert into unit_names (unit_code, locale, name, is_display_name) values
  ('mg','sr','mg',true),('mg','sr','miligram',false),
  ('mg','en','mg',true),('mg','en','milligram',false),

  ('g','sr','g',true),('g','sr','gr',false),('g','sr','gram',false),
  ('g','sr','grama',false),('g','sr','grami',false),
  ('g','en','g',true),('g','en','gram',false),('g','en','grams',false),

  ('kg','sr','kg',true),('kg','sr','kilogram',false),
  ('kg','sr','kilograma',false),('kg','sr','kila',false),
  ('kg','en','kg',true),('kg','en','kilogram',false),('kg','en','kilograms',false),

  ('oz','sr','unca',true),('oz','sr','unce',false),
  ('oz','en','oz',true),('oz','en','ounce',false),('oz','en','ounces',false),

  ('lb','sr','funta',true),('lb','sr','funte',false),
  ('lb','en','lb',true),('lb','en','pound',false),('lb','en','pounds',false),

  ('ml','sr','ml',true),('ml','sr','mililitar',false),('ml','sr','mililitara',false),
  ('ml','en','ml',true),('ml','en','milliliter',false),('ml','en','milliliters',false),

  ('dl','sr','dl',true),('dl','sr','decilitar',false),('dl','sr','decilitara',false),
  ('dl','en','dl',true),('dl','en','deciliter',false),

  ('l','sr','l',true),('l','sr','litar',false),('l','sr','litra',false),
  ('l','sr','litre',false),('l','sr','litara',false),
  ('l','en','l',true),('l','en','liter',false),('l','en','liters',false),
  ('l','en','litre',false),

  ('tsp','sr','kašičica',true),('tsp','sr','kašičice',false),
  ('tsp','sr','kašičicu',false),('tsp','sr','kafena kašičica',false),
  ('tsp','sr','čajna kašičica',false),
  ('tsp','en','tsp',true),('tsp','en','teaspoon',false),('tsp','en','teaspoons',false),

  ('tbsp','sr','kašika',true),('tbsp','sr','kašike',false),
  ('tbsp','sr','kašiku',false),('tbsp','sr','kašikom',false),
  ('tbsp','sr','supena kašika',false),('tbsp','sr','kš',false),
  ('tbsp','en','tbsp',true),('tbsp','en','tablespoon',false),
  ('tbsp','en','tablespoons',false),

  ('cup','sr','šolja',true),('cup','sr','šolje',false),('cup','sr','šolju',false),
  ('cup','en','cup',true),('cup','en','cups',false),

  ('glass','sr','čaša',true),('glass','sr','čaše',false),('glass','sr','čašu',false),
  ('glass','en','glass',true),('glass','en','glasses',false),

  ('fl_oz','sr','tečna unca',true),
  ('fl_oz','en','fl oz',true),('fl_oz','en','fluid ounce',false),

  ('kom','sr','kom',true),('kom','sr','kom.',false),('kom','sr','komad',false),
  ('kom','sr','komada',false),
  ('kom','en','pc',true),('kom','en','piece',false),('kom','en','pieces',false),

  ('clove','sr','čen',true),('clove','sr','čena',false),
  ('clove','sr','čenova',false),('clove','sr','češanj',false),
  ('clove','en','clove',true),('clove','en','cloves',false),

  ('head','sr','glavica',true),('head','sr','glavice',false),
  ('head','en','head',true),('head','en','heads',false),

  ('bunch','sr','veza',true),('bunch','sr','veze',false),
  ('bunch','sr','struk',false),('bunch','sr','struka',false),
  ('bunch','en','bunch',true),('bunch','en','bunches',false),

  ('slice','sr','kriška',true),('slice','sr','kriške',false),
  ('slice','sr','parče',false),('slice','sr','parčeta',false),
  ('slice','en','slice',true),('slice','en','slices',false),

  ('sachet','sr','kesica',true),('sachet','sr','kesice',false),
  ('sachet','en','sachet',true),('sachet','en','packet',false),

  ('can','sr','konzerva',true),('can','sr','konzerve',false),
  ('can','en','can',true),('can','en','cans',false),

  ('pinch','sr','prstohvat',true),('pinch','sr','prstohvata',false),
  ('pinch','en','pinch',true),('pinch','en','pinches',false),

  ('to_taste','sr','po ukusu',true),
  ('to_taste','en','to taste',true);

-- ---------------------------------------------------------------------------
-- ingredients
-- ---------------------------------------------------------------------------
-- A language-neutral concept row. It carries no name at all -- every string a
-- human would recognise lives in ingredient_names, which is what lets *brašno*
-- and *flour* be one ingredient and one shopping-list line (D1).

create table ingredients (
  id uuid primary key default gen_random_uuid(),

  -- D27. The stable seed key from docs/INGREDIENTS.md's CSV (`brasno_glatko`).
  -- Nullable, and null is the common case: only the curated core carries one.
  -- Everything the matcher auto-creates has key = null.
  --
  -- Nullable UNIQUE is exactly right here -- Postgres treats NULLs as distinct,
  -- so this reads as "unique among rows that have a key" with no partial index
  -- and no `where key is not null` clause to repeat in every ON CONFLICT.
  --
  -- A plain constraint rather than a partial unique index on purpose: the seed
  -- upserts with `on conflict (key) do update`, and conflict inference against
  -- a partial index would have to restate the predicate every time.
  --
  -- Deliberately NOT tied to is_verified. A curated row can be retired and a
  -- tail row can be verified by hand later; two independent facts, two columns.
  key text unique check (key is null or key ~ '^[a-z][a-z0-9_]*$'),

  parent_id uuid references ingredients(id),      -- ONE level only (D3)
  category text,                                  -- nullable; aisle grouping later
  default_unit_family text
    check (default_unit_family in ('mass','volume','count')),
  is_verified boolean not null default false,     -- false = auto-created tail
  is_pantry_staple boolean not null default false,
  density_g_per_ml numeric,                       -- nullable, deferred (D9)
  piece_weight_g numeric,                         -- nullable, deferred
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Not household-scoped, but it keeps deleted_at anyway: merges retire rows
  -- (never hard-delete them, rule 4) and Phase 2's delta fetch needs the
  -- tombstone to evict the ingredient from the Drift cache (D12/D23).
  deleted_at timestamptz
);

comment on table ingredients is
  'Language-neutral ingredient concepts. Names live in ingredient_names. '
  'Curated rows carry a key; the auto-created tail does not (D27).';

create index ingredients_parent_id_idx on ingredients (parent_id)
  where parent_id is not null;

create trigger ingredients_set_updated_at
  before update on ingredients
  for each row execute function set_updated_at();

-- D3 is "exactly one level", which no CHECK constraint can express -- a check
-- may not read other rows. A trigger can, and this is cheap: it fires only on
-- rows that actually set a parent.
--
-- Both directions have to be blocked. Pointing at a row that already has a
-- parent makes a grandchild; acquiring a parent while already having children
-- makes the same shape from the other end.

create or replace function ingredients_enforce_one_level()
returns trigger
language plpgsql
as $$
begin
  if new.parent_id is null then
    return new;
  end if;

  if new.parent_id = new.id then
    raise exception 'ingredient % cannot be its own parent', new.id
      using errcode = '23514';
  end if;

  if exists (
    select 1 from ingredients p
    where p.id = new.parent_id and p.parent_id is not null
  ) then
    raise exception
      'ingredient hierarchy is one level only (D3): parent % already has a parent',
      new.parent_id using errcode = '23514';
  end if;

  if exists (select 1 from ingredients c where c.parent_id = new.id) then
    raise exception
      'ingredient hierarchy is one level only (D3): % already has children',
      new.id using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger ingredients_one_level_only
  before insert or update of parent_id on ingredients
  for each row execute function ingredients_enforce_one_level();

-- ---------------------------------------------------------------------------
-- ingredient_names
-- ---------------------------------------------------------------------------
-- Aliases AND translations in one table (D1). `glatko brašno`, `brašna`,
-- `all-purpose flour` and `flour` are four rows pointing at the same concept,
-- and tier 2 of the matcher is a single equality against normalized_name.
--
-- D28: this table keeps updated_at and deleted_at, unlike household_invites in
-- migration 3. The exception D25 took does not apply here:
--
--   * is_display_name is mutable -- a merge demotes it -- so "append-only,
--     write once" was never true of this table the way it is of an invite.
--   * merge_ingredients has to dispose of a duplicate alias row. docs/
--     DATA_MODEL.md words that as "drop the duplicate", which would be a hard
--     delete and a straight violation of CLAUDE.md rule 4. deleted_at makes it
--     a soft delete and keeps the rule intact.
--   * It has a household_id, so D24 catches it literally.
--   * Phase 2 caches the catalog for offline autocomplete, and a cache needs
--     tombstones to evict (D12/D23).

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
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table ingredient_names is
  'Every string that resolves to an ingredient, in every locale. Tier 2 of the '
  'matcher is one equality against normalized_name. household_id null = global.';

create trigger ingredient_names_set_updated_at
  before update on ingredient_names
  for each row execute function set_updated_at();

-- The coalesce is how a nullable household_id participates in a unique index:
-- NULLs are distinct to Postgres, so without it every global row would be
-- unique against every other global row and the constraint would do nothing.
--
-- Deliberately TOTAL -- no `where deleted_at is null`. One string means one
-- thing, forever, per locale and scope. Re-seeding a retired alias resurrects
-- and repoints the existing row (`do update set deleted_at = null`) instead of
-- creating a second row for the same string, which is the shape that would
-- eventually let one string resolve two ways.
create unique index ingredient_names_unique
  on ingredient_names (
    normalized_name,
    locale,
    coalesce(household_id, '00000000-0000-0000-0000-000000000000'::uuid)
  );

-- Tier 3. The fuzzy tier is a similarity() scan over this index; without it
-- the matcher still works and gets slower with every ingredient anyone types.
create index ingredient_names_trgm
  on ingredient_names using gin (normalized_name gin_trgm_ops);

-- One canonical name per ingredient per locale, among global rows. Soft-
-- deleted rows are excluded so that retiring a display name actually frees the
-- slot for its replacement.
create unique index one_display_name_per_locale
  on ingredient_names (ingredient_id, locale)
  where is_display_name and household_id is null and deleted_at is null;

create index ingredient_names_ingredient_id_idx
  on ingredient_names (ingredient_id);

-- ---------------------------------------------------------------------------
-- ingredient_merges
-- ---------------------------------------------------------------------------
-- The audit log for merge_ingredients(), which arrives in a later slice. The
-- table lands here because the standing rule puts tables, triggers and policies
-- in one migration, and because the function is easier to review next to
-- nothing but itself.
--
-- source_id and target_id carry no foreign key, following docs/DATA_MODEL.md.
-- The audit trail has to survive whatever happens to the rows it describes; a
-- merge chain is read by following these pairs, and an FK would make this log
-- a constraint on the catalog rather than a record of it.

create table ingredient_merges (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null,
  target_id uuid not null,
  merged_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  constraint ingredient_merges_distinct check (source_id <> target_id)
);

create index ingredient_merges_source_id_idx on ingredient_merges (source_id);

comment on table ingredient_merges is
  'Audit log of merge_ingredients(). No FKs on source_id/target_id: the record '
  'must outlive whatever happens to the rows it describes.';

-- ---------------------------------------------------------------------------
-- ingredient_display_name
-- ---------------------------------------------------------------------------
-- The fallback chain, defined once. Requested locale's display name, then any
-- locale's display name, then any name at all. Phase 2's shopping list and
-- Phase 3's translated recipe view both need this and must not each invent
-- their own order.
--
-- Global rows only. A household alias is a way of *finding* an ingredient, not
-- a way of renaming it for that household -- that is a later feature, and
-- letting it leak into the canonical name here would ship half of it by
-- accident.

create or replace function ingredient_display_name(iid uuid, loc text default 'sr')
returns text
language sql
stable
set search_path = public
as $$
  select n.name
  from ingredient_names n
  where n.ingredient_id = iid
    and n.household_id is null
    and n.deleted_at is null
  order by
    (n.locale = loc and n.is_display_name) desc,
    n.is_display_name desc,
    (n.locale = loc) desc,
    n.created_at
  limit 1;
$$;

comment on function ingredient_display_name(uuid, text) is
  'Display name in the requested locale, falling back to any display name, '
  'then any name. Global rows only.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- D32. The catalog is READ-ONLY to every client in Phase 1b. There is no
-- INSERT, UPDATE or DELETE policy on any table here, and that absence is the
-- decision, not an oversight:
--
--   * The seed runs as postgres, during migration.
--   * merge_ingredients runs as service role / operator.
--   * The matcher's write-back tier (tier 4/5 in docs/INGREDIENTS.md) is an
--     Edge Function holding the service role key, and it does not exist until
--     Phase 1d.
--   * Phase 1c's "create a new ingredient" needs a write path, and it gets a
--     deliberate one -- a narrow SECURITY DEFINER RPC in 1c's own migration,
--     chosen then. What it must not do is inherit a broad INSERT policy
--     written a phase early by someone guessing at its shape.
--
-- Migration 3 already ruled on this exact question: a write policy nobody uses
-- "would be dead code that reads like a second, weaker way in".
--
-- ingredients and the unit tables are global reference data with nothing
-- private in them, so SELECT is open to any authenticated user.

alter table units enable row level security;
alter table unit_names enable row level security;
alter table ingredients enable row level security;
alter table ingredient_names enable row level security;
alter table ingredient_merges enable row level security;

create policy units_select on units for select
  to authenticated using (true);

create policy unit_names_select on unit_names for select
  to authenticated using (true);

-- No deleted_at clause, per D23: the policy answers visibility, and the
-- repository filters tombstones so the Phase 2 delta fetch can still see them.
create policy ingredients_select on ingredients for select
  to authenticated using (true);

-- Global rows are visible to everyone; a household's own aliases only to its
-- members. is_household_member is the SECURITY DEFINER helper from migration 2.
create policy ingredient_names_select on ingredient_names for select
  to authenticated
  using (household_id is null or is_household_member(household_id));

-- ingredient_merges gets RLS with NO policy at all, which denies every client.
-- It is an operator's audit log, and nothing in Phase 1b or 1c reads it. Phase
-- 2's admin screen (docs/ROADMAP.md) adds a read policy when it exists and has
-- a reason. An empty policy list is the restrictive default here, on purpose.
