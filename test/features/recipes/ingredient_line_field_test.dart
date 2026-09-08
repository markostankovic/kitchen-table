import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_line_parser.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/recipes/application/recipe_providers.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';
import 'package:kitchen_table/features/recipes/presentation/widgets/ingredient_line_field.dart';

/// The line editor's three states, driven through the real parser with the
/// catalog stubbed by provider override -- no mocking package (rule 8).

final UnitCatalog _units = UnitCatalog(
  units: const <Unit>[
    Unit(code: 'g', family: UnitFamily.mass, toBase: 1, isMetric: true),
    Unit(code: 'dl', family: UnitFamily.volume, toBase: 100, isMetric: true),
  ],
  aliases: const <String, String>{'g': 'g', 'dl': 'dl'},
  displayNames: const <String, String>{'g|sr': 'g', 'dl|sr': 'dl'},
);

IngredientMatch _sargarepa({required bool autoAccept}) => IngredientMatch(
      ingredientId: 'i1',
      displayName: 'šargarepa',
      matchedName: 'šargarepe',
      matchedLocale: 'sr',
      matchMethod: autoAccept ? MatchMethod.alias : MatchMethod.fuzzy,
      confidence: autoAccept ? 1.0 : 0.5,
      autoAccept: autoAccept,
      isVerified: true,
    );

/// Holds the line the way the editor screen does, so a change reported by the
/// field comes back as new state.
class _Harness extends StatefulWidget {
  const _Harness({required this.initial});

  final RecipeDraftLine initial;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late RecipeDraftLine _line = widget.initial;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IngredientLineField(
          index: 0,
          line: _line,
          locale: 'sr',
          onChanged: (RecipeDraftLine next) => setState(() => _line = next),
          onRemove: () {},
        ),
      );
}

/// Records every term the field actually searched for.
final List<String> _searched = <String>[];

/// [matches] is keyed by search term, so a line whose name changes stops
/// matching what the old name matched -- which is the point of two of the
/// tests below.
Future<void> _pump(
  WidgetTester tester, {
  required Map<String, List<IngredientMatch>> matches,
  RecipeDraftLine? line,
}) async {
  _searched.clear();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        recipeUnitCatalogProvider.overrideWith((Ref ref) async => _units),
        recipeLineParserProvider
            .overrideWith((Ref ref) async => IngredientLineParser(_units)),
        ingredientMatchesProvider.overrideWith(
          (Ref ref, (String, {String locale}) arg) async {
            if (arg.$1.isNotEmpty) _searched.add(arg.$1);
            return matches[arg.$1] ?? const <IngredientMatch>[];
          },
        ),
      ],
      child: MaterialApp(
        home: _Harness(
          initial: line ?? const RecipeDraftLine(localId: 0, rawText: ''),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Types a line and lets the 250 ms debounce elapse.
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextFormField), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty line says nothing at all', (WidgetTester tester) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});

    expect(find.text('No match'), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('the search term is the parsed name, not the whole line',
      (WidgetTester tester) async {
    await _pump(tester, matches: <String, List<IngredientMatch>>{
      'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: true)],
    });

    await _type(tester, '200 g šargarepe');

    // Tier 1 stripped the quantity and the unit before tiers 2 and 3 ever saw
    // the line (D31). The name is the literal remainder -- still genitive,
    // because there is no stemmer (D6).
    expect(_searched, contains('šargarepe'));
    expect(_searched, isNot(contains('200 g šargarepe')));
  });

  testWidgets('an auto-accepted row is adopted and shown as matched',
      (WidgetTester tester) async {
    await _pump(tester, matches: <String, List<IngredientMatch>>{
      'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: true)],
    });

    await _type(tester, '200 g šargarepe');

    // The catalog's word, in the recipe's language -- not what was typed (D1).
    expect(find.textContaining('šargarepa'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    // Quantity and unit come from the parse, rendered in Serbian, alongside
    // the catalog name -- the chip, not the field the cook typed into.
    expect(find.text('200 g · šargarepa'), findsOneWidget);
  });

  testWidgets('a row below auto-accept is offered, not applied',
      (WidgetTester tester) async {
    await _pump(tester, matches: <String, List<IngredientMatch>>{
      'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: false)],
    });

    await _type(tester, '200 g šargarepe');

    // auto_accept is the server's call and the only thing consulted here; the
    // 0.75 line has no copy in Dart (D31).
    expect(find.textContaining('šargarepa?'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });

  testWidgets('a line that matches nothing still stands', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});

    await _type(tester, 'kesica vanilin šećera');

    // Rule 3: not an error, not a blocker. The raw text is what saves.
    expect(find.text('No match'), findsOneWidget);
    expect(find.text('kesica vanilin šećera'), findsOneWidget);
  });

  testWidgets('quantities render as exact fractions, never decimals',
      (WidgetTester tester) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});

    await _type(tester, '1,5 dl vode');

    // The Serbian decimal comma parsed to 3/2 and renders as a vulgar
    // fraction. A '.' anywhere here would mean a float got in (rule 5).
    expect(find.textContaining('1½ dl'), findsOneWidget);
    final ActionChip chip = tester.widget<ActionChip>(find.byType(ActionChip));
    expect(((chip.label as Text).data ?? ''), isNot(contains('.')));
  });

  testWidgets('editing the quantity keeps a match the name still fits',
      (WidgetTester tester) async {
    await _pump(tester, matches: <String, List<IngredientMatch>>{
      'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: true)],
    });

    await _type(tester, '200 g šargarepe');
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    await _type(tester, '300 g šargarepe');

    // The match is a decision about a word, and that word did not change.
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('300 g · šargarepa'), findsOneWidget);
  });

  testWidgets('editing the name retires the match it no longer describes',
      (WidgetTester tester) async {
    await _pump(tester, matches: <String, List<IngredientMatch>>{
      'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: true)],
    });

    await _type(tester, '200 g šargarepe');
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    // Same shape, different ingredient, and nothing in the catalog answers to
    // it. Keeping šargarepa here would attach the wrong thing to the shopping
    // list.
    await _type(tester, '200 g krompira');

    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    expect(find.text('200 g · No match'), findsOneWidget);
  });
}
