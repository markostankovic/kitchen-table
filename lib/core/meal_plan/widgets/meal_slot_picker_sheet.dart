import 'package:flutter/material.dart';

import '../../../features/meal_plan/domain/meal_slot.dart';
import '../../l10n/date_labels.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/meal_slot_labels.dart';

/// What the cook decided when adding a recipe to the plan from its own
/// detail screen: a day and a slot.
///
/// One value, not a sealed hierarchy like `RecipePick` -- unlike the recipe
/// picker sheet, there is only one kind of decision to make here.
class MealSlotPick {
  const MealSlotPick(this.date, this.slot);

  final DateTime date;
  final MealSlot slot;
}

/// Asks the cook which day and slot to add a recipe to.
///
/// Opened from the recipe detail screen's overflow menu. The sheet performs
/// no writes of its own -- it returns the decision and the caller acts on
/// it, the same split `showRecipePicker` and `showIngredientPicker` use.
Future<MealSlotPick?> showMealSlotPicker(BuildContext context) =>
    showModalBottomSheet<MealSlotPick>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => const _MealSlotPickerSheet(),
    );

class _MealSlotPickerSheet extends StatefulWidget {
  const _MealSlotPickerSheet();

  @override
  State<_MealSlotPickerSheet> createState() => _MealSlotPickerSheetState();
}

class _MealSlotPickerSheetState extends State<_MealSlotPickerSheet> {
  MealSlot _selectedSlot = MealSlot.dinner;

  void _pickDay(DateTime day) =>
      Navigator.of(context).pop(MealSlotPick(day, _selectedSlot));

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateTime now = DateTime.now();
    final List<DateTime> days = List<DateTime>.generate(
      14,
      (int i) => DateTime(now.year, now.month, now.day + i),
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.addToPlanSheetTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final MealSlot slot in MealSlot.ordered)
                    ChoiceChip(
                      label: Text(mealSlotLabel(slot, l10n)),
                      selected: _selectedSlot == slot,
                      onSelected: (_) => setState(() => _selectedSlot = slot),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (int i = 0; i < days.length; i++)
                    ListTile(
                      title: Text(shortDateLabel(days[i], l10n.localeName)),
                      trailing:
                          i == 0 ? Chip(label: Text(l10n.todayChipLabel)) : null,
                      onTap: () => _pickDay(days[i]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
