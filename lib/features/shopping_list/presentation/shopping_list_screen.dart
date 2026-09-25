import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/ingredients/ingredient_catalog_providers.dart';
import '../../../core/ingredients/widgets/ingredient_line_row.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/net/network_status.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/kitchen_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../ingredients/domain/unit_catalog.dart';
import '../../meal_plan/domain/plan_week.dart';
import '../application/shopping_list_providers.dart';
import '../domain/format_item_quantity.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list.dart';
import 'shopping_list_text.dart';

/// The generated shopping list.
///
/// The `AppBar` is built outside the body's `AsyncValue.when` and titled from
/// `AppLocalizations.navList` -- the same key the bottom nav label uses (D77,
/// Phase 3 part 1), so this screen's own header and its tab always agree on
/// language. `test/core/router/app_shell_test.dart` taps this tab and asserts
/// that title regardless of what the underlying providers do, the same shape
/// `MealPlanScreen` and `RecipeListScreen` already survive.
///
/// There are no checkboxes here and there never will be. D13 made the list a
/// snapshot rather than a live document, and that single decision is what
/// removes offline writes, the outbox and last-write-wins reasoning from the
/// entire app (D12). A cook reading this in a shop is reading, not editing.
///
/// **Two locales render at once here (Phase 3 part 6), unlike every other
/// screen.** `_ListBody` -- `_GeneratedAt`'s dates, the "Probably have"
/// count, item quantities -- is a document that was generated in one
/// language, and reads
/// `list.locale` (`shopping_lists.locale`, migration 16: "the list is already
/// a document in one language; remembering which one is what stops a list
/// generated in Serbian rendering half-translated after a locale toggle").
/// The chrome around it -- this `AppBar`, `_RangeBar` (which describes the
/// list about to be generated, not the one on screen), `AppEmptyState`,
/// every snackbar and every error -- reads the reader's own locale,
/// `AppLocalizations.of(context)` straight from the ambient one, same as
/// every other screen. `_ItemRow` already drew this line for unit names
/// (`formatItemQuantityParts(q, units, locale: locale)`) before this part;
/// this is that same argument generalized to the rest of the document.
/// `_DocumentLanguageTag` (Phase 7 part 5) is what makes the split legible:
/// its code is the document's language, its sentence the reader's.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<ShoppingList?> list = ref.watch(
      currentShoppingListProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navList),
        actions: <Widget>[
          if (list.value != null) ...<Widget>[
            IconButton(
              tooltip: l10n.copyListTooltip,
              icon: const Icon(Icons.copy_outlined),
              onPressed: () => _copy(context, ref, list.value!),
            ),
            IconButton(
              tooltip: l10n.regenerateTooltip,
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => _generate(context, ref),
            ),
          ],
        ],
      ),
      body: Column(
        children: <Widget>[
          const _RangeBar(),
          if (list.isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: list.when(
              loading: () => const SizedBox.shrink(),
              error: (Object e, _) =>
                  AppErrorView(message: localizedErrorMessage(e, l10n)),
              data: (ShoppingList? current) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(currentShoppingListProvider),
                child: current == null
                    ? AppEmptyState(
                        icon: Icons.checklist_outlined,
                        title: l10n.noListYetTitle,
                        body: l10n.noListYetBody,
                        action: FilledButton.icon(
                          onPressed: () => _generate(context, ref),
                          icon: const Icon(Icons.playlist_add_check_outlined),
                          label: Text(l10n.generateListButton),
                        ),
                      )
                    : _ListBody(list: current),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generating is the one write this screen makes, so the error handling lives
/// in one place rather than being repeated per call site. Chrome -- the
/// reader's locale.
Future<void> _generate(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(currentShoppingListProvider.notifier).generate();
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
  }
}

/// Copies the current list as plain text (D105) to the clipboard.
///
/// The text is built from [list]'s own `list.locale` (the two-locale rule,
/// D94/D86) -- it is the document, same as `_ListBody`, not the chrome
/// around it. The tooltip and this confirmation SnackBar are chrome, so
/// they read the reader's own locale via `AppLocalizations.of(context)`,
/// re-read after the `await` on `household_screen.dart`'s own precedent.
Future<void> _copy(
  BuildContext context,
  WidgetRef ref,
  ShoppingList list,
) async {
  final UnitCatalog units =
      ref.read(unitCatalogProvider).value ?? UnitCatalog.empty();
  final AppLocalizations bodyL10n = lookupAppLocalizations(
    Locale(list.locale),
  );
  final String text = formatShoppingListAsText(list, units, bodyL10n);

  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  final AppLocalizations l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(l10n.listCopiedSnackbar)));
}

/// The range bar's three segments. Never stored: [_RangeBar] derives which
/// one is selected from `shoppingRangeProvider` on every build, so the
/// selection cannot disagree with the range the next list will cover.
enum _RangeChoice { thisWeek, nextWeek, custom }

/// Which dates the next list will cover, and the two shortcuts that cover
/// almost every case. Chrome -- this describes the list about to be
/// generated, not the one on screen, so it reads the reader's locale even
/// while `_ListBody` below it is reading `list.locale`.
///
/// The range text used to share the button row and wrapped to three lines in
/// Serbian (Phase 7 part 2). It now lives on its own line under the segments,
/// and only when it tells the reader something the list on screen does not:
/// no list yet, or a selected range that differs from the list's own.
class _RangeBar extends ConsumerWidget {
  const _RangeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ({DateTime from, DateTime to}) range = ref.watch(
      shoppingRangeProvider,
    );
    final ShoppingList? current = ref.watch(currentShoppingListProvider).value;
    final _RangeChoice selected = _choiceFor(range);

    final bool showRangeLine =
        current == null ||
        !isSameDate(current.dateFrom, range.from) ||
        !isSameDate(current.dateTo, range.to);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SegmentedButton<_RangeChoice>(
            segments: <ButtonSegment<_RangeChoice>>[
              ButtonSegment<_RangeChoice>(
                value: _RangeChoice.thisWeek,
                label: Text(l10n.thisWeekButton),
              ),
              ButtonSegment<_RangeChoice>(
                value: _RangeChoice.nextWeek,
                label: Text(l10n.nextWeekButton),
              ),
              ButtonSegment<_RangeChoice>(
                value: _RangeChoice.custom,
                icon: const Icon(
                  Icons.date_range_outlined,
                  size: AppSizes.iconInButton,
                ),
                label: Text(l10n.pickDatesSegment),
                tooltip: l10n.pickDatesTooltip,
              ),
            ],
            selected: <_RangeChoice>{selected},
            // No check on the selected segment: each gets ~109dp at phone
            // width, and the check pushed `Ova nedelja` / `This week` onto
            // two lines in both languages (Phase 7 part 5's device walk).
            // The `secondaryContainer` fill already says which is selected.
            showSelectedIcon: false,
            // A single-select SegmentedButton does not fire for a tap on the
            // segment that is already selected. Allowing an empty selection
            // turns that tap into an empty set, which is how a second custom
            // range gets picked after the first.
            emptySelectionAllowed: true,
            onSelectionChanged: (Set<_RangeChoice> next) {
              if (next.isEmpty) {
                if (selected == _RangeChoice.custom) {
                  _pickRange(context, ref, range);
                }
                // Otherwise a no-op: the derived selection re-renders as is.
                return;
              }
              final ShoppingRange notifier = ref.read(
                shoppingRangeProvider.notifier,
              );
              switch (next.single) {
                case _RangeChoice.thisWeek:
                  notifier.thisWeek();
                case _RangeChoice.nextWeek:
                  notifier.nextWeek();
                case _RangeChoice.custom:
                  _pickRange(context, ref, range);
              }
            },
          ),
          if (showRangeLine) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.nextListRangeLine(
                shortDateLabel(range.from, l10n.localeName),
                shortDateLabel(range.to, l10n.localeName),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// This week and next are recognised by value, so a range picked by hand
  /// that happens to be exactly next week reads as `nextWeek` -- which is
  /// what it is.
  static _RangeChoice _choiceFor(({DateTime from, DateTime to}) range) {
    final PlanWeek thisWeek = PlanWeek.of(DateTime.now());
    bool covers(PlanWeek week) =>
        isSameDate(range.from, week.start) && isSameDate(range.to, week.end);
    if (covers(thisWeek)) return _RangeChoice.thisWeek;
    if (covers(thisWeek.next)) return _RangeChoice.nextWeek;
    return _RangeChoice.custom;
  }

  Future<void> _pickRange(
    BuildContext context,
    WidgetRef ref,
    ({DateTime from, DateTime to}) current,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(current.from.year - 1),
      lastDate: DateTime(current.to.year + 2),
      initialDateRange: DateTimeRange(start: current.from, end: current.to),
    );
    if (picked == null) return;
    ref
        .read(shoppingRangeProvider.notifier)
        .setRange(from: picked.start, to: picked.end);
  }
}

class _ListBody extends ConsumerWidget {
  const _ListBody({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The snapshot's own locale (the two-locale rule) -- never the reader's
    // ambient one. `lookupAppLocalizations` on `core/ingredients/widgets/
    // ingredient_line_field.dart`'s own precedent (D86: a value stored in one
    // language is read back in that language, not the chrome's).
    final AppLocalizations bodyL10n = lookupAppLocalizations(
      Locale(list.locale),
    );
    final ThemeData theme = Theme.of(context);

    final AsyncValue<UnitCatalog> catalogAsync = ref.watch(unitCatalogProvider);
    // A loading catalog with no value yet is not the same as an empty one
    // (rule 3): the former is "still finding out", the latter renders every
    // quantity unscaled and every count unit in its raw code (`3 clove`
    // instead of `3 čen`). `unitCatalogProvider` only ever settles into
    // `UnitCatalog.empty()`'s territory once both the network and the cache
    // have genuinely come up with nothing (Phase 2 part 5).
    if (catalogAsync.isLoading && !catalogAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final UnitCatalog units = catalogAsync.value ?? UnitCatalog.empty();

    final List<ShoppingItem> toBuy = list.toBuy;
    final List<ShoppingItem> staples = list.probablyHave;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: <Widget>[
        _GeneratedAt(list: list, bodyL10n: bodyL10n),
        const SizedBox(height: AppSpacing.sm),
        _DocumentLanguageTag(locale: list.locale),
        const SizedBox(height: AppSpacing.lg),
        if (toBuy.isEmpty && staples.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              bodyL10n.nothingToBuyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        if (toBuy.isNotEmpty) _toBuyCard(bodyL10n, units),
        if (toBuy.isNotEmpty && staples.isNotEmpty)
          const SizedBox(height: AppSpacing.md),
        if (staples.isNotEmpty)
          // Collapsed, never hidden. Nothing is missing from the snapshot
          // itself -- the pantry flag changes where a line appears, not
          // whether it exists.
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              title: Text(
                bodyL10n.probablyHaveHeading(staples.length),
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                bodyL10n.cupboardStaplesSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children: <Widget>[
                for (int i = 0; i < staples.length; i++)
                  _ItemRow(
                    item: staples[i],
                    units: units,
                    locale: list.locale,
                    showDivider: i < staples.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// One card for everything to buy. Items stay grouped and ordered by
  /// category through `groupByCategory`, shared with the clipboard export,
  /// but no heading renders -- on screen or in the export (D105, amended
  /// 2026-09-21: headings were noise when scanning a list in a shop). The
  /// Garden mock draws them; the decision wins. A `md` gap between blocks is
  /// all that shows the grouping.
  ///
  /// Every row keeps its hairline except the card's last, where the card's
  /// own edge does the separating. Dropping the hairline at the end of each
  /// block as well was tried first and failed on the device (Phase 7 part 5's
  /// walk): most real categories hold one item, so the few hairlines left
  /// looked arbitrary and the gaps read as uneven row spacing, not as groups.
  /// A hairline on every row keeps the rhythm even, so the gap stands out.
  Widget _toBuyCard(AppLocalizations bodyL10n, UnitCatalog units) {
    final List<CategoryGroup> groups = groupByCategory(list.toBuy, bodyL10n);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int g = 0; g < groups.length; g++) ...<Widget>[
              if (g > 0) const SizedBox(height: AppSpacing.md),
              for (int i = 0; i < groups[g].items.length; i++)
                _ItemRow(
                  item: groups[g].items[i],
                  units: units,
                  locale: list.locale,
                  showDivider: g < groups.length - 1 ||
                      i < groups[g].items.length - 1,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GeneratedAt extends ConsumerWidget {
  const _GeneratedAt({required this.list, required this.bodyL10n});

  final ShoppingList list;

  /// The snapshot's own `list.locale`, already resolved by the caller
  /// (`_ListBody` looks it up once, not per widget).
  final AppLocalizations bodyL10n;

  /// This widget's own claim is narrower than [OfflineBanner]'s (Phase 2
  /// part 6b, D76): it renders exclusively when a list is on screen, which
  /// is exactly the "cache hit" half of `ShoppingListRepository.watchLatest`
  /// (Phase 2 part 5), and says "this is not what the server has right now"
  /// -- the banner says "the phone cannot reach the server at all". Neither
  /// replaces the other: the banner is a session-wide fact, this line is a
  /// provenance claim about the data actually on screen.
  ///
  /// Its own date line renders in [bodyL10n] (`list.locale`, the two-locale
  /// rule -- this is the snapshot's own provenance, part of the document).
  /// The offline sub-line beneath it does not: whether the READER is
  /// offline right now is a fact about them, not about the document, so it
  /// reads `AppLocalizations.of(context)` like the rest of the chrome, same
  /// key as `MealPlanScreen`'s `_SavedCopyLine`.
  ///
  /// `onSurfaceVariant`, not `error`: offline is an ordinary state in this
  /// app, not a fault (`_SavedCopyLine`'s precedent, Phase 7 part 4).
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool offline =
        ref.watch(networkStatusProvider) == Reachability.offline;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          bodyL10n.generatedForRangeLine(
            shortDateLabel(list.generatedAt, list.locale),
            shortDateLabel(list.dateFrom, list.locale),
            shortDateLabel(list.dateTo, list.locale),
          ),
          style: style,
        ),
        if (offline) Text(l10n.savedCopyOfflineMessage, style: style),
      ],
    );
  }
}

/// `SR · Ova lista je na srpskom` -- what makes D94 legible. The code is
/// `list.locale`, the document's own language; the sentence is chrome, in the
/// reader's locale, because it tells the reader something about the document.
///
/// Always shown while a list is on screen, not only when the two locales
/// differ: it is calm, and a tag that appears only sometimes reads as a
/// warning. Before it existed, a list generated in English read under a
/// Serbian UI as "untranslated strings" (Phase 7 part 1's report) when it
/// was D94 working as designed.
class _DocumentLanguageTag extends StatelessWidget {
  const _DocumentLanguageTag({required this.locale});

  /// `list.locale`.
  final String locale;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: kitchen.docLanguage,
          shape: StadiumBorder(
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                locale.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  locale == 'sr' ? l10n.listIsInSerbian : l10n.listIsInEnglish,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One shopping item as an `IngredientLineRow` (D53: this screen is its third
/// consumer, fed primitives like the other two).
///
/// The first quantity goes in the row's quantity column, its unit beside the
/// name. Any further quantity -- a second unit family, never merged into the
/// first (D9) -- goes in the trailer as `+ 300 g`, followed by each unmatched
/// raw line on its own line. An item with no quantities at all shows only
/// its name and raw lines, which is rule 3 working rather than failing.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.item,
    required this.units,
    required this.locale,
    required this.showDivider,
  });

  final ShoppingItem item;
  final UnitCatalog units;

  /// The LIST's own stored locale (`list.locale`, D81's own fix applied one
  /// layer over) -- not the reader's current `appLocaleProvider`. A
  /// generated list is a snapshot; rendering its count units in whatever
  /// language the reader happens to be in today would half-translate a
  /// document that `shopping_lists.locale` exists precisely to keep
  /// consistent (migration 16's own comment).
  final String locale;

  /// `false` for the last row of a category block or of a card.
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<({String number, String unit})> parts =
        <({String number, String unit})>[
          for (final ItemQuantity q in item.quantities)
            formatItemQuantityParts(q, units, locale: locale),
        ];
    final ({String number, String unit})? first = parts.isEmpty
        ? null
        : parts.first;

    final String trailer = <String>[
      if (parts.length > 1)
        parts
            .skip(1)
            .map(
              (({String number, String unit}) p) => '+ ${p.number} ${p.unit}',
            )
            .join(' '),
      ...item.unmatchedLines,
    ].join('\n');

    return InkWell(
      onLongPress: item.ingredientId == null
          ? null
          : () => _togglePantry(context, ref),
      child: IngredientLineRow(
        quantity: first?.number,
        unit: first?.unit,
        name: item.displayName,
        trailer: trailer.isEmpty ? null : trailer,
        isMatched: item.ingredientId != null,
        // Chrome -- the reader's locale, as on the recipe detail screen.
        unmatchedTooltip: l10n.ingredientNotMatchedTooltip,
        showDivider: showDivider,
      ),
    );
  }

  /// Long-press moves an item in or out of "Probably have" for good.
  ///
  /// Deliberately does not rewrite the list on screen: the snapshot is what it
  /// was when it was generated (D13). The override lands on the next
  /// generation, and the confirmation says so rather than silently
  /// rearranging a document the cook is reading in a shop.
  ///
  /// The confirmation is chrome -- the reader's locale -- even though
  /// `item.displayName` inside it is snapshot data, the same composition
  /// shape `MealPlanScreen`'s `leftoverEntryLabel` uses for a recipe title.
  Future<void> _togglePantry(BuildContext context, WidgetRef ref) async {
    final bool nowStaple = !item.isPantryStaple;
    try {
      await ref
          .read(currentShoppingListProvider.notifier)
          .setPantryPref(
            ingredientId: item.ingredientId!,
            alwaysHave: nowStaple,
          );
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
      return;
    }

    if (!context.mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowStaple
              ? l10n.markedAsStapleSnackbar(item.displayName)
              : l10n.willBeOnListSnackbar(item.displayName),
        ),
      ),
    );
  }
}
