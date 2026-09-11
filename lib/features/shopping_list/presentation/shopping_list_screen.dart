import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/ingredients/ingredient_catalog_providers.dart';
import '../../ingredients/domain/unit_catalog.dart';
import '../../meal_plan/domain/plan_week.dart';
import '../application/shopping_list_providers.dart';
import '../domain/format_item_quantity.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list.dart';

/// The generated shopping list.
///
/// The `AppBar` is built outside the body's `AsyncValue.when` and titled
/// exactly `List` -- `test/core/router/app_shell_test.dart` taps this tab and
/// asserts that title regardless of what the underlying providers do, the
/// same shape `MealPlanScreen` and `RecipeListScreen` already survive.
///
/// There are no checkboxes here and there never will be. D13 made the list a
/// snapshot rather than a live document, and that single decision is what
/// removes offline writes, the outbox and last-write-wins reasoning from the
/// entire app (D12). A cook reading this in a shop is reading, not editing.
class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ShoppingList?> list = ref.watch(
      currentShoppingListProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('List'),
        actions: <Widget>[
          if (list.value != null)
            IconButton(
              tooltip: 'Regenerate',
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => _generate(context, ref),
            ),
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
                  child: Text(e is AppFailure ? e.message : e.toString()),
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
/// in one place rather than being repeated per call site.
Future<void> _generate(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(currentShoppingListProvider.notifier).generate();
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Which dates the next list will cover, and the two shortcuts that cover
/// almost every case.
class _RangeBar extends ConsumerWidget {
  const _RangeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({DateTime from, DateTime to}) range = ref.watch(
      shoppingRangeProvider,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${shortDateLabel(range.from)} – ${shortDateLabel(range.to)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(shoppingRangeProvider.notifier).thisWeek(),
            child: const Text('This week'),
          ),
          TextButton(
            onPressed: () =>
                ref.read(shoppingRangeProvider.notifier).nextWeek(),
            child: const Text('Next'),
          ),
          IconButton(
            tooltip: 'Pick dates',
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

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    children: <Widget>[
      const SizedBox(height: 64),
      const Center(child: Icon(Icons.checklist_outlined, size: 56)),
      const SizedBox(height: 16),
      const Center(child: Text('No list yet.')),
      const SizedBox(height: 8),
      const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Generate one from what you have planned for these dates.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      const SizedBox(height: 24),
      Center(
        child: FilledButton.icon(
          onPressed: () => _generate(context, ref),
          icon: const Icon(Icons.playlist_add_check_outlined),
          label: const Text('Generate list'),
        ),
      ),
    ],
  );
}

class _ListBody extends ConsumerWidget {
  const _ListBody({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UnitCatalog units =
        ref.watch(unitCatalogProvider).value ?? UnitCatalog.empty();

    final List<ShoppingItem> toBuy = list.toBuy;
    final List<ShoppingItem> staples = list.probablyHave;

    return ListView(
      children: <Widget>[
        _GeneratedAt(list: list),
        if (toBuy.isEmpty && staples.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nothing to buy -- there was nothing planned for these dates.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final MapEntry<String, List<ShoppingItem>> group in _byCategory(
          toBuy,
        ).entries) ...<Widget>[
          _CategoryHeading(label: group.key),
          for (final ShoppingItem item in group.value)
            _ItemTile(item: item, units: units),
        ],
        if (staples.isNotEmpty)
          // Collapsed, never hidden. Nothing is missing from the snapshot
          // itself -- the pantry flag changes where a line appears, not
          // whether it exists.
          ExpansionTile(
            title: Text('Probably have (${staples.length})'),
            subtitle: const Text('Cupboard staples'),
            children: <Widget>[
              for (final ShoppingItem item in staples)
                _ItemTile(item: item, units: units),
            ],
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Groups by `ingredients.category`, with uncategorised items last under a
  /// neutral heading rather than being dropped or shuffled in.
  Map<String, List<ShoppingItem>> _byCategory(List<ShoppingItem> items) {
    final Map<String, List<ShoppingItem>> groups =
        <String, List<ShoppingItem>>{};
    for (final ShoppingItem item in items) {
      groups
          .putIfAbsent(item.category ?? 'Other', () => <ShoppingItem>[])
          .add(item);
    }

    final List<String> keys = groups.keys.toList()
      ..sort((String a, String b) {
        if (a == 'Other') return 1;
        if (b == 'Other') return -1;
        return a.compareTo(b);
      });
    return <String, List<ShoppingItem>>{
      for (final String key in keys) key: groups[key]!,
    };
  }
}

class _GeneratedAt extends ConsumerWidget {
  const _GeneratedAt({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: Text(
      'Generated ${shortDateLabel(list.generatedAt)} '
      'for ${shortDateLabel(list.dateFrom)} – ${shortDateLabel(list.dateTo)}',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
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
  const _ItemTile({required this.item, required this.units});

  final ShoppingItem item;
  final UnitCatalog units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `480 ml + 300 g` -- two families on one line, never converted into each
    // other (D9). An item with no quantities at all shows only its raw lines,
    // which is rule 3 working rather than failing.
    final String quantities = item.quantities
        .map((ItemQuantity q) => formatItemQuantity(q, units))
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowStaple
              ? '${item.displayName} marked as always in the cupboard. '
                    'Takes effect next time you generate.'
              : '${item.displayName} will be on the list from now on.',
        ),
      ),
    );
  }
}
