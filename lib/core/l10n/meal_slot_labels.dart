/// [MealSlot]'s sentence, in the reader's language.
///
/// `MealSlot` is a domain enum and may not know a sentence (CLAUDE.md rule 7,
/// D92) -- so, like `core/error/failure_l10n.dart` does for `FailureCode`,
/// this is a sibling function taking `(value, AppLocalizations)`, not a
/// method on the enum. Moved here from `meal_plan_screen.dart`'s private
/// `_slotLabel` so `core/meal_plan/widgets/meal_slot_picker_sheet.dart` --
/// which may not import `features/meal_plan/presentation/` -- has one
/// definition to call rather than a second copy of the same switch.
///
/// No `default` arm, deliberately: a new [MealSlot] must fail to compile
/// until it has a label here.
library;

import '../../features/meal_plan/domain/meal_slot.dart';
import 'generated/app_localizations.dart';

String mealSlotLabel(MealSlot slot, AppLocalizations l10n) => switch (slot) {
      MealSlot.breakfast => l10n.mealSlotBreakfast,
      MealSlot.lunch => l10n.mealSlotLunch,
      MealSlot.dinner => l10n.mealSlotDinner,
      MealSlot.snack => l10n.mealSlotSnack,
    };
