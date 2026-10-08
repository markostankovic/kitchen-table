import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_list_layout.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';

/// The ingredient list's items and drop rules, without a widget tree: a
/// heading is its own item, a dropped line takes the heading above it, and a
/// dragged heading carries its run to a group boundary.

List<RecipeDraftLine> _lines(List<String?> sections) => <RecipeDraftLine>[
      for (final (int i, String? section) in sections.indexed)
        RecipeDraftLine(localId: i, rawText: 'line $i', section: section),
    ];

void main() {
  group('items', () {
    test('with no sections, a flat list of lines', () {
      expect(
        ingredientListItems(_lines(<String?>[null, null, null])),
        const <IngredientListItem>[LineItem(0), LineItem(1), LineItem(2)],
      );
    });

    test('a headingless top block, then a group', () {
      expect(
        ingredientListItems(_lines(<String?>[null, 'Fil', ' Fil '])),
        const <IngredientListItem>[
          LineItem(0),
          HeadingItem(1, 3, 'Fil'),
          LineItem(1),
          LineItem(2),
        ],
      );
    });

    test('a null continuation stays in the run, with no heading', () {
      expect(
        ingredientListItems(_lines(<String?>['Testo', null, 'Fil'])),
        const <IngredientListItem>[
          HeadingItem(0, 2, 'Testo'),
          LineItem(0),
          LineItem(1),
          HeadingItem(2, 3, 'Fil'),
          LineItem(2),
        ],
      );
    });

    test('two non-adjacent groups with the same name each get a heading', () {
      expect(
        ingredientListItems(_lines(<String?>['Testo', 'Fil', 'Testo'])),
        const <IngredientListItem>[
          HeadingItem(0, 1, 'Testo'),
          LineItem(0),
          HeadingItem(1, 2, 'Fil'),
          LineItem(1),
          HeadingItem(2, 3, 'Testo'),
          LineItem(2),
        ],
      );
    });

    test('an open heading is a heading while blank, or equal to the one '
        'above', () {
      expect(
        ingredientListItems(
          _lines(<String?>['Testo', null]),
          openHeadingLineId: 1,
        ),
        const <IngredientListItem>[
          HeadingItem(0, 1, 'Testo'),
          LineItem(0),
          HeadingItem(1, 2, null),
          LineItem(1),
        ],
      );
      expect(
        ingredientListItems(
          _lines(<String?>['Testo', 'Testo']),
          openHeadingLineId: 1,
        ),
        const <IngredientListItem>[
          HeadingItem(0, 1, 'Testo'),
          LineItem(0),
          HeadingItem(1, 2, 'Testo'),
          LineItem(1),
        ],
      );
    });
  });

  group('a line drop', () {
    // 0: line 0 · 1: Fil · 2: line 1 · 3: line 2
    final List<IngredientListItem> items =
        ingredientListItems(_lines(<String?>[null, 'Fil', 'Fil']));

    test('between a heading and its first line joins the group', () {
      // line 0 lifted out leaves [Fil, line 1, line 2]; position 1 is under
      // the heading.
      expect(
        resolveLineDrop(items, 0, 1),
        (oldIndex: 0, newIndex: 0, section: 'Fil'),
      );
    });

    test('above the first heading takes null', () {
      expect(
        resolveLineDrop(items, 3, 0),
        (oldIndex: 2, newIndex: 0, section: null),
      );
      expect(
        resolveLineDrop(items, 3, 1),
        (oldIndex: 2, newIndex: 1, section: null),
      );
    });

    test('to the end of a group keeps the group', () {
      expect(
        resolveLineDrop(items, 2, 3),
        (oldIndex: 1, newIndex: 2, section: 'Fil'),
      );
    });
  });

  group('a run drop', () {
    // Lines: 0 top · 1,2 Testo · 3,4,5 Fil · 6 Krem.
    // Items: 0 L0 · 1 H(1,3) · 2 L1 · 3 L2 · 4 H(3,6) · 5 L3 · 6 L4 · 7 L5 ·
    //        8 H(6,7) · 9 L6.
    final List<IngredientListItem> items = ingredientListItems(
      _lines(<String?>[null, 'Testo', 'Testo', 'Fil', 'Fil', 'Fil', 'Krem']),
    );

    test('to the top works when no headingless block is there', () {
      // Lines: 0 Testo · 1 Fil. Items: 0 H · 1 L0 · 2 H · 3 L1.
      final List<IngredientListItem> headed =
          ingredientListItems(_lines(<String?>['Testo', 'Fil']));
      expect(resolveRunDrop(headed, 2, 0), 0);
    });

    test('never above a headingless top block, which it would take in', () {
      // Krem dropped at the very top lands under line 0, not over it.
      expect(resolveRunDrop(items, 8, 0), 1);
    });

    test('onto a boundary lands there', () {
      // Krem dropped right over Testo's heading: before line 1.
      expect(resolveRunDrop(items, 8, 1), 1);
      // Testo dropped at the very end.
      expect(resolveRunDrop(items, 1, 9), 7);
    });

    test('mid-group snaps to the nearest boundary', () {
      // Krem dropped between Fil's line 3 and line 4: one from Fil's start,
      // two from its end.
      expect(resolveRunDrop(items, 8, 6), 3);
      // Testo dropped between line 4 and line 5: one from Fil's end.
      expect(resolveRunDrop(items, 1, 6), 6);
    });

    test('a tie goes down', () {
      // Lines: 0,1 Testo · 2,3 Fil · 4 Krem. Krem dropped between line 0 and
      // line 1 sits one from each boundary of Testo, and lands at its end.
      final List<IngredientListItem> tied = ingredientListItems(
        _lines(<String?>['Testo', 'Testo', 'Fil', 'Fil', 'Krem']),
      );
      // Items: 0 H · 1 L0 · 2 L1 · 3 H · 4 L2 · 5 L3 · 6 H · 7 L4.
      expect(resolveRunDrop(tied, 6, 2), 2);
    });

    test('inside its own run is no move', () {
      expect(resolveRunDrop(items, 4, 5), isNull);
      expect(resolveRunDrop(items, 4, 4), isNull);
      // A snap back onto its own start is no move either.
      expect(resolveRunDrop(items, 4, 3), isNull);
    });
  });
}
