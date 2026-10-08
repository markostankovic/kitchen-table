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
  const _Harness({required this.initial, required this.review});

  final RecipeDraft initial;
  final bool review;

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
            IngredientLinesEditor(
              lines: _draft.lines,
              locale: 'sr',
              units: _units,
              parser: IngredientLineParser(_units),
              review: widget.review,
              flagged: const <int>{},
              onReplace: (RecipeDraftLine l) => _set(_draft.replaceLine(l)),
              onRemove: (int id) => _set(_draft.removeLine(id)),
              onReorder: (int a, int b) => _set(_draft.reorderLines(a, b)),
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

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

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
}
