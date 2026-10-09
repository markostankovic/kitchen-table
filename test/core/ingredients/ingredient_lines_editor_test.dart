import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_line_field.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_line_row.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_lines_editor.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/recipes/widgets/recipe_group_heading.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/ingredients/data/ingredient_repository.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_line_parser.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';

/// The shared ingredient list (D157): rows that open one at a time, fast
/// entry (D159), the pill on closed rows (D160) and section headings (D156).
/// Driven through the real draft operations and the real parser, with the
/// catalog stubbed by provider override -- no mocking package (rule 8).

final UnitCatalog _units = UnitCatalog(
  units: const <Unit>[
    Unit(code: 'g', family: UnitFamily.mass, toBase: 1, isMetric: true),
  ],
  aliases: const <String, String>{'g': 'g'},
  displayNames: const <String, String>{'g|sr': 'g'},
);

const IngredientMatch _brasno = IngredientMatch(
  ingredientId: 'i-brasno',
  displayName: 'brašno',
  matchedName: 'brašno',
  matchedLocale: 'sr',
  matchMethod: MatchMethod.alias,
  confidence: 1,
  // Above the bar on purpose: a closed row must still only offer it.
  autoAccept: true,
  isVerified: true,
);

class _FakeCatalog implements IngredientRepository {
  final List<(String, String)> linked = <(String, String)>[];

  @override
  Future<bool> linkAlias(
    String ingredientId,
    String aliasName, {
    String locale = 'sr',
  }) async {
    linked.add((ingredientId, aliasName));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Holds the draft the way both screens' notifiers do.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.initial,
    required this.review,
    this.withOtherField = false,
  });

  final RecipeDraft initial;
  final bool review;

  /// A text field and a plain label above the list: the rest of the screen,
  /// for focus to sit in and for taps to land outside the open line.
  final bool withOtherField;

  @override
  State<_Harness> createState() => _HarnessState();
}

late RecipeDraft _draft;

class _HarnessState extends State<_Harness> {
  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _set(RecipeDraft next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(
          children: <Widget>[
            if (widget.withOtherField) ...<Widget>[
              const TextField(key: Key('otherField')),
              const SizedBox(
                height: 80,
                child: Text('outside', key: Key('outside')),
              ),
            ],
            IngredientLinesEditor(
              lines: _draft.lines,
              locale: 'sr',
              units: _units,
              parser: IngredientLineParser(_units),
              review: widget.review,
              flagged: const <int>{},
              onReplace: (RecipeDraftLine l) => _set(_draft.replaceLine(l)),
              onRemove: (int id) => _set(_draft.removeLine(id)),
              onMoveLine: (int a, int b, String? section) =>
                  _set(_draft.moveLine(a, b, section: section)),
              onMoveRun: (int start, int end, int to) =>
                  _set(_draft.moveLines(start, end, to)),
              onSetSections: (Map<int, String?> m) =>
                  _set(_draft.setSections(m)),
              onInsertAfter: (int id) {
                _set(_draft.insertLineAfter(id));
                final int at = _draft.lines
                    .indexWhere((RecipeDraftLine l) => l.localId == id);
                return _draft.lines[at + 1].localId;
              },
              onAdd: () {
                _set(_draft.addLine());
                return _draft.lines.last.localId;
              },
            ),
          ],
        ),
      );
}

final List<String> _searched = <String>[];

Future<_FakeCatalog> _pump(
  WidgetTester tester,
  List<RecipeDraftLine> lines, {
  bool review = false,
  bool withOtherField = false,
  Map<String, List<IngredientMatch>> matches =
      const <String, List<IngredientMatch>>{},
}) async {
  _searched.clear();
  final _FakeCatalog catalog = _FakeCatalog();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ingredientCatalogProvider.overrideWithValue(catalog),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
        lineParserProvider
            .overrideWith((Ref ref) async => IngredientLineParser(_units)),
        ingredientMatchesProvider.overrideWith(
          (Ref ref, (String, {String locale}) arg) async {
            if (arg.$1.isNotEmpty) _searched.add(arg.$1);
            return matches[arg.$1] ?? const <IngredientMatch>[];
          },
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: _Harness(
          initial: RecipeDraft(lines: lines),
          review: review,
          withOtherField: withOtherField,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return catalog;
}

RecipeDraftLine _line(
  int id,
  String text, {
  String? section,
  bool matched = true,
}) =>
    RecipeDraftLine(
      localId: id,
      rawText: text,
      section: section,
      ingredientId: matched ? 'i$id' : null,
      displayName: matched ? text : null,
      matchMethod: matched ? MatchMethod.manual : null,
    );

Finder get _field => find.byType(IngredientLineField);

IngredientLineField _open(WidgetTester tester) =>
    tester.widget<IngredientLineField>(_field);

EditableText _editable(WidgetTester tester) => tester.widget<EditableText>(
      find.descendant(of: _field, matching: find.byType(EditableText)),
    );

EditableText _other(WidgetTester tester) => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('otherField')),
        matching: find.byType(EditableText),
      ),
    );

List<String> _texts() =>
    _draft.lines.map((RecipeDraftLine l) => l.rawText).toList();

void main() {
  testWidgets('a saved list opens as rows, and a tap opens one, focused', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <RecipeDraftLine>[
      _line(0, 'brašno'),
      _line(1, 'so'),
    ]);

    expect(_field, findsNothing);
    expect(find.byType(IngredientLineRow), findsNWidgets(2));

    await tester.tap(find.byType(IngredientLineRow).first);
    await tester.pumpAndSettle();

    expect(_field, findsOneWidget);
    expect(_open(tester).line.localId, 0);
    expect(_editable(tester).focusNode.hasFocus, isTrue);
  });

  testWidgets('only one line is open at a time', (WidgetTester tester) async {
    await _pump(tester, <RecipeDraftLine>[
      _line(0, 'brašno'),
      _line(1, 'so'),
    ]);

    await tester.tap(find.byType(IngredientLineRow).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IngredientLineRow).first);
    await tester.pumpAndSettle();

    expect(_field, findsOneWidget);
    expect(_open(tester).line.localId, 1);
  });

  testWidgets('Next on a line inserts a blank one after it and opens it, '
      'keeping the keyboard', (WidgetTester tester) async {
    await _pump(tester, <RecipeDraftLine>[
      _line(0, 'brašno', section: 'Za testo'),
      _line(1, 'so'),
    ]);
    await tester.tap(find.byType(IngredientLineRow).first);
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(_texts(), <String>['brašno', '', 'so']);
    expect(_draft.lines[1].section, 'Za testo');
    expect(_open(tester).line.localId, _draft.lines[1].localId);
    expect(_editable(tester).focusNode.hasFocus, isTrue);
  });

  testWidgets('Next on a blank line closes it and removes it', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <RecipeDraftLine>[_line(0, 'brašno')]);
    await tester.tap(find.byType(IngredientLineRow).first);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(_texts(), <String>['brašno', '']);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(_texts(), <String>['brašno']);
    expect(_field, findsNothing);
  });

  testWidgets('Backspace on an empty line removes it and opens the one '
      'above, caret at the end', (WidgetTester tester) async {
    await _pump(tester, <RecipeDraftLine>[_line(0, 'brašno')]);
    await tester.tap(find.byType(IngredientLineRow).first);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(_texts(), <String>['brašno']);
    expect(_open(tester).line.localId, 0);
    final EditableText editable = _editable(tester);
    expect(editable.focusNode.hasFocus, isTrue);
    expect(
      editable.controller.selection,
      const TextSelection.collapsed(offset: 'brašno'.length),
    );
  });

  testWidgets('Backspace on an empty first line does nothing', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <RecipeDraftLine>[
      const RecipeDraftLine(localId: 0, rawText: ''),
      _line(1, 'so'),
    ]);
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(_texts(), <String>['', 'so']);
  });

  testWidgets('a sole blank line renders open, unfocused, and stays', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <RecipeDraftLine>[
      const RecipeDraftLine(localId: 0, rawText: ''),
    ]);

    expect(_field, findsOneWidget);
    expect(_editable(tester).focusNode.hasFocus, isFalse);

    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(_texts(), <String>['']);
    expect(_field, findsOneWidget);
    expect(_editable(tester).focusNode.hasFocus, isFalse);
  });

  testWidgets('Add ingredient appends a line, opens it and focuses it', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <RecipeDraftLine>[_line(0, 'brašno')]);

    await tester.tap(find.text('Add ingredient'));
    await tester.pumpAndSettle();

    expect(_texts(), <String>['brašno', '']);
    expect(_open(tester).line.localId, _draft.lines.last.localId);
    expect(_editable(tester).focusNode.hasFocus, isTrue);
  });

  testWidgets('closed matched rows never search', (WidgetTester tester) async {
    await _pump(
      tester,
      <RecipeDraftLine>[_line(0, '200 g brašno'), _line(1, 'so')],
      matches: <String, List<IngredientMatch>>{
        'brašno': <IngredientMatch>[_brasno],
      },
    );

    expect(_searched, isEmpty);
    expect(find.byKey(const Key('ingredientSuggestionPill')), findsNothing);
  });

  testWidgets('a closed unmatched row offers the pill and never '
      'auto-accepts, even above the bar', (WidgetTester tester) async {
    await _pump(
      tester,
      <RecipeDraftLine>[_line(0, '200 g brašno', matched: false)],
      matches: <String, List<IngredientMatch>>{
        'brašno': <IngredientMatch>[_brasno],
      },
    );

    expect(_searched, <String>['brašno']);
    expect(find.byKey(const Key('ingredientSuggestionPill')), findsOneWidget);
    expect(find.text('brašno?'), findsOneWidget);
    // Opening a saved recipe must not change a line nobody touched.
    expect(_draft.lines.single.isMatched, isFalse);
  });

  testWidgets('tapping the pill on a closed row confirms it as manual', (
    WidgetTester tester,
  ) async {
    final _FakeCatalog catalog = await _pump(
      tester,
      <RecipeDraftLine>[_line(0, '200 g brašna', matched: false)],
      matches: <String, List<IngredientMatch>>{
        'brašna': <IngredientMatch>[_brasno],
      },
    );

    await tester.tap(find.byKey(const Key('ingredientSuggestionPill')));
    await tester.pumpAndSettle();

    final RecipeDraftLine line = _draft.lines.single;
    expect(line.ingredientId, 'i-brasno');
    expect(line.matchMethod, MatchMethod.manual);
    expect(line.matchConfidence, 1);
    expect(catalog.linked, <(String, String)>[('i-brasno', 'brašna')]);
    expect(find.byKey(const Key('ingredientSuggestionPill')), findsNothing);
    // Still closed: confirming is not editing.
    expect(_field, findsNothing);
  });

  testWidgets('headings follow D156 runs, and a group drops its last divider',
      (WidgetTester tester) async {
    await _pump(tester, <RecipeDraftLine>[
      _line(0, 'brašno', section: 'Za testo'),
      _line(1, 'jaja', section: ' Za testo '),
      _line(2, 'šećer', section: 'Fil'),
      _line(3, 'so'),
      _line(4, 'mleko', section: 'Za testo'),
    ]);

    expect(
      tester
          .widgetList<RecipeGroupHeading>(find.byType(RecipeGroupHeading))
          .map((RecipeGroupHeading h) => h.text),
      <String>['Za testo', 'Fil', 'Za testo'],
    );
    // jaja ends its group, so (a null section continues Fil, headingless)
    // ends before the second Za testo, and mleko ends the list.
    final List<bool> dividers = tester
        .widgetList<IngredientLineRow>(find.byType(IngredientLineRow))
        .map((IngredientLineRow r) => r.showDivider)
        .toList();
    expect(dividers, <bool>[true, false, true, false, false]);
  });

  testWidgets('the editor style has a grip and no inset', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <RecipeDraftLine>[_line(0, 'brašno')]);

    expect(find.byKey(const Key('ingredientLineGrip')), findsOneWidget);
    expect(
      tester.widget<IngredientLineRow>(find.byType(IngredientLineRow)).inset,
      isFalse,
    );
  });

  testWidgets('the review style has no grip and is inset', (
    WidgetTester tester,
  ) async {
    await _pump(tester, <RecipeDraftLine>[_line(0, 'brašno')], review: true);

    expect(find.byKey(const Key('ingredientLineGrip')), findsNothing);
    expect(
      tester.widget<IngredientLineRow>(find.byType(IngredientLineRow)).inset,
      isTrue,
    );
  });

  group('closing without ✕', () {
    testWidgets('a tap outside closes the open line and keeps its text', (
      WidgetTester tester,
    ) async {
      await _pump(tester, withOtherField: true, <RecipeDraftLine>[
        _line(0, 'brašno'),
        _line(1, 'so'),
      ]);
      await tester.tap(find.byType(IngredientLineRow).first);
      await tester.pumpAndSettle();
      await tester.enterText(_field, '200 g brašna');
      await tester.pump();

      await tester.tap(find.byKey(const Key('outside')));
      await tester.pumpAndSettle();

      expect(_field, findsNothing);
      expect(_texts(), <String>['200 g brašna', 'so']);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('a blank line closed by a tap outside is removed', (
      WidgetTester tester,
    ) async {
      await _pump(tester, withOtherField: true, <RecipeDraftLine>[
        _line(0, 'brašno'),
      ]);
      await tester.tap(find.text('Add ingredient'));
      await tester.pumpAndSettle();
      expect(_texts(), <String>['brašno', '']);

      await tester.tap(find.byKey(const Key('outside')));
      await tester.pumpAndSettle();

      expect(_texts(), <String>['brašno']);
      expect(_field, findsNothing);
    });

    testWidgets('a drag outside is a scroll and leaves the line open', (
      WidgetTester tester,
    ) async {
      await _pump(tester, withOtherField: true, <RecipeDraftLine>[
        _line(0, 'brašno'),
      ]);
      await tester.tap(find.byType(IngredientLineRow).first);
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const Key('outside')), const Offset(0, -40));
      await tester.pumpAndSettle();

      expect(_field, findsOneWidget);
    });

    testWidgets('another field taking focus closes the open line', (
      WidgetTester tester,
    ) async {
      await _pump(tester, withOtherField: true, <RecipeDraftLine>[
        _line(0, 'brašno'),
      ]);
      await tester.tap(find.byType(IngredientLineRow).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('otherField')));
      await tester.pumpAndSettle();

      expect(_field, findsNothing);
      expect(_other(tester).focusNode.hasFocus, isTrue);
    });

    testWidgets('a tap on a row takes the focus from another field', (
      WidgetTester tester,
    ) async {
      await _pump(tester, withOtherField: true, <RecipeDraftLine>[
        _line(0, 'brašno'),
      ]);
      await tester.tap(find.byKey(const Key('otherField')));
      await tester.pumpAndSettle();
      expect(_other(tester).focusNode.hasFocus, isTrue);

      await tester.tap(find.byType(IngredientLineRow).first);
      await tester.pumpAndSettle();

      expect(_editable(tester).focusNode.hasFocus, isTrue);
      expect(_other(tester).focusNode.hasFocus, isFalse);
    });

    testWidgets('the picker over the line does not close it', (
      WidgetTester tester,
    ) async {
      await _pump(tester, withOtherField: true, <RecipeDraftLine>[
        _line(0, 'brašno'),
      ]);
      await tester.tap(find.byType(IngredientLineRow).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ingredientLinePreview')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.byType(BottomSheet));
      await tester.pumpAndSettle();
      expect(_field, findsOneWidget);

      // The barrier dismisses the sheet; that tap is not the line's either.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(_field, findsOneWidget);
    });

    testWidgets('a tap outside closes an open heading and keeps its name', (
      WidgetTester tester,
    ) async {
      await _pump(tester, withOtherField: true, <RecipeDraftLine>[
        _line(0, 'brašno', section: 'Za testo'),
      ]);
      await tester.tap(find.text('Za testo'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(IngredientLinesEditor),
          matching: find.byType(EditableText),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('outside')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(IngredientLinesEditor),
          matching: find.byType(EditableText),
        ),
        findsNothing,
      );
      expect(_draft.lines.single.section, 'Za testo');
    });
  });

  group('sections', () {
    Finder headingField() => find.descendant(
          of: find.byKey(const Key('ingredientSectionBox')),
          matching: find.byType(EditableText),
        );

    List<String?> sections() =>
        _draft.lines.map((RecipeDraftLine l) => l.section).toList();

    testWidgets('Add section, a name and Next leave the cursor in a blank '
        'line in that section', (WidgetTester tester) async {
      await _pump(tester, <RecipeDraftLine>[_line(0, 'brašno')]);

      await tester.tap(find.text('Add section'));
      await tester.pumpAndSettle();

      expect(headingField(), findsOneWidget);
      expect(
        tester.widget<EditableText>(headingField()).focusNode.hasFocus,
        isTrue,
      );
      // The blank line under it shows open, unfocused.
      expect(_open(tester).line.localId, _draft.lines.last.localId);

      await tester.enterText(headingField(), 'Za fil');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(_texts(), <String>['brašno', '']);
      expect(sections(), <String?>[null, 'Za fil']);
      expect(headingField(), findsNothing);
      expect(
        tester
            .widgetList<RecipeGroupHeading>(find.byType(RecipeGroupHeading))
            .map((RecipeGroupHeading h) => h.text),
        <String>['Za fil'],
      );
      expect(_open(tester).line.localId, _draft.lines.last.localId);
      expect(_editable(tester).focusNode.hasFocus, isTrue);

      // Fast entry carries on inside the section (D159).
      await tester.enterText(find.byType(EditableText), 'šećer');
      // A frame between the keystroke and Next, as on a device.
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(sections(), <String?>[null, 'Za fil', 'Za fil']);
    });

    testWidgets('tapping a heading opens it, and one thing is open at a time',
        (WidgetTester tester) async {
      await _pump(tester, <RecipeDraftLine>[
        _line(0, 'brašno', section: 'Za testo'),
        _line(1, 'so'),
        _line(2, 'šećer', section: 'Fil'),
      ]);

      await tester.tap(find.byType(IngredientLineRow).first);
      await tester.pumpAndSettle();
      expect(_field, findsOneWidget);

      await tester.tap(find.text('Za testo'));
      await tester.pumpAndSettle();
      expect(_field, findsNothing);
      expect(headingField(), findsOneWidget);

      // Every line of the run follows a rename, the null continuation too.
      await tester.enterText(headingField(), 'Kore');
      await tester.pump();
      expect(sections(), <String?>['Kore', 'Kore', 'Fil']);

      await tester.tap(find.byType(IngredientLineRow).last);
      await tester.pumpAndSettle();
      expect(headingField(), findsNothing);
      expect(_open(tester).line.localId, 2);
    });

    testWidgets('✕ on a heading joins its lines to the group above, and Undo '
        'restores them', (WidgetTester tester) async {
      await _pump(tester, <RecipeDraftLine>[
        _line(0, 'brašno', section: 'Za testo'),
        _line(1, 'so'),
        _line(2, 'šećer', section: 'Fil'),
        _line(3, 'orasi', section: 'Fil'),
      ]);

      await tester.tap(find.text('Fil'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.ancestor(
          of: find.byKey(const Key('ingredientSectionBox')),
          matching: find.byType(Row),
        ),
        matching: find.byIcon(Icons.close),
      ));
      await tester.pumpAndSettle();

      expect(_texts(), <String>['brašno', 'so', 'šećer', 'orasi']);
      expect(sections(), <String?>['Za testo', null, 'Za testo', 'Za testo']);
      expect(find.text('Section removed.'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(sections(), <String?>['Za testo', null, 'Fil', 'Fil']);
    });

    testWidgets('a heading closed blank is removed, and Undo brings back its '
        'old name', (WidgetTester tester) async {
      await _pump(tester, <RecipeDraftLine>[
        _line(0, 'brašno'),
        _line(1, 'šećer', section: 'Fil'),
      ]);

      await tester.tap(find.text('Fil'));
      await tester.pumpAndSettle();
      await tester.enterText(headingField(), '');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(sections(), <String?>[null, null]);
      expect(find.text('Section removed.'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(sections(), <String?>[null, 'Fil']);
    });

    testWidgets('closing a blank new heading shows no snackbar', (
      WidgetTester tester,
    ) async {
      await _pump(tester, <RecipeDraftLine>[_line(0, 'brašno')]);

      await tester.tap(find.text('Add section'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IngredientLineRow));
      await tester.pumpAndSettle();

      expect(headingField(), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      // The blank line under it followed the blank-line rule.
      expect(_texts(), <String>['brašno']);
    });

    testWidgets('a dragged heading lifts with its rows, under the finger', (
      WidgetTester tester,
    ) async {
      await _pump(tester, <RecipeDraftLine>[
        _line(0, 'brašno'),
        _line(1, 'šećer', section: 'Fil'),
        _line(2, 'orasi', section: 'Fil'),
      ]);
      final Finder grip = find.byKey(const Key('ingredientSectionGrip'));
      final Offset start = tester.getCenter(grip);

      final TestGesture gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -10));
      await tester.pumpAndSettle();

      // The proxy: the lifted Material holding the heading and its rows.
      final Finder proxy = find.byWidgetPredicate(
        (Widget w) => w is Material && w.elevation == 3,
      );
      expect(proxy, findsOneWidget);
      expect(
        find.descendant(of: proxy, matching: find.text('Fil')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: proxy, matching: find.byType(IngredientLineRow)),
        findsNWidgets(2),
      );
      // Its grip stays by the finger -- within the drag's slop -- rather
      // than thrown off-screen, as a second OverflowBox once did.
      final Offset lifted = tester.getCenter(
        find.descendant(of: proxy, matching: grip),
      );
      expect((lifted.dy - (start.dy - 30)).abs(), lessThan(24));
      expect((lifted.dx - start.dx).abs(), lessThan(2));
      expect(tester.takeException(), isNull);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the editor gives a heading a grip; review does not', (
      WidgetTester tester,
    ) async {
      await _pump(tester, <RecipeDraftLine>[_line(0, 'brašno', section: 'F')]);
      expect(find.byKey(const Key('ingredientSectionGrip')), findsOneWidget);

      await _pump(
        tester,
        <RecipeDraftLine>[_line(0, 'brašno', section: 'F')],
        review: true,
      );
      expect(find.byKey(const Key('ingredientSectionGrip')), findsNothing);
    });
  });
}
