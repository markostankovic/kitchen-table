/// The two small closed vocabularies a meal plan entry carries.
///
/// Both spellings match `meal_plan_entries`' check constraints exactly
/// (`slot in ('breakfast','lunch','dinner','snack')`,
/// `entry_kind in ('recipe','leftover','note')`), so [Values.byName] /
/// `.name` is the whole conversion -- no `wireValue` map is needed, unlike
/// `RecipeSourceType`, whose Dart names and DB spellings differ
/// (`urlImport` / `'url_import'`).
///
/// Pure Dart (CLAUDE.md rule 7).
library;

enum MealSlot {
  breakfast,
  lunch,
  dinner,
  snack;

  static const List<MealSlot> ordered = <MealSlot>[
    MealSlot.breakfast,
    MealSlot.lunch,
    MealSlot.dinner,
    MealSlot.snack,
  ];
}

enum MealEntryKind {
  recipe,

  /// D51: the column and this value ship in migration 14, but nothing writes
  /// it yet -- the leftover feature itself is a later part.
  leftover,
  note,
}
