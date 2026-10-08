import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_en.dart';
import 'package:kitchen_table/features/ingredients/data/ingredient_repository.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_line_parser.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_match.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_draft.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_line_field.dart';

/// The open line: the box, its live preview, the pill, and the two keys fast
/// entry listens for. Driven through the real parser with the catalog
/// stubbed by provider override -- no mocking package (rule 8).

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
  matchedName: 'šargarepa',
  matchedLocale: 'sr',
  matchMethod: autoAccept ? MatchMethod.alias : MatchMethod.fuzzy,
  confidence: autoAccept ? 1.0 : 0.5,
  autoAccept: autoAccept,
  isVerified: true,
);

/// Records the alias write-backs; nothing else is reached.
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

/// Holds the line the way the editor does, so a change reported by the
/// field comes back as new state.
class _Harness extends StatefulWidget {
  const _Harness({required this.initial});

  final RecipeDraftLine initial;

  @override
  State<_Harness> createState() => _HarnessState();
}

int _submits = 0;
int _backspaces = 0;
RecipeDraftLine? _last;

class _HarnessState extends State<_Harness> {
  late RecipeDraftLine _line = widget.initial;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ReorderableListView(
      onReorderItem: (int a, int b) {},
      buildDefaultDragHandles: false,
      children: <Widget>[
        IngredientLineField(
          key: const ValueKey<int>(0),
          index: 0,
          line: _line,
          locale: 'sr',
          autofocus: true,
          onChanged: (RecipeDraftLine next) => setState(() {
            _line = next;
            _last = next;
          }),
          onRemove: () {},
          onSubmitted: (_) => _submits++,
          onBackspaceWhenEmpty: () => _backspaces++,
        ),
      ],
    ),
  );
}

/// Records every term the field actually searched for.
final List<String> _searched = <String>[];

/// [matches] is keyed by search term, so a line whose name changes stops
/// matching what the old name matched.
Future<_FakeCatalog> _pump(
  WidgetTester tester, {
  required Map<String, List<IngredientMatch>> matches,
  RecipeDraftLine? line,
  Duration searchDelay = Duration.zero,
}) async {
  _searched.clear();
  _submits = 0;
  _backspaces = 0;
  _last = null;
  final _FakeCatalog catalog = _FakeCatalog();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ingredientCatalogProvider.overrideWithValue(catalog),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
        lineParserProvider.overrideWith(
          (Ref ref) async => IngredientLineParser(_units),
        ),
        ingredientMatchesProvider.overrideWith((
          Ref ref,
          (String, {String locale}) arg,
        ) async {
          if (arg.$1.isNotEmpty) _searched.add(arg.$1);
          if (searchDelay > Duration.zero) {
            await Future<void>.delayed(searchDelay);
          }
          return matches[arg.$1] ?? const <IngredientMatch>[];
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: _Harness(
          initial: line ?? const RecipeDraftLine(localId: 0, rawText: ''),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return catalog;
}

/// Types a line and lets the 250 ms debounce elapse.
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

String _previewText(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(const Key('ingredientLinePreview')),
        matching: find.byType(Text),
      ),
    )
    .map((Text t) => t.data ?? t.textSpan!.toPlainText())
    .join('|')
    // The preview keeps status words whole with non-breaking spaces.
    .replaceAll('\u00A0', ' ');

// The widget under test is always given locale: 'sr', while this test host
// resolves to English. Status words are chrome and follow the READER (this
// host), while amounts, unit names and catalog names follow the RECIPE
// (D86). Read off AppLocalizationsEn() rather than a literal, so a wording
// change in the ARB cannot silently desync this.
final AppLocalizations reader = AppLocalizationsEn();

void main() {
  testWidgets('an empty line has no preview and no pill', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});

    expect(find.byKey(const Key('ingredientLinePreview')), findsNothing);
    expect(find.byKey(const Key('ingredientSuggestionPill')), findsNothing);
  });

  testWidgets('the typed text is bodyLarge, the preview bodyMedium', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});
    await _type(tester, '200 g brašna, prosejano');

    final ThemeData theme = AppTheme.light();
    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.fontSize, theme.textTheme.bodyLarge?.fontSize);
    final Text left = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('ingredientLinePreview')),
        matching: find.textContaining('→'),
      ),
    );
    expect(left.style?.fontSize, theme.textTheme.bodyMedium?.fontSize);
  });

  testWidgets('the preview shows the name, the note and the amount as typed', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});

    await _type(tester, '200 g brašna, prosejano');

    expect(_previewText(tester), contains('→ brašna · prosejano'));
    expect(
      tester
          .widget<Text>(find.byKey(const Key('ingredientLinePreviewAmount')))
          .textSpan!
          .toPlainText(),
      '200 g',
    );
  });

  testWidgets('the search term is the parsed name, not the whole line', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      matches: <String, List<IngredientMatch>>{
        'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: true)],
      },
    );

    await _type(tester, '200 g šargarepe');

    // Tier 1 stripped the quantity and the unit before tiers 2 and 3 ever saw
    // the line (D31).
    expect(_searched, contains('šargarepe'));
    expect(_searched, isNot(contains('200 g šargarepe')));
  });

  testWidgets('an auto-accepted row is adopted as typed, and the preview '
      'names the catalog word', (WidgetTester tester) async {
    await _pump(
      tester,
      matches: <String, List<IngredientMatch>>{
        'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: true)],
      },
    );

    await _type(tester, '200 g šargarepe');

    expect(_last?.ingredientId, 'i1');
    // The search's own method, not manual: nobody confirmed this.
    expect(_last?.matchMethod, MatchMethod.alias);
    expect(_previewText(tester), contains('→ šargarepa'));
    expect(find.byKey(const Key('ingredientSuggestionPill')), findsNothing);
  });

  testWidgets('a row below auto-accept is offered as the pill, not applied', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      matches: <String, List<IngredientMatch>>{
        'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: false)],
      },
    );

    await _type(tester, '200 g šargarepe');

    // auto_accept is the server's call and the only thing consulted here; the
    // 0.75 line has no copy in Dart (D31).
    expect(_last?.isMatched, isFalse);
    expect(
      find.text(reader.ingredientSuggestionLabel('šargarepa')),
      findsOneWidget,
    );
    expect(find.text(reader.ingredientSuggestionConfirmHint), findsOneWidget);
  });

  testWidgets('tapping the pill confirms the match as manual and writes the '
      'alias back', (WidgetTester tester) async {
    final _FakeCatalog catalog = await _pump(
      tester,
      matches: <String, List<IngredientMatch>>{
        'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: false)],
      },
    );
    await _type(tester, '200 g šargarepe');

    await tester.tap(find.byKey(const Key('ingredientSuggestionPill')));
    await tester.pumpAndSettle();

    // D7: a human decision.
    expect(_last?.ingredientId, 'i1');
    expect(_last?.matchMethod, MatchMethod.manual);
    expect(_last?.matchConfidence, 1);
    // D8: the word typed, taught to the catalog.
    expect(catalog.linked, <(String, String)>[('i1', 'šargarepe')]);
    expect(find.byKey(const Key('ingredientSuggestionPill')), findsNothing);
  });

  testWidgets('a line that matches nothing still stands, and says so', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});

    await _type(tester, 'kesica vanilin šećera');

    // Rule 3: not an error, not a blocker. The raw text is what saves.
    expect(_previewText(tester), contains(reader.ingredientNoMatchLabel));
    expect(find.text('kesica vanilin šećera'), findsOneWidget);
  });

  testWidgets('quantities render as exact fractions, never decimals', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});

    await _type(tester, '1,5 dl vode');

    // The Serbian decimal comma parsed to 3/2 and renders as a vulgar
    // fraction. A '.' anywhere here would mean a float got in (rule 5).
    final String amount = tester
        .widget<Text>(find.byKey(const Key('ingredientLinePreviewAmount')))
        .textSpan!
        .toPlainText();
    expect(amount, '1½ dl');
    expect(_previewText(tester), isNot(contains('.')));
  });

  testWidgets('editing the quantity keeps a match the name still fits', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      matches: <String, List<IngredientMatch>>{
        'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: true)],
      },
    );

    await _type(tester, '200 g šargarepe');
    expect(_last?.isMatched, isTrue);

    await _type(tester, '300 g šargarepe');

    // The match is a decision about a word, and that word did not change.
    expect(_last?.ingredientId, 'i1');
    expect(_previewText(tester), contains('300 g'));
  });

  testWidgets('editing the name retires the match it no longer describes', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      matches: <String, List<IngredientMatch>>{
        'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: true)],
      },
    );

    await _type(tester, '200 g šargarepe');
    expect(_last?.isMatched, isTrue);

    await _type(tester, '200 g krompira');

    expect(_last?.isMatched, isFalse);
    expect(
      _previewText(tester),
      contains('→ krompira · ${reader.ingredientNoMatchLabel}'),
    );
  });

  testWidgets('tapping the preview opens the picker -- choose another', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});
    await _type(tester, '200 g šargarepe');

    await tester.tap(find.byKey(const Key('ingredientLinePreview')));
    await tester.pumpAndSettle();

    // The sheet's title is in the recipe's language.
    expect(
      find.text(
        lookupAppLocalizations(const Locale('sr'))
            .ingredientPickerQuestion('šargarepe'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Next reports the text and keeps focus', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});
    await _type(tester, 'so');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(_submits, 1);
    final EditableText editable = tester.widget<EditableText>(
      find.byType(EditableText),
    );
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('Backspace reports only on an empty line', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});
    await _type(tester, 'so');

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(_backspaces, 0);

    await _type(tester, '');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(_backspaces, 1);
  });

  testWidgets('the box draws its primary border only while focused', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});

    BorderSide side() =>
        ((tester
                            .widget<Container>(
                              find.byKey(const Key('ingredientLineBox')),
                            )
                            .foregroundDecoration!
                        as BoxDecoration)
                    .border!
                as Border)
            .top;
    expect(side().width, 2);
    expect(side().color, AppTheme.light().colorScheme.primary);

    tester.widget<EditableText>(find.byType(EditableText)).focusNode.unfocus();
    await tester.pumpAndSettle();
    expect(side(), BorderSide.none);
  });

  testWidgets('the text field is bare inside the box -- no theme border, no '
      '52dp minimum', (WidgetTester tester) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});

    final InputDecorator decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorator.decoration.focusedBorder, InputBorder.none);
    expect(decorator.decoration.enabledBorder, InputBorder.none);
    // One bodyLarge line (28), nowhere near the theme's 52.
    expect(tester.getSize(find.byType(TextField)).height, lessThan(40));
  });

  testWidgets('a search that lands after the name changed is not adopted', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      matches: <String, List<IngredientMatch>>{
        'šargarepe': <IngredientMatch>[_sargarepa(autoAccept: true)],
      },
      searchDelay: const Duration(milliseconds: 100),
    );

    // The debounce fires on `šargarepe` at 250 ms; the cook types on at
    // 300, and the answer lands at 350 -- before the next debounce moves the
    // search on.
    await tester.enterText(find.byType(TextField), '200 g šargarepe');
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.enterText(find.byType(TextField), '200 g krompira');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(_last?.isMatched, isFalse);
    // And the late answer did not write the older text back.
    expect(_last?.rawText, '200 g krompira');
  });

  testWidgets('the no-match words never split across lines', (
    WidgetTester tester,
  ) async {
    await _pump(tester, matches: const <String, List<IngredientMatch>>{});
    await _type(tester, 'kesica vanilin šećera');

    final String raw = tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const Key('ingredientLinePreview')),
            matching: find.textContaining('→'),
          ),
        )
        .data!;
    expect(
      raw,
      endsWith(' ·\u00A0${reader.ingredientNoMatchLabel.replaceAll(' ', '\u00A0')}'),
    );
  });
}
