import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/net/network_status.dart';
import '../../../core/recipes/widgets/recipe_picker_sheet.dart';
import '../../../core/router/routes.dart';
import '../application/meal_plan_providers.dart';
import '../domain/meal_plan_entry.dart';
import '../domain/meal_plan_week.dart';
import '../domain/meal_slot.dart';
import '../domain/plan_week.dart';
import '../domain/snack_variety.dart';

/// The week grid: 7 days x 4 slots, add / move / remove a recipe or a note.
///
/// The `AppBar` is built outside the body's `AsyncValue.when` and titled
/// exactly `Plan` -- `test/core/router/app_shell_test.dart` taps this tab and
/// asserts that title regardless of what the underlying providers do, the
/// same shape `RecipeListScreen` already survives.
///
/// Phone-first vertical list of days, each with 4 slot rows -- not a 7-column
/// grid, which would not fit a phone's width. Tapping a slot is the primary,
/// tested way to add or move an entry; long-press-drag is offered alongside
/// it as a shortcut between nearby slots, not as the only path (D53).
class MealPlanScreen extends ConsumerWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MealPlanWeek> week = ref.watch(mealPlanEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        actions: <Widget>[
          IconButton(
            tooltip: 'This week',
            icon: const Icon(Icons.today_outlined),
            onPressed: () => ref.read(visibleWeekProvider.notifier).today(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const _WeekBar(),
          if (week.isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: week.when(
              loading: () => const SizedBox.shrink(),
              error: (Object e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(e is AppFailure ? e.message : e.toString()),
                ),
              ),
              data: (MealPlanWeek plan) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(mealPlanEditorProvider),
                child: ListView(
                  children: <Widget>[
                    const _SavedCopyLine(),
                    for (final DateTime day in plan.week.days)
                      _DaySection(day: day, plan: plan),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBar extends ConsumerWidget {
  const _WeekBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlanWeek week = ref.watch(visibleWeekProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          tooltip: 'Previous week',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(visibleWeekProvider.notifier).previous(),
        ),
        Text(week.label, style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          tooltip: 'Next week',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => ref.read(visibleWeekProvider.notifier).next(),
        ),
      ],
    );
  }
}

/// "Showing your saved copy -- no connection." on `_GeneratedAt`'s exact
/// precedent (`shopping_list_screen.dart`, D67, widened to meal plans in
/// Phase 2 part 6b). Renders only inside the `data:` branch -- exactly where
/// a cache hit is on screen -- and only when [Reachability.offline], never
/// on [Reachability.unknown]: no read has completed yet at that point, and a
/// line here would be a guess, not a fact.
///
/// Narrower and more useful than [OfflineBanner]: this says "this WEEK is
/// not what the server has right now", the banner says "the phone cannot
/// reach the server at all" (D76).
class _SavedCopyLine extends ConsumerWidget {
  const _SavedCopyLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool offline =
        ref.watch(networkStatusProvider) == Reachability.offline;
    if (!offline) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        'Showing your saved copy — no connection.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.plan});

  final DateTime day;
  final MealPlanWeek plan;

  bool get _isToday {
    final DateTime now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${dayAbbrevOf(day)} ${day.day}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: _isToday ? theme.colorScheme.primary : null,
              fontWeight: _isToday ? FontWeight.bold : null,
            ),
          ),
        ),
        for (final MealSlot slot in MealSlot.ordered)
          _SlotRow(day: day, slot: slot, entries: plan.entriesFor(day, slot)),
        const Divider(height: 1),
      ],
    );
  }
}

String _slotLabel(MealSlot slot) => switch (slot) {
      MealSlot.breakfast => 'Breakfast',
      MealSlot.lunch => 'Lunch',
      MealSlot.dinner => 'Dinner',
      MealSlot.snack => 'Snack',
    };

class _SlotRow extends ConsumerWidget {
  const _SlotRow({
    required this.day,
    required this.slot,
    required this.entries,
  });

  final DateTime day;
  final MealSlot slot;
  final List<MealPlanEntry> entries;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final RecipePick? pick = await showRecipePicker(context);
    if (pick == null || !context.mounted) return;

    try {
      final MealPlanEditor editor = ref.read(mealPlanEditorProvider.notifier);
      switch (pick) {
        case PickRecipe(:final recipe):
          if (slot == MealSlot.snack) {
            final int repeatCount = await editor.snackRepeatCount(
                recipeId: recipe.id, entryDate: day);
            if (!context.mounted) return;
            if (shouldWarnOnRepeat(repeatCount)) {
              final bool proceed = await _confirmRepeat(context, repeatCount);
              if (!proceed || !context.mounted) return;
            }
          }
          await editor.addRecipe(
              entryDate: day, slot: slot, recipeId: recipe.id);
        case PickNote(:final note):
          await editor.addNote(entryDate: day, slot: slot, note: note);
      }
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Advisory only -- `snack_variety.dart`'s check never blocks the write,
  /// it only asks first. Cancelling here writes nothing; the caller checks
  /// `context.mounted` again after this returns either way.
  Future<bool> _confirmRepeat(BuildContext context, int repeatCount) async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Already planned recently'),
        content: Text(
          'Already in $repeatCount snack slot${repeatCount == 1 ? '' : 's'} '
          'this fortnight.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add anyway'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  Future<void> _moveHere(BuildContext context, WidgetRef ref, String entryId) async {
    try {
      await ref
          .read(mealPlanEditorProvider.notifier)
          .moveEntry(entryId: entryId, entryDate: day, slot: slot);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => DragTarget<String>(
        onAcceptWithDetails: (DragTargetDetails<String> details) =>
            _moveHere(context, ref, details.data),
        builder: (BuildContext context, List<String?> candidate, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: candidate.isEmpty
              ? null
              : BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 76,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_slotLabel(slot),
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    for (int i = 0; i < entries.length; i++)
                      _EntryChip(
                        entry: entries[i],
                        index: i,
                        total: entries.length,
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      onPressed: () => _add(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

enum _EntryAction { open, servings, leftovers, move, up, down, remove }

class _EntryChip extends ConsumerWidget {
  const _EntryChip({
    required this.entry,
    required this.index,
    required this.total,
  });

  final MealPlanEntry entry;

  /// This chip's position and the slot's size, both computed by the caller
  /// from the same ordered list `entriesFor` already returns -- so *Move up*
  /// / *Move down* can be shown only where there is somewhere to go, without
  /// a second definition of "first" / "last" in this file.
  final int index;
  final int total;

  Future<void> _openActions(BuildContext context, WidgetRef ref) async {
    final _EntryAction? action = await showModalBottomSheet<_EntryAction>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (entry.recipeId != null)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open recipe'),
                onTap: () => Navigator.of(context).pop(_EntryAction.open),
              ),
            if (entry.entryKind == MealEntryKind.recipe)
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Cooking for...'),
                subtitle: Text(entry.servings == null
                    ? 'As the recipe says'
                    : '${entry.servings}'),
                onTap: () => Navigator.of(context).pop(_EntryAction.servings),
              ),
            if (entry.entryKind == MealEntryKind.recipe)
              ListTile(
                leading: const Icon(Icons.replay_outlined),
                title: const Text('Plan leftovers...'),
                onTap: () => Navigator.of(context).pop(_EntryAction.leftovers),
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Move to...'),
              onTap: () => Navigator.of(context).pop(_EntryAction.move),
            ),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Move up'),
                onTap: () => Navigator.of(context).pop(_EntryAction.up),
              ),
            if (index < total - 1)
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text('Move down'),
                onTap: () => Navigator.of(context).pop(_EntryAction.down),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove'),
              onTap: () => Navigator.of(context).pop(_EntryAction.remove),
            ),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;
    switch (action) {
      case _EntryAction.open:
        RecipeDetailRoute(entry.recipeId!).go(context);
      case _EntryAction.servings:
        await _showServingsDialog(context, ref);
      case _EntryAction.leftovers:
        await _showLeftoverDialog(context, ref);
      case _EntryAction.move:
        await _showMoveDialog(context, ref);
      case _EntryAction.up:
        await _reorder(context, ref, index - 1);
      case _EntryAction.down:
        await _reorder(context, ref, index + 1);
      case _EntryAction.remove:
        await _remove(context, ref);
    }
  }

  /// How many people this one planned meal is for (D62).
  ///
  /// `meal_plan_entries.servings` has been readable since migration 14 and
  /// nothing ever wrote it, which quietly made `docs/DATA_MODEL.md`'s "scale
  /// by servings" step a no-op. This is what makes the shopping list's
  /// scaling reachable from the app rather than only from a unit test.
  ///
  /// "As the recipe says" clears the override rather than storing the
  /// recipe's own number: copying it would freeze a value that should follow
  /// the recipe if the recipe is later corrected.
  Future<void> _showServingsDialog(BuildContext context, WidgetRef ref) async {
    final int? recipeServings = entry.recipeServings;
    int? selected = entry.servings;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: const Text('Cooking for'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<int?>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Servings'),
                items: <DropdownMenuItem<int?>>[
                  DropdownMenuItem<int?>(
                    child: Text(recipeServings == null
                        ? 'As the recipe says'
                        : 'As the recipe says ($recipeServings)'),
                  ),
                  for (int n = 1; n <= 20; n++)
                    DropdownMenuItem<int?>(value: n, child: Text('$n')),
                ],
                onChanged: (int? value) => setState(() => selected = value),
              ),
              const SizedBox(height: 8),
              Text(
                recipeServings == null
                    ? 'This recipe does not say how many it serves, so the '
                        'shopping list cannot scale it.'
                    : 'The shopping list scales this meal\'s ingredients to '
                        'match.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(mealPlanEditorProvider.notifier)
          .setServings(entryId: entry.id, servings: selected);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showMoveDialog(BuildContext context, WidgetRef ref) async {
    final PlanWeek week = ref.read(visibleWeekProvider);
    DateTime selectedDay = entry.entryDate;
    MealSlot selectedSlot = entry.slot;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: const Text('Move to'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<DateTime>(
                initialValue: selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: <DropdownMenuItem<DateTime>>[
                  for (final DateTime day in week.days)
                    DropdownMenuItem<DateTime>(
                      value: day,
                      child: Text('${dayAbbrevOf(day)} ${day.day}'),
                    ),
                ],
                onChanged: (DateTime? value) {
                  if (value != null) setState(() => selectedDay = value);
                },
              ),
              DropdownButtonFormField<MealSlot>(
                initialValue: selectedSlot,
                decoration: const InputDecoration(labelText: 'Slot'),
                items: <DropdownMenuItem<MealSlot>>[
                  for (final MealSlot slot in MealSlot.ordered)
                    DropdownMenuItem<MealSlot>(
                      value: slot,
                      child: Text(_slotLabel(slot)),
                    ),
                ],
                onChanged: (MealSlot? value) {
                  if (value != null) setState(() => selectedSlot = value);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(mealPlanEditorProvider.notifier).moveEntry(
            entryId: entry.id,
            entryDate: selectedDay,
            slot: selectedSlot,
          );
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Same `StatefulBuilder` + two dropdowns shape as [_showMoveDialog], but
  /// the day list is 14 consecutive dates from [entry]'s own date rather than
  /// the visible week's 7 -- a leftover's range is D56's "next 14 days from
  /// the source", not bounded by what happens to be on screen, and it can
  /// cross a month boundary, hence [shortDateLabel] rather than
  /// [dayAbbrevOf].
  Future<void> _showLeftoverDialog(BuildContext context, WidgetRef ref) async {
    final List<DateTime> candidateDays = List<DateTime>.generate(
      14,
      (int i) => DateTime(
        entry.entryDate.year,
        entry.entryDate.month,
        entry.entryDate.day + i,
      ),
    );
    DateTime selectedDay = candidateDays[1]; // source date + 1 day, default
    MealSlot selectedSlot = entry.slot;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: const Text('Plan leftovers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<DateTime>(
                initialValue: selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: <DropdownMenuItem<DateTime>>[
                  for (final DateTime day in candidateDays)
                    DropdownMenuItem<DateTime>(
                      value: day,
                      child: Text(shortDateLabel(day)),
                    ),
                ],
                onChanged: (DateTime? value) {
                  if (value != null) setState(() => selectedDay = value);
                },
              ),
              DropdownButtonFormField<MealSlot>(
                initialValue: selectedSlot,
                decoration: const InputDecoration(labelText: 'Slot'),
                items: <DropdownMenuItem<MealSlot>>[
                  for (final MealSlot slot in MealSlot.ordered)
                    DropdownMenuItem<MealSlot>(
                      value: slot,
                      child: Text(_slotLabel(slot)),
                    ),
                ],
                onChanged: (MealSlot? value) {
                  if (value != null) setState(() => selectedSlot = value);
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(mealPlanEditorProvider.notifier).addLeftover(
            sourceEntryId: entry.id,
            entryDate: selectedDay,
            slot: selectedSlot,
          );
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _reorder(
      BuildContext context, WidgetRef ref, int newPosition) async {
    try {
      await ref.read(mealPlanEditorProvider.notifier).reorderEntry(
            entryId: entry.id,
            newPosition: newPosition,
          );
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(mealPlanEditorProvider.notifier).removeEntry(entry.id);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => LongPressDraggable<String>(
        data: entry.id,
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: _chip(context),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: _chip(context)),
        child: GestureDetector(
          onTap: () => _openActions(context, ref),
          child: _chip(context),
        ),
      );

  Widget _chip(BuildContext context) => Chip(
        avatar: Icon(
          switch (entry.entryKind) {
            MealEntryKind.note => Icons.edit_note_outlined,
            MealEntryKind.leftover => Icons.replay_outlined,
            MealEntryKind.recipe => Icons.restaurant_menu_outlined,
          },
          size: 16,
        ),
        label: Text(entry.label),
      );
}
