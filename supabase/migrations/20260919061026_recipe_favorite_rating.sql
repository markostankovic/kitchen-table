-- Migration 19 -- recipe_favorite_rating (Phase 5, part 1).
--
-- Favorites and a five-star rating on recipes. Both are household facts, not
-- personal ones (D24): one member's tap changes the value for everyone,
-- because recipes carries a household_id and profiles is the only table in
-- this app with auth.uid()-based RLS. Part 2 builds the tags-and-favorites
-- filter on top of this.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D100 (the first additive `alter table ...
-- add column` against an applied table, and what it means for D35's
-- "ship the column ahead of its writer" precedent).

-- ---------------------------------------------------------------------------
-- recipes.is_favorite, recipes.rating
-- ---------------------------------------------------------------------------
-- Every migration before this one creates its table whole; this is the first
-- that extends one already applied. That is deliberately narrow: an additive
-- `alter table ... add column`, nothing else.
--
-- No RLS change: recipes_select / recipes_insert / recipes_update (migration
-- 8) are table-level predicates on household_id, so they already cover these
-- columns, the same precedent migration 18 set explicitly for
-- recipe_translations_update.
--
-- No trigger change: recipes_set_updated_at (migration 8) is row-level and
-- column-agnostic, so it already covers a write to either column.
--
-- Both columns get a writer in this same slice (setFavorite / setRating), so
-- D35/D51/D82's "ship the column ahead of its writer" does not apply.

alter table recipes
  add column is_favorite boolean not null default false;

alter table recipes
  add column rating smallint check (rating between 1 and 5);

comment on column recipes.is_favorite is
  'Household fact, not a personal one (D24): any member''s tap changes it '
  'for everyone. Written only by setFavorite, never by the recipe editor''s '
  'update (D100).';

comment on column recipes.rating is
  '1-5, or null for unrated. Household fact, not a personal one (D24). '
  'Written only by setRating, never by the recipe editor''s update (D100).';
