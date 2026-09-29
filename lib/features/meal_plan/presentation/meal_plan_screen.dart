import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/meal_slot_labels.dart';
import '../../../core/net/network_status.dart';
import '../../../core/recipes/widgets/recipe_picker_sheet.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/kitchen_colors.dart';
import '../../../core/theme/kitchen_type.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_meta_row.dart';
import '../application/meal_plan_providers.dart';
import '../domain/meal_plan_entry.dart';
import '../domain/meal_plan_week.dart';
import '../domain/meal_slot.dart';
import '../domain/plan_week.dart';
import '../domain/snack_variety.dart';

/// The week plan: a day card per day, add / move / remove a recipe or a note.
///
/// The `AppBar` is built outside the body's `AsyncValue.when` and titled from
/// `AppLocalizations.navPlan` -- the same key the bottom nav label uses (D77,
/// Phase 3 part 1), so this screen's own header and its tab always agree on
/// language. `test/core/router/app_shell_test.dart` taps this tab and asserts
/// that title regardless of what the underlying providers do, the same shape
/// `RecipeListScreen` already survives.
///
/// Phone-first vertical list of day cards -- not a 7-column grid, which would
/// not fit a phone's width (Phase 7 part 4, the Garden "Plan -- week"
/// layout). A day with entries, and today always, is an expanded card: its
/// entries grouped by slot, then one bottom-right `+ Add meal` that opens the
/// slot chooser (Phase 7 part 11 dropped the per-slot `+ <Slot>` buttons). A
/// week-view day with nothing planned collapses to one compact `+ Add meal`
/// row. Tapping is the primary, tested way to add or move
/// an entry; long-press-drag is offered alongside it as a shortcut, not as the
/// only path (D53). The drag carries the entry itself, and it lands on a
/// filled slot's group or on a collapsed day -- which keeps the entry's own
/// slot, since a collapsed day shows none.
///
/// A meal plan is live data, not a snapshot (unlike the shopping list, D13) --
/// so unlike `ShoppingListScreen`, there is no split locale here. Every date
/// label and every string on this screen renders in the reader's own locale,
/// `AppLocalizations.of(context).localeName` throughout (Phase 3 part 6).
///
/// Today (the default) or This week -- Phase 5's own answer to "the plan
/// always opens on a whole week" (one of the six frictions the phase's intro
/// names). Local `setState` state, not a provider, on `recipe_list_screen
/// .dart`'s precedent for a screen's own ephemeral view selection.
class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

enum _PlanView { today, week }

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  _PlanView _view = _PlanView.today;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<MealPlanWeek> week = ref.watch(mealPlanEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPlan),
        actions: <Widget>[
          if (_view == _PlanView.week)
            IconButton(
              tooltip: l10n.thisWeekTooltip,
              icon: const Icon(Icons.today_outlined),
              onPressed: () => ref.read(visibleWeekProvider.notifier).today(),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SegmentedButton<_PlanView>(
              expandedInsets: EdgeInsets.zero,
              segments: <ButtonSegment<_PlanView>>[
                ButtonSegment<_PlanView>(
                  value: _PlanView.today,
                  label: Text(l10n.todayViewLabel),
                ),
                ButtonSegment<_PlanView>(
                  value: _PlanView.week,
                  label: Text(l10n.weekViewLabel),
                ),
              ],
              selected: <_PlanView>{_view},
              onSelectionChanged: (Set<_PlanView> selection) {
                setState(() => _view = selection.first);
                if (selection.first == _PlanView.today) {
                  ref.read(visibleWeekProvider.notifier).today();
                }
              },
            ),
          ),
          if (_view == _PlanView.week) const _WeekBar(),
          if (week.isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: week.when(
              loading: () => const SizedBox.shrink(),
              error: (Object e, _) =>
                  AppErrorView(message: localizedErrorMessage(e, l10n)),
              data: (MealPlanWeek plan) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(mealPlanEditorProvider),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    const _SavedCopyLine(),
                    if (_view == _PlanView.week)
                      for (
                        int i = 0;
                        i < plan.week.days.length;
                        i++
                      ) ...<Widget>[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        _DayCard(day: plan.week.days[i], plan: plan),
                      ]
                    else
                      _DayCard(
                        day: DateTime.now(),
                        plan: plan,
                        showFullDate: true,
                        alwaysExpanded: true,
                      ),
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
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlanWeek week = ref.watch(visibleWeekProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: l10n.previousWeekTooltip,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(visibleWeekProvider.notifier).previous(),
          ),
          Expanded(
            child: Text(
              weekRangeLabel(week.start, week.end, l10n.localeName),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: l10n.nextWeekTooltip,
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(visibleWeekProvider.notifier).next(),
          ),
        ],
      ),
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
/// reach the server at all" (D76). Same key as the shopping list's own copy
/// of this line (`savedCopyOfflineMessage`) -- byte-identical text, one
/// definition.
///
/// `onSurfaceVariant`, not `error`: offline is an ordinary state in this app,
/// not a fault (`KitchenColors.offline`'s rule, Phase 7 part 4).
class _SavedCopyLine extends ConsumerWidget {
  const _SavedCopyLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool offline =
        ref.watch(networkStatusProvider) == Reachability.offline;
    if (!offline) return const SizedBox.shrink();

    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        l10n.savedCopyOfflineMessage,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

void _showFailure(BuildContext context, AppFailure e) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
}

/// Pick a recipe (or a note) for [day]/[slot] and write it -- what the slot
/// chooser runs once a slot is picked.
Future<void> _add(
  BuildContext context,
  WidgetRef ref,
  DateTime day,
  MealSlot slot,
) async {
  final RecipePick? pick = await showRecipePicker(context);
  if (pick == null || !context.mounted) return;

  try {
    final MealPlanEditor editor = ref.read(mealPlanEditorProvider.notifier);
    switch (pick) {
      case PickRecipe(:final recipe):
        if (slot == MealSlot.snack) {
          final int repeatCount = await editor.snackRepeatCount(
            recipeId: recipe.id,
            entryDate: day,
          );
          if (!context.mounted) return;
          if (shouldWarnOnRepeat(repeatCount)) {
            final bool proceed = await _confirmRepeat(context, repeatCount);
            if (!proceed || !context.mounted) return;
          }
        }
        await editor.addRecipe(entryDate: day, slot: slot, recipeId: recipe.id);
      case PickNote(:final note):
        await editor.addNote(entryDate: day, slot: slot, note: note);
    }
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    _showFailure(context, e);
  }
}

/// Advisory only -- `snack_variety.dart`'s check never blocks the write,
/// it only asks first. Cancelling here writes nothing; the caller checks
/// `context.mounted` again after this returns either way.
Future<bool> _confirmRepeat(BuildContext context, int repeatCount) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final bool? proceed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(l10n.snackRepeatWarningTitle),
      content: Text(
        l10n.snackRepeatWarningBody(l10n.snackSlotCount(repeatCount)),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.addAnywayButton),
        ),
      ],
    ),
  );
  return proceed ?? false;
}

/// A drop, from any of the three drop targets.
Future<void> _moveHere(
  BuildContext context,
  WidgetRef ref,
  MealPlanEntry entry,
  DateTime day,
  MealSlot slot,
) async {
  try {
    await ref
        .read(mealPlanEditorProvider.notifier)
        .moveEntry(entryId: entry.id, entryDate: day, slot: slot);
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    _showFailure(context, e);
  }
}

/// Which slot to add into, when the tap did not already say: a collapsed
/// day's `+ Add meal`, and an expanded day's trailing `+`.
Future<MealSlot?> _showSlotChooser(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  return showModalBottomSheet<MealSlot>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.addMealButton,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final MealSlot slot in MealSlot.ordered)
            ListTile(
              title: Text(mealSlotLabel(slot, l10n)),
              onTap: () => Navigator.of(context).pop(slot),
            ),
        ],
      ),
    ),
  );
}

Future<void> _chooseSlotThenAdd(
  BuildContext context,
  WidgetRef ref,
  DateTime day,
) async {
  final MealSlot? slot = await _showSlotChooser(context);
  if (slot == null || !context.mounted) return;
  await _add(context, ref, day, slot);
}

/// One day. Expanded -- entries by slot, then the add row -- when it has
/// anything planned, when it is today, or when the caller forces it (the
/// Today view); otherwise one compact row with `+ Add meal`.
class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.day,
    required this.plan,
    this.showFullDate = false,
    this.alwaysExpanded = false,
  });

  final DateTime day;
  final MealPlanWeek plan;

  /// Whether the header carries the month (`shortDateLabel`) instead of just
  /// the weekday (`weekdayAndDay`). The Today view sets this: there is no
  /// week around a lone day card to disambiguate the month, the same
  /// argument `_showLeftoverDialog` already makes for its 14-day list.
  final bool showFullDate;

  /// The Today view's card never collapses, even with nothing planned.
  final bool alwaysExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isToday = isSameDate(day, DateTime.now());
    final Map<MealSlot, List<MealPlanEntry>> bySlot =
        <MealSlot, List<MealPlanEntry>>{
          for (final MealSlot slot in MealSlot.ordered)
            slot: plan.entriesFor(day, slot),
        };
    final bool hasEntries = bySlot.values.any(
      (List<MealPlanEntry> e) => e.isNotEmpty,
    );

    if (!alwaysExpanded && !isToday && !hasEntries) {
      return _collapsed(context, ref);
    }
    return _expanded(context, ref, isToday, bySlot);
  }

  Widget _header(BuildContext context, {required bool isToday}) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            showFullDate
                ? shortDateLabel(day, l10n.localeName)
                : weekdayAndDay(day, l10n.localeName),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (isToday) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          const _TodayPill(),
        ],
      ],
    );
  }

  /// A drop here keeps the entry's own slot: a collapsed day shows no slots
  /// to aim at.
  Widget _collapsed(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DragTarget<MealPlanEntry>(
      onAcceptWithDetails: (DragTargetDetails<MealPlanEntry> details) =>
          _moveHere(context, ref, details.data, day, details.data.slot),
      builder: (BuildContext context, List<MealPlanEntry?> candidate, _) =>
          Card(
            color: candidate.isEmpty ? scheme.surface : scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.md,
                end: AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(child: _header(context, isToday: false)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: AppSizes.iconInButton),
                    label: Text(l10n.addMealButton),
                    onPressed: () => _chooseSlotThenAdd(context, ref, day),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _expanded(
    BuildContext context,
    WidgetRef ref,
    bool isToday,
    Map<MealSlot, List<MealPlanEntry>> bySlot,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    final List<MealSlot> filled = <MealSlot>[
      for (final MealSlot slot in MealSlot.ordered)
        if (bySlot[slot]!.isNotEmpty) slot,
    ];

    return Card(
      shape: isToday
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              side: BorderSide(color: kitchen.today, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _header(context, isToday: isToday),
            for (final MealSlot slot in filled) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              _SlotGroup(
                day: day,
                slot: slot,
                entries: bySlot[slot]!,
                plan: plan,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            // One way in, bottom-right, the collapsed day's button: the slot
            // chooser asks which meal, so an empty slot needs no button of
            // its own.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: AppSizes.iconInButton),
                label: Text(l10n.addMealButton),
                onPressed: () => _chooseSlotThenAdd(context, ref, day),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `Danas` / `Today`, beside today's header.
class _TodayPill extends StatelessWidget {
  const _TodayPill();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: kitchen.today,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(
          AppLocalizations.of(context).todayViewLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

/// A filled slot's entries, and the drop target for that day/slot. The
/// highlight goes on the entry cards themselves -- their own fill would
/// otherwise hide one drawn behind them.
class _SlotGroup extends ConsumerWidget {
  const _SlotGroup({
    required this.day,
    required this.slot,
    required this.entries,
    required this.plan,
  });

  final DateTime day;
  final MealSlot slot;
  final List<MealPlanEntry> entries;
  final MealPlanWeek plan;

  /// A leftover's source, only when it is in the loaded week -- no extra
  /// query for a day that is not on screen anyway.
  MealPlanEntry? _sourceOf(MealPlanEntry entry) {
    final String? sourceId = entry.leftoverOfEntryId;
    if (sourceId == null) return null;
    return plan.entries
        .where((MealPlanEntry e) => e.id == sourceId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      DragTarget<MealPlanEntry>(
        onAcceptWithDetails: (DragTargetDetails<MealPlanEntry> details) =>
            _moveHere(context, ref, details.data, day, slot),
        builder: (BuildContext context, List<MealPlanEntry?> candidate, _) =>
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < entries.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _MealEntryCard(
                    entry: entries[i],
                    index: i,
                    total: entries.length,
                    source: _sourceOf(entries[i]),
                    highlighted: candidate.isNotEmpty,
                  ),
                ],
              ],
            ),
      );
}

/// What to show as the card's title: the recipe's title for a recipe entry,
/// the note text for a note entry, and the leftover sentence for a leftover --
/// it must not read as a second helping cooked from scratch. `MealPlanEntry`
/// used to define this itself (`label`), until D92 caught up with it here
/// too: a pure Dart domain model cannot reach `AppLocalizations`, so it moved
/// presentation-side, same shape as `mealSlotLabel`. No `default` arm.
String _entryLabel(MealPlanEntry entry, AppLocalizations l10n) =>
    switch (entry.entryKind) {
      MealEntryKind.recipe =>
        entry.recipeTitle ?? l10n.recipeDetailFallbackTitle,
      MealEntryKind.leftover => l10n.leftoverEntryLabel(
        entry.recipeTitle ?? l10n.recipeDetailFallbackTitle,
      ),
      MealEntryKind.note => entry.note ?? '',
    };

enum _EntryAction { open, servings, leftovers, move, up, down, remove }

/// One planned meal, nested in its day card. No photo or monogram: an entry
/// carries a recipe's title and servings, not the recipe (D53).
///
/// A leftover is the same card with a dashed `outline` border and a leading
/// return icon in `KitchenColors.leftover`, so it never reads as a second
/// meal cooked from scratch.
class _MealEntryCard extends ConsumerWidget {
  const _MealEntryCard({
    required this.entry,
    required this.index,
    required this.total,
    required this.source,
    required this.highlighted,
  });

  final MealPlanEntry entry;

  /// This card's position and the slot's size, both computed by the caller
  /// from the same ordered list `entriesFor` already returns -- so *Move up*
  /// / *Move down* can be shown only where there is somewhere to go, without
  /// a second definition of "first" / "last" in this file.
  final int index;
  final int total;

  /// A leftover's source entry, when it is in the loaded week.
  final MealPlanEntry? source;

  /// Whether a drag is over this card's slot group.
  final bool highlighted;

  Future<void> _openActions(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final _EntryAction? action = await showModalBottomSheet<_EntryAction>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (entry.recipeId != null)
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: Text(l10n.openRecipeMenuItem),
                onTap: () => Navigator.of(context).pop(_EntryAction.open),
              ),
            if (entry.entryKind == MealEntryKind.recipe)
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text(l10n.cookingForMenuItem),
                subtitle: Text(
                  entry.servings == null
                      ? l10n.asTheRecipeSaysLabel
                      : '${entry.servings}',
                ),
                onTap: () => Navigator.of(context).pop(_EntryAction.servings),
              ),
            if (entry.entryKind == MealEntryKind.recipe)
              ListTile(
                leading: const Icon(Icons.replay_outlined),
                title: Text(l10n.planLeftoversMenuItem),
                onTap: () => Navigator.of(context).pop(_EntryAction.leftovers),
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l10n.moveToMenuItem),
              onTap: () => Navigator.of(context).pop(_EntryAction.move),
            ),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: Text(l10n.moveUpMenuItem),
                onTap: () => Navigator.of(context).pop(_EntryAction.up),
              ),
            if (index < total - 1)
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: Text(l10n.moveDownMenuItem),
                onTap: () => Navigator.of(context).pop(_EntryAction.down),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.removeTooltip),
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
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int? recipeServings = entry.recipeServings;
    int? selected = entry.servings;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: Text(l10n.cookingForDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<int?>(
                initialValue: selected,
                decoration: InputDecoration(labelText: l10n.servingsFieldLabel),
                items: <DropdownMenuItem<int?>>[
                  DropdownMenuItem<int?>(
                    child: Text(
                      recipeServings == null
                          ? l10n.asTheRecipeSaysLabel
                          : l10n.asTheRecipeSaysWithCount(recipeServings),
                    ),
                  ),
                  for (int n = 1; n <= 20; n++)
                    DropdownMenuItem<int?>(value: n, child: Text('$n')),
                ],
                onChanged: (int? value) => setState(() => selected = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                recipeServings == null
                    ? l10n.servingsUnknownExplanation
                    : l10n.servingsScalesExplanation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.saveButton),
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
      _showFailure(context, e);
    }
  }

  Future<void> _showMoveDialog(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlanWeek week = ref.read(visibleWeekProvider);
    DateTime selectedDay = entry.entryDate;
    MealSlot selectedSlot = entry.slot;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: Text(l10n.moveToDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<DateTime>(
                initialValue: selectedDay,
                decoration: InputDecoration(labelText: l10n.dayFieldLabel),
                items: <DropdownMenuItem<DateTime>>[
                  for (final DateTime day in week.days)
                    DropdownMenuItem<DateTime>(
                      value: day,
                      child: Text(weekdayAndDay(day, l10n.localeName)),
                    ),
                ],
                onChanged: (DateTime? value) {
                  if (value != null) setState(() => selectedDay = value);
                },
              ),
              DropdownButtonFormField<MealSlot>(
                initialValue: selectedSlot,
                decoration: InputDecoration(labelText: l10n.slotFieldLabel),
                items: <DropdownMenuItem<MealSlot>>[
                  for (final MealSlot slot in MealSlot.ordered)
                    DropdownMenuItem<MealSlot>(
                      value: slot,
                      child: Text(mealSlotLabel(slot, l10n)),
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
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.moveButton),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(mealPlanEditorProvider.notifier)
          .moveEntry(
            entryId: entry.id,
            entryDate: selectedDay,
            slot: selectedSlot,
          );
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      _showFailure(context, e);
    }
  }

  /// Same `StatefulBuilder` + two dropdowns shape as [_showMoveDialog], but
  /// the day list is 14 consecutive dates from [entry]'s own date rather than
  /// the visible week's 7 -- a leftover's range is D56's "next 14 days from
  /// the source", not bounded by what happens to be on screen, and it can
  /// cross a month boundary, hence [shortDateLabel] rather than
  /// [weekdayAndDay].
  Future<void> _showLeftoverDialog(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
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
          title: Text(l10n.planLeftoversDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<DateTime>(
                initialValue: selectedDay,
                decoration: InputDecoration(labelText: l10n.dayFieldLabel),
                items: <DropdownMenuItem<DateTime>>[
                  for (final DateTime day in candidateDays)
                    DropdownMenuItem<DateTime>(
                      value: day,
                      child: Text(shortDateLabel(day, l10n.localeName)),
                    ),
                ],
                onChanged: (DateTime? value) {
                  if (value != null) setState(() => selectedDay = value);
                },
              ),
              DropdownButtonFormField<MealSlot>(
                initialValue: selectedSlot,
                decoration: InputDecoration(labelText: l10n.slotFieldLabel),
                items: <DropdownMenuItem<MealSlot>>[
                  for (final MealSlot slot in MealSlot.ordered)
                    DropdownMenuItem<MealSlot>(
                      value: slot,
                      child: Text(mealSlotLabel(slot, l10n)),
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
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.addButton),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(mealPlanEditorProvider.notifier)
          .addLeftover(
            sourceEntryId: entry.id,
            entryDate: selectedDay,
            slot: selectedSlot,
          );
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      _showFailure(context, e);
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int newPosition,
  ) async {
    try {
      await ref
          .read(mealPlanEditorProvider.notifier)
          .reorderEntry(entryId: entry.id, newPosition: newPosition);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      _showFailure(context, e);
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(mealPlanEditorProvider.notifier).removeEntry(entry.id);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      _showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) =>
        LongPressDraggable<MealPlanEntry>(
          data: entry,
          feedback: SizedBox(
            width: constraints.maxWidth,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: _card(context, null),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: _card(context, null)),
          child: _card(context, () => _openActions(context, ref)),
        ),
  );

  Widget _card(BuildContext context, VoidCallback? onTap) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    final Color fill = highlighted
        ? scheme.primaryContainer
        : scheme.surfaceContainerLowest;

    final Widget body = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (entry.isLeftover) ...<Widget>[
              Icon(
                Icons.replay_outlined,
                size: AppSizes.iconInButton,
                color: kitchen.leftover,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppMetaRow(items: _meta(context)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _entryLabel(entry, AppLocalizations.of(context)),
                    // A note reads as a meal like any other, so it wears a
                    // recipe title's face; the meta row says it is a note.
                    style: theme.extension<KitchenType>()!.recipeTitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!entry.isLeftover) {
      return Card(color: fill, child: body);
    }
    return CustomPaint(
      foregroundPainter: _DashedRoundedRectPainter(
        color: scheme.outline,
        radius: AppRadii.md,
      ),
      child: Card(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: body,
      ),
    );
  }

  /// The slot, then the facts this entry has. An [AppMetaRow], never a
  /// ` · `-joined string (D119).
  List<Widget> _meta(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final int? servings = entry.servings ?? entry.recipeServings;
    final MealPlanEntry? source = this.source;
    return <Widget>[
      Text(
        mealSlotLabel(entry.slot, l10n),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      if (entry.entryKind == MealEntryKind.recipe && servings != null)
        AppMetaItem(
          icon: Icons.soup_kitchen_outlined,
          label: l10n.recipeServingsCount(servings),
        ),
      if (entry.entryKind == MealEntryKind.note)
        AppMetaItem(
          icon: Icons.edit_note_outlined,
          label: l10n.mealEntryNoteLabel,
        ),
      // The abbreviated weekday on purpose: a full Serbian weekday would
      // have to be declined after `od`, and a generated date cannot be.
      if (entry.isLeftover && source != null)
        AppMetaItem(
          icon: Icons.event_outlined,
          label: l10n.leftoverFromDay(
            weekdayAndDay(source.entryDate, l10n.localeName),
          ),
        ),
    ];
  }
}

/// A 1dp rounded rectangle drawn as dashes, for a leftover's border.
///
/// `_DashedRingPainter`'s approach (`ingredient_line_row.dart`) along an
/// `RRect` instead of a circle: Flutter has no dashed border, and CLAUDE.md
/// rule 8 says a package is not the answer to twenty lines of geometry.
class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final Path border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(paint.strokeWidth / 2),
          Radius.circular(radius),
        ),
      );
    for (final PathMetric metric in border.computeMetrics()) {
      for (double d = 0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
