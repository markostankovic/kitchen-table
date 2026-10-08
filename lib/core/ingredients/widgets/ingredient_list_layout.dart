import '../../../features/recipes/domain/recipe_draft.dart';

/// The ingredient list's children, as [IngredientLinesEditor] lays them out:
/// a heading is its own item, not part of its first line's child, so a line
/// can be dropped between a heading and the line under it, and join that
/// group.
///
/// Item indices are what `ReorderableListView.onReorderItem` delivers. They
/// are mapped back to line indices here, never in the widget, which is what
/// lets the drop rules be tested without a widget tree.
///
/// Pure Dart: no Flutter import.
sealed class IngredientListItem {
  const IngredientListItem();
}

/// The line at [lineIndex].
final class LineItem extends IngredientListItem {
  const LineItem(this.lineIndex);

  final int lineIndex;

  @override
  bool operator ==(Object other) =>
      other is LineItem && other.lineIndex == lineIndex;

  @override
  int get hashCode => lineIndex.hashCode;

  @override
  String toString() => 'LineItem($lineIndex)';
}

/// A section heading over the lines `[start, end)`: its **visual run**, up
/// to the next heading. The run includes D156's null-continuation lines,
/// because they read as part of the group.
///
/// [section] is the trimmed name, or null for a heading open with no name
/// yet.
final class HeadingItem extends IngredientListItem {
  const HeadingItem(this.start, this.end, this.section);

  final int start;
  final int end;
  final String? section;

  @override
  bool operator ==(Object other) =>
      other is HeadingItem &&
      other.start == start &&
      other.end == end &&
      other.section == section;

  @override
  int get hashCode => Object.hash(start, end, section);

  @override
  String toString() => 'HeadingItem($start, $end, $section)';
}

String? _sectionOf(RecipeDraftLine line) {
  final String? section = line.section?.trim();
  return section == null || section.isEmpty ? null : section;
}

/// The list's items, in order.
///
/// A heading goes before line `i` when `i` starts a group (D156: its section
/// is set and differs from the line before's), **or** when it is
/// [openHeadingLineId] -- a heading open for naming, which must stay a
/// heading while its name is blank or, mid-word, equal to the group above.
List<IngredientListItem> ingredientListItems(
  List<RecipeDraftLine> lines, {
  int? openHeadingLineId,
}) {
  bool headed(int i) {
    if (lines[i].localId == openHeadingLineId) return true;
    final String? section = _sectionOf(lines[i]);
    return section != null && (i == 0 || section != _sectionOf(lines[i - 1]));
  }

  final List<int> starts = <int>[
    for (int i = 0; i < lines.length; i++)
      if (headed(i)) i,
  ];
  final List<IngredientListItem> items = <IngredientListItem>[];
  int next = 0;
  for (int i = 0; i < lines.length; i++) {
    if (next < starts.length && starts[next] == i) {
      next++;
      items.add(
        HeadingItem(
          i,
          next < starts.length ? starts[next] : lines.length,
          _sectionOf(lines[i]),
        ),
      );
    }
    items.add(LineItem(i));
  }
  return items;
}

/// A line's drop, in line terms: the indices for [RecipeDraft.moveLine], and
/// the section the line takes there.
typedef LineDrop = ({int oldIndex, int newIndex, String? section});

/// Resolves a [LineItem] moved from [oldItem] to [newItem] (`onReorderItem`'s
/// indices, [newItem] already adjusted for the lifted child).
///
/// The line lands at the matching line index and takes the section of the
/// nearest heading above it, or null above the first one.
LineDrop resolveLineDrop(
  List<IngredientListItem> items,
  int oldItem,
  int newItem,
) {
  final LineItem moved = items[oldItem] as LineItem;
  final List<IngredientListItem> rest = List<IngredientListItem>.of(items)
    ..removeAt(oldItem);
  int newIndex = 0;
  String? section;
  for (final IngredientListItem item in rest.take(newItem)) {
    switch (item) {
      case LineItem():
        newIndex++;
      case HeadingItem(section: final String? s):
        section = s;
    }
  }
  return (oldIndex: moved.lineIndex, newIndex: newIndex, section: section);
}

/// Resolves a [HeadingItem] moved from [oldItem] to [newItem], as the line
/// index its run should sit before ([RecipeDraft.moveLines]'s `newIndex`),
/// or null for no move.
///
/// The run is still in the list while its heading is dragged (collapsed, so
/// item indices stay valid), and may land only on a **group boundary**: the
/// top of the list, or the end of a group -- the headingless top block
/// counts as one. A drop inside another group snaps to the nearest boundary,
/// ties going down, so a section can never split a group and leave a
/// duplicate heading behind. A drop inside its own run is no move.
///
/// The top of the list is a boundary only when no headingless block is
/// there. Lines without a section read as part of the group above them
/// (D156), so a run dropped above that block would take it in -- found on
/// the device walk.
int? resolveRunDrop(List<IngredientListItem> items, int oldItem, int newItem) {
  final HeadingItem moved = items[oldItem] as HeadingItem;
  final List<IngredientListItem> rest = List<IngredientListItem>.of(items)
    ..removeAt(oldItem);
  final int dropAt = rest.take(newItem).whereType<LineItem>().length;

  final int lineCount = items.whereType<LineItem>().length;
  // Every group ends where the next heading starts, or at the end.
  final List<int> boundaries = <int>{
    if (items.first is HeadingItem) 0,
    for (final HeadingItem h in items.whereType<HeadingItem>()) h.start,
    lineCount,
  }.toList()..sort();

  int snapped = boundaries.first;
  for (final int b in boundaries) {
    // `<=`: on a tie the later boundary wins -- ties go down the list.
    if ((b - dropAt).abs() <= (snapped - dropAt).abs()) snapped = b;
  }
  if (snapped >= moved.start && snapped <= moved.end) return null;
  return snapped;
}
