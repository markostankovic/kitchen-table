-- Migration 1 -- foundations only.
--
-- Extensions, normalize_text(), and the updated_at trigger function. No
-- tables: those arrive with their RLS policies in Phase 1 (docs/ROADMAP.md).
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md). Every change is a new
-- timestamped migration.
--
-- ---------------------------------------------------------------------------
-- OPERATIONAL TRAP, read before changing normalize_text()
-- ---------------------------------------------------------------------------
-- normalize_text() is IMMUTABLE and backs STORED generated columns
-- (ingredient_names.normalized_name, recipes.title_normalized, ...).
--
-- Postgres will happily accept CREATE OR REPLACE on this function and will NOT
-- recompute those stored columns. The data silently goes stale and search
-- starts missing rows that used to match.
--
-- So: any future change to this function needs a migration that ALSO rebuilds
-- every generated column derived from it, and the same change must land in
-- lib/core/text/text_normalizer.dart, verified against
-- test/fixtures/normalization.json (CLAUDE.md rule 6, D5).
-- ---------------------------------------------------------------------------

create extension if not exists pg_trgm;

-- Note: `unaccent` is deliberately NOT installed.
--
-- Two reasons. It maps đ -> d, which splits *đuveč* from a user typing
-- *djuvec* (D5 rejects it on exactly this ground). And it is STABLE rather
-- than IMMUTABLE, because its behaviour depends on a mutable dictionary -- so
-- any function calling it cannot be IMMUTABLE and therefore cannot back a
-- generated column at all. docs/DATA_MODEL.md lists it as a helper inside
-- normalize_text; that is not implementable, and not needed.

-- ---------------------------------------------------------------------------
-- normalize_text
-- ---------------------------------------------------------------------------
-- Mirrors TextNormalizer.normalize in Dart, step for step. Order matters:
--
--   1. lowercase
--   2. Cyrillic -> Latin, DIGRAPHS FIRST (њ is one codepoint, two letters, so
--      translate() cannot express it), then the 1:1 map
--   3. Latin diacritics, with đ -> dj done by replace() before translate()
--      handles the 1:1 ones
--   4. collapse whitespace, trim
--
-- Punctuation is deliberately preserved: the ingredient line parser already
-- splits notes off at the first comma.

create or replace function normalize_text(input text)
returns text
language sql
immutable
strict
parallel safe
as $$
  select trim(
    regexp_replace(
      translate(
        -- 3. Latin diacritics: the 1:1 remainder, after đ -> dj below
        replace(
          translate(
            -- 2. Cyrillic -> Latin, 1:1 remainder
            replace(replace(replace(replace(replace(replace(
              -- 1. lowercase, then Cyrillic digraphs
              lower(input),
              'њ', 'nj'), 'љ', 'lj'), 'џ', 'dz'), 'ђ', 'dj'), 'ћ', 'c'), 'ж', 'z'),
            'абвгдезијклмнопрстуфхцчш',
            'abvgdezijklmnoprstufhccs'
          ),
          -- đ is two characters in Latin, so it cannot ride in translate()
          'đ', 'dj'
        ),
        'čćšž',
        'ccsz'
      ),
      -- 4. collapse whitespace
      '\s+', ' ', 'g'
    )
  );
$$;

comment on function normalize_text(text) is
  'Serbian text -> lowercase diacritic-free Latin. Mirrors TextNormalizer in '
  'Dart; both are verified against test/fixtures/normalization.json. '
  'Changing this requires rebuilding every generated column that uses it.';

-- ---------------------------------------------------------------------------
-- updated_at trigger
-- ---------------------------------------------------------------------------
-- Every household-scoped table gets this trigger in the same migration that
-- creates it -- never a follow-up (docs/ROADMAP.md, "Standing rules").

create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function set_updated_at() is
  'BEFORE UPDATE trigger: maintains updated_at. Required on every '
  'household-scoped table (CLAUDE.md rule 4).';
