/// The ingredient display-name fallback chain, ported from
/// `ingredient_display_name()` (migration 4) so a matched line can render
/// its catalog name offline (Phase 2 part 6a, D72).
///
/// Migration 4's own comment rejected reimplementing this chain in Dart,
/// "out of reach of the SQL tests" -- true when there was no offline reader
/// to serve. D72 overturns that narrowly, on the mechanism CLAUDE.md rule 6
/// already uses for exactly this shape of problem: one definition per side,
/// held to a shared fixture (`test/fixtures/display_names.json`), asserted
/// in both Dart (this file's own test) and Postgres
/// (`supabase/tests/display_names_test.sql`, generated from the same
/// fixture by `tool/gen_display_name_sql.dart`) -- the same pattern that
/// already governs `normalize_text()`/[TextNormalizer] and
/// `parse_line.ts`/the ingredient line parser.
///
/// Global rows only. A household's own alias is a way of *finding* an
/// ingredient, never a way of renaming it for that household (migration 4's
/// own words) -- callers must filter to `householdId == null` before
/// calling [resolve], exactly as the SQL function's own `where` clause does.
///
/// Pure Dart (rule 7): no Flutter, no Supabase, no drift.
library;

/// One global name a matched ingredient can be called -- the shape
/// `ingredient_display_name`'s own `order by` sorts on, nothing more.
class IngredientNameRow {
  const IngredientNameRow({
    required this.name,
    required this.locale,
    required this.isDisplayName,
    required this.createdAt,
  });

  final String name;
  final String locale;
  final bool isDisplayName;
  final DateTime createdAt;
}

class DisplayNameChain {
  const DisplayNameChain._();

  /// The winning name for [loc] among [names], or null if [names] is empty
  /// -- migration 4's `limit 1` over zero rows.
  ///
  /// Ported clause for clause from the SQL `order by`:
  /// ```
  /// order by
  ///   (locale = loc and is_display_name) desc,
  ///   is_display_name desc,
  ///   (locale = loc) desc,
  ///   created_at
  /// limit 1
  /// ```
  /// Not a single sort key: this is "prefer A, then among ties prefer B,
  /// then among those ties prefer C", which is what SQL's multi-column
  /// `order by` means and what a chain of comparisons (rather than a scored
  /// sum) is needed to reproduce exactly.
  static String? resolve(List<IngredientNameRow> names, String loc) {
    if (names.isEmpty) return null;

    int compare(IngredientNameRow a, IngredientNameRow b) {
      int c = _rank(a.locale == loc && a.isDisplayName) -
          _rank(b.locale == loc && b.isDisplayName);
      if (c != 0) return c;

      c = _rank(a.isDisplayName) - _rank(b.isDisplayName);
      if (c != 0) return c;

      c = _rank(a.locale == loc) - _rank(b.locale == loc);
      if (c != 0) return c;

      return a.createdAt.compareTo(b.createdAt);
    }

    return (List<IngredientNameRow>.of(names)..sort(compare)).first.name;
  }

  /// `true` sorts before `false` -- SQL's `... desc` on a boolean column.
  static int _rank(bool value) => value ? 0 : 1;
}
