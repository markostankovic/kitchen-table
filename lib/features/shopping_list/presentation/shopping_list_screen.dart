import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/ingredients/ingredient_catalog_providers.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/net/network_status.dart';
import '../../ingredients/domain/unit_catalog.dart';
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
/// screen.** `_ListBody` -- category headings, `_GeneratedAt`'s dates, item
/// quantities -- is a document that was generated in one language, and reads
/// `list.locale` (`shopping_lists.locale`, migration 16: "the list is already
/// a document in one language; remembering which one is what stops a list
/// generated in Serbian rendering half-translated after a locale toggle").
/// The chrome around it -- this `AppBar`, `_RangeBar` (which describes the
/// list about to be generated, not the one on screen), `_EmptyState`, every
/// snackbar and every error -- reads the reader's own locale,
/// `AppLocalizations.of(context)` straight from the ambient one, same as
/// every other screen. `_ItemTile` already drew this line for unit names
/// (`formatItemQuantity(q, units, locale: locale)`) before this part; this is
/// that same argument generalized to the rest of the document.
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
              error: (Object e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(localizedErrorMessage(e, l10n)),
                ),
              ),
              data: (ShoppingList? current) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(currentShoppingListProvider),
                child: current == null
                    ? const _EmptyState()
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

/// Which dates the next list will cover, and the two shortcuts that cover
/// almost every case. Chrome -- this describes the list about to be
/// generated, not the one on screen, so it reads the reader's locale even
/// while `_ListBody` below it is reading `list.locale`.
class _RangeBar extends ConsumerWidget {
  const _RangeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ({DateTime from, DateTime to}) range = ref.watch(
      shoppingRangeProvider,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${shortDateLabel(range.from, l10n.localeName)} – '
              '${shortDateLabel(range.to, l10n.localeName)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(shoppingRangeProvider.notifier).thisWeek(),
            child: Text(l10n.thisWeekButton),
          ),
          TextButton(
            onPressed: () =>
                ref.read(shoppingRangeProvider.notifier).nextWeek(),
            child: Text(l10n.nextWeekButton),
          ),
          IconButton(
            tooltip: l10n.pickDatesTooltip,
            icon: const Icon(Icons.date_range_outlined),
            onPressed: () => _pickRange(context, ref, range),
          ),
        ],
      ),
    );
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

/// Chrome -- the reader's locale, same as [_RangeBar].
class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ListView(
      children: <Widget>[
        const SizedBox(height: 64),
        const Center(child: Icon(Icons.checklist_outlined, size: 56)),
        const SizedBox(height: 16),
        Center(child: Text(l10n.noListYetTitle)),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.noListYetBody,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: () => _generate(context, ref),
            icon: const Icon(Icons.playlist_add_check_outlined),
            label: Text(l10n.generateListButton),
          ),
        ),
      ],
    );
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

    final AsyncValue<UnitCatalog> catalogAsync = ref.watch(
      unitCatalogProvider,
    );
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
      children: <Widget>[
        _GeneratedAt(list: list, bodyL10n: bodyL10n),
        if (toBuy.isEmpty && staples.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              bodyL10n.nothingToBuyMessage,
              textAlign: TextAlign.center,
            ),
          ),
        for (final CategoryGroup group in groupByCategory(toBuy, bodyL10n)) ...<Widget>[
          _CategoryHeading(label: group.label),
          for (final ShoppingItem item in group.items)
            _ItemTile(item: item, units: units, locale: list.locale),
        ],
        if (staples.isNotEmpty)
          // Collapsed, never hidden. Nothing is missing from the snapshot
          // itself -- the pantry flag changes where a line appears, not
          // whether it exists.
          ExpansionTile(
            title: Text(bodyL10n.probablyHaveHeading(staples.length)),
            subtitle: Text(bodyL10n.cupboardStaplesSubtitle),
            children: <Widget>[
              for (final ShoppingItem item in staples)
                _ItemTile(item: item, units: units, locale: list.locale),
            ],
          ),
        const SizedBox(height: 24),
      ],
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool offline =
        ref.watch(networkStatusProvider) == Reachability.offline;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            bodyL10n.generatedForRangeLine(
              shortDateLabel(list.generatedAt, list.locale),
              shortDateLabel(list.dateFrom, list.locale),
              shortDateLabel(list.dateTo, list.locale),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (offline)
            Text(
              l10n.savedCopyOfflineMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item, required this.units, required this.locale});

  final ShoppingItem item;
  final UnitCatalog units;

  /// The LIST's own stored locale (`list.locale`, D81's own fix applied one
  /// layer over) -- not the reader's current `appLocaleProvider`. A
  /// generated list is a snapshot; rendering its count units in whatever
  /// language the reader happens to be in today would half-translate a
  /// document that `shopping_lists.locale` exists precisely to keep
  /// consistent (migration 16's own comment). Before this fix the parameter
  /// did not exist and `formatItemQuantity` fell through to its `'sr'`
  /// default regardless of who generated the list or in what language.
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `480 ml + 300 g` -- two families on one line, never converted into each
    // other (D9). An item with no quantities at all shows only its raw lines,
    // which is rule 3 working rather than failing.
    final String quantities = item.quantities
        .map((ItemQuantity q) => formatItemQuantity(q, units, locale: locale))
        .join(' + ');

    return ListTile(
      dense: true,
      title: Text(item.displayName),
      subtitle: item.unmatchedLines.isEmpty
          ? null
          : Text(
              item.unmatchedLines.join('\n'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: quantities.isEmpty
          ? null
          : Text(quantities, style: Theme.of(context).textTheme.titleSmall),
      onLongPress: item.ingredientId == null
          ? null
          : () => _togglePantry(context, ref),
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
