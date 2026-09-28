import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/date_labels.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_en.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/net/network_status.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/shopping_list/application/shopping_list_providers.dart';
import 'package:kitchen_table/features/shopping_list/domain/rational.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_item.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_list.dart';
import 'package:kitchen_table/features/shopping_list/presentation/shopping_list_screen.dart';

/// Captured calls, kept off the notifier: `riverpod_lint`'s
/// `avoid_public_notifier_properties` forbids public fields on a `Notifier`
/// subclass, so the spy lives here (the same arrangement
/// `meal_plan_screen_test.dart` uses).
class _Calls {
  int generated = 0;
  ({String ingredientId, bool? alwaysHave})? pantryPref;
}

/// Overridden through Riverpod rather than mocked -- no mocking package, so
/// rule 8 is never triggered. Every write is replaced because a real one
/// would reach `currentHouseholdIdProvider` and on to
/// `Supabase.instance.client`, which this suite deliberately never provides.
class _StubList extends CurrentShoppingList {
  _StubList(this.initial, this.calls, {this.failure});

  final ShoppingList? initial;
  final _Calls calls;
  final AppFailure? failure;

  @override
  Stream<ShoppingList?> build() async* {
    yield initial;
  }

  @override
  Future<void> generate() async {
    calls.generated++;
    final AppFailure? f = failure;
    if (f != null) throw f;
  }

  @override
  Future<void> setPantryPref({
    required String ingredientId,
    required bool? alwaysHave,
  }) async {
    calls.pantryPref = (ingredientId: ingredientId, alwaysHave: alwaysHave);
  }

  @override
  Future<void> discard() async {}
}

/// A range pinned off the clock, so nothing here depends on today's date.
class _PinnedRange extends ShoppingRange {
  @override
  ({DateTime from, DateTime to}) build() =>
      (from: DateTime(2026, 7, 6), to: DateTime(2026, 7, 12));
}

final UnitCatalog _units = UnitCatalog(
  units: <Unit>[
    const Unit(code: 'g', family: UnitFamily.mass, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'kg', family: UnitFamily.mass, toBase: 1000, toBaseExact: '1000', isMetric: true),
    const Unit(code: 'ml', family: UnitFamily.volume, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'dl', family: UnitFamily.volume, toBase: 100, toBaseExact: '100', isMetric: true),
    const Unit(code: 'l', family: UnitFamily.volume, toBase: 1000, toBaseExact: '1000', isMetric: true),
    const Unit(code: 'kom', family: UnitFamily.count, toBase: 1, toBaseExact: '1'),
  ],
  aliases: <String, String>{},
  displayNames: <String, String>{
    'g|sr': 'g',
    'kg|sr': 'kg',
    'ml|sr': 'ml',
    'dl|sr': 'dl',
    'l|sr': 'l',
    'kom|sr': 'kom',
    'kom|en': 'pc',
  },
);

ShoppingItem _item(
  String name, {
  String? id = 'i-1',
  String? category = 'pantry',
  bool staple = false,
  List<ItemQuantity> quantities = const <ItemQuantity>[],
  List<String> unmatched = const <String>[],
}) =>
    ShoppingItem(
      ingredientId: id,
      displayName: name,
      category: category,
      isPantryStaple: staple,
      quantities: quantities,
      unmatchedLines: unmatched,
    );

ItemQuantity _q(int amount, UnitFamily family, String code) =>
    ItemQuantity(family: family, amount: Rational(amount, 1), unitCode: code);

ShoppingList _list(List<ShoppingItem> items, {String locale = 'sr'}) =>
    ShoppingList(
      id: 'l1',
      dateFrom: DateTime(2026, 7, 6),
      dateTo: DateTime(2026, 7, 12),
      locale: locale,
      generatedAt: DateTime(2026, 7, 5),
      updatedAt: DateTime(2026, 7, 5),
      items: items,
    );

Future<_Calls> _pump(
  WidgetTester tester, {
  ShoppingList? initial,
  AppFailure? failure,
  Locale? locale,
  Reachability? networkStatus,
  Size surface = const Size(1200, 3000),
  // `false` leaves `shoppingRangeProvider` on its real clock-derived
  // default, for the segment-selection tests that need "this week" to be
  // today's week.
  bool pinRange = true,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final _Calls calls = _Calls();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentShoppingListProvider
            .overrideWith(() => _StubList(initial, calls, failure: failure)),
        if (pinRange) shoppingRangeProvider.overrideWith(() => _PinnedRange()),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
        if (networkStatus != null)
          networkStatusProvider.overrideWithValue(networkStatus),
      ],
      // The AppBar title reads AppLocalizations now (D77, Phase 3 part 1).
      // No `locale:` set (the default) resolves English chrome regardless of
      // `list.locale` -- exactly the two-locale rule this suite pins.
      // The theme comes along since Phase 7 part 5: the doc-language tag and
      // `IngredientLineRow` read `KitchenColors` off it.
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const ShoppingListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return calls;
}

void main() {
  // No default in-memory clipboard in this SDK's flutter_test (contrary to
  // the slice's own assumption) -- an unmocked `flutter/platform` channel
  // call never replies, so `Clipboard.setData` inside `_copy` hangs forever
  // instead of throwing. A minimal mock is enough to let `_copy` complete;
  // the exported text itself is covered directly, and thoroughly, by
  // shopping_list_text_test.dart, so this only needs to unblock the
  // SnackBar assertion below.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async => null,
    );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('titles the tab List whatever the providers do', (tester) async {
    // app_shell_test.dart taps this tab and asserts the title, so it is built
    // outside the AsyncValue.when on purpose.
    await _pump(tester);
    expect(find.text('List'), findsOneWidget);
  });

  testWidgets('with no list, offers to generate one', (tester) async {
    final _Calls calls = await _pump(tester);

    expect(find.text('No list yet.'), findsOneWidget);
    await tester.tap(find.text('Generate list'));
    await tester.pumpAndSettle();

    expect(calls.generated, 1);
  });

  testWidgets('a failure to generate is shown, not swallowed', (tester) async {
    // A bare NetworkFailure, not a custom message: D92's failure vocabulary
    // renders from the variant's default FailureCode, not from `message`
    // (which is the log-line/server-prose fallback for a null code).
    await _pump(tester, failure: const NetworkFailure());

    await tester.tap(find.text('Generate list'));
    await tester.pumpAndSettle();

    expect(find.text(AppLocalizationsEn().failureOffline), findsOneWidget);
  });

  testWidgets('renders an item with its summed quantity', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('brašno',
            quantities: <ItemQuantity>[_q(1200, UnitFamily.mass, 'g')]),
      ]),
    );

    // IngredientLineRow's amount: the unit rides with the number, on the
    // right, apart from the name (D127).
    expect(find.text('1.2 kg'), findsOneWidget);
    expect(find.text('brašno'), findsOneWidget);
    expect(find.text('kg brašno'), findsNothing);
  });

  testWidgets(
      'count units follow the LIST\'s own locale, not a hardcoded default '
      '(same class of bug as D81, one layer over)', (tester) async {
    await _pump(
      tester,
      initial: _list(
        <ShoppingItem>[
          _item('eggs', quantities: <ItemQuantity>[
            _q(3, UnitFamily.count, 'kom'),
          ]),
        ],
        locale: 'en',
      ),
    );

    expect(find.text('3 pc'), findsOneWidget);
    expect(find.text('3 kom'), findsNothing);
  });

  testWidgets('two families on one line are shown side by side, never merged',
      (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('brašno', quantities: <ItemQuantity>[
          _q(480, UnitFamily.volume, 'ml'),
          _q(300, UnitFamily.mass, 'g'),
        ]),
      ]),
    );

    // The first family in the amount, the second in the trailer.
    expect(find.text('480 ml'), findsOneWidget);
    expect(find.text('brašno'), findsOneWidget);
    expect(find.text('+ 300 g'), findsOneWidget);
  });

  testWidgets('an unmatched line renders verbatim (rule 3)', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('so', id: null, unmatched: <String>['so po ukusu']),
      ]),
    );

    // `textContaining`: the ring is a WidgetSpan inline after the name, so
    // the run's plain text carries its placeholder.
    expect(find.textContaining('so po ukusu'), findsOneWidget);
    // Unmatched is marked quietly, never as an error.
    expect(find.byKey(const Key('unmatchedMarker')), findsOneWidget);
  });

  testWidgets('pantry staples are collapsed under Probably have, not hidden',
      (tester) async {
    // Explicit English so the section heading is asserted in a fixed
    // language -- it renders in list.locale (the two-locale rule), not the
    // reader's, so this is deliberate, not a default left unexamined.
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('brašno',
            quantities: <ItemQuantity>[_q(500, UnitFamily.mass, 'g')]),
        _item('so',
            id: 'i-so',
            staple: true,
            quantities: <ItemQuantity>[_q(5, UnitFamily.mass, 'g')]),
      ], locale: 'en'),
    );

    expect(find.text('Probably have (1)'), findsOneWidget);
    // Collapsed: present in the tree as a heading, the item itself not yet
    // rendered.
    expect(find.text('5 g'), findsNothing);

    await tester.tap(find.text('Probably have (1)'));
    await tester.pumpAndSettle();

    // Expanding shows it -- nothing was ever dropped from the snapshot.
    expect(find.text('5 g'), findsOneWidget);
  });

  testWidgets(
      'items are still ordered by category, uncategorised last, even though '
      'no heading renders any more', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('nešto', id: 'i-x', category: null),
        _item('luk', id: 'i-l', category: 'produce'),
        _item('brašno', id: 'i-b', category: 'pantry'),
      ], locale: 'en'),
    );

    // No heading widgets exist at all now (D105, amended).
    final AppLocalizationsEn en = AppLocalizationsEn();
    expect(find.text(en.categoryProduce), findsNothing);
    expect(find.text(en.categoryPantry), findsNothing);
    expect(find.text(en.categoryOther), findsNothing);

    // Sorted by English label -- Pantry, Produce -- uncategorised last.
    final double pantryItemY = tester.getTopLeft(find.text('brašno')).dy;
    final double produceItemY = tester.getTopLeft(find.text('luk')).dy;
    final double uncategorisedItemY = tester.getTopLeft(find.text('nešto')).dy;
    expect(pantryItemY, lessThan(produceItemY));
    expect(produceItemY, lessThan(uncategorisedItemY));
  });

  testWidgets(
      'a locale: "sr" list still renders the AppBar in the reader\'s English '
      '(the two-locale rule), even with no category heading left to show it',
      (tester) async {
    // No `locale:` passed to _pump -- the reader stays on the harness
    // default (English), while _list()'s own default locale is 'sr'. With
    // category headings gone, `_GeneratedAt`'s own date line and the
    // "Probably have" count are what's left to carry list.locale.
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('brašno', id: 'i-b', category: 'pantry'),
        _item('so',
            id: 'i-so',
            staple: true,
            quantities: <ItemQuantity>[_q(5, UnitFamily.mass, 'g')]),
      ]),
    );

    expect(find.widgetWithText(AppBar, 'List'), findsOneWidget);
    // categoryPantry no longer renders, but probablyHaveHeading still does,
    // in the list's own Serbian.
    expect(find.text('Verovatno imate (1)'), findsOneWidget);
    expect(find.text('Probably have (1)'), findsNothing);
  });

  testWidgets('long-pressing an item records a pantry override', (tester) async {
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('brašno', id: 'i-brasno')]),
    );

    await tester.longPress(find.text('brašno'));
    await tester.pumpAndSettle();

    expect(calls.pantryPref?.ingredientId, 'i-brasno');
    expect(calls.pantryPref?.alwaysHave, isTrue);
    // The snapshot is not rearranged under the cook -- it says so instead.
    expect(find.textContaining('next time you generate'), findsOneWidget);
  });

  testWidgets('an unmatched item cannot be given a pantry override',
      (tester) async {
    // There is no ingredient id to hang the preference off.
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('so po ukusu', id: null)]),
    );

    await tester.longPress(find.textContaining('so po ukusu'));
    await tester.pumpAndSettle();

    expect(calls.pantryPref, isNull);
  });

  testWidgets('regenerating is not offered before a list exists',
      (tester) async {
    await _pump(tester);
    expect(find.byTooltip('Regenerate'), findsNothing);
  });

  testWidgets('regenerating is offered once a list exists', (tester) async {
    await _pump(tester, initial: _list(<ShoppingItem>[_item('brašno')]));
    expect(find.byTooltip('Regenerate'), findsOneWidget);
  });

  testWidgets('copying is not offered before a list exists', (tester) async {
    await _pump(tester);
    expect(find.byTooltip('Copy list'), findsNothing);
  });

  testWidgets(
      'copying shows the reader-locale SnackBar (D94 chrome side); the '
      'exported text itself is covered directly by '
      'shopping_list_text_test.dart', (tester) async {
    // Reading `Clipboard.getData` back from the TEST BODY (as opposed to
    // from inside a widget callback) hangs indefinitely in this Flutter SDK
    // -- confirmed with a minimal reproduction outside this suite, not a bug
    // in `_copy`. The slice anticipated this ("if it proves awkward, test
    // formatShoppingListAsText directly and assert only that the SnackBar
    // appears on tap"); the D94 split itself is exercised end-to-end by
    // shopping_list_text_test.dart's own list-locale-vs-reader-locale case.
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('mleko', id: 'i-mleko', category: 'dairy',
            quantities: <ItemQuantity>[_q(500, UnitFamily.volume, 'ml')]),
      ]),
    );

    await tester.tap(find.byTooltip('Copy list'));
    await tester.pumpAndSettle();

    // Chrome -- reader's locale (English), even though the list is Serbian.
    expect(find.text('List copied.'), findsOneWidget);
  });

  testWidgets(
      'under srLatn, the chrome renders Serbian, Latin script (D91 -- '
      'invisible if only English is ever pumped)', (tester) async {
    await _pump(tester, locale: srLatn);

    // AppBar title, chrome, reader's locale.
    expect(find.widgetWithText(AppBar, 'Lista'), findsOneWidget);
    // The range line (shown: there is no list yet) -- chrome, so the
    // reader's locale too, and Latin script: Cyrillic would fail this
    // exact-text match.
    expect(
      find.text(
        AppLocalizationsSr().nextListRangeLine(
          shortDateLabel(DateTime(2026, 7, 6), 'sr'),
          shortDateLabel(DateTime(2026, 7, 12), 'sr'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'every to-buy row draws its hairline, the last row of a category block '
    'included; only the card\'s last row drops it (Phase 7 part 5\'s walk: '
    'block-end gaps with no hairline read as uneven spacing, not grouping)',
    (tester) async {
      await _pump(
        tester,
        initial: _list(<ShoppingItem>[
          _item('brašno', id: 'i-b', category: 'pantry'),
          _item('šećer', id: 'i-s', category: 'pantry'),
          _item('luk', id: 'i-l', category: 'produce'),
        ]),
      );

      Border borderOf(String name) {
        final Container row = tester.widget<Container>(
          find
              .ancestor(of: find.text(name), matching: find.byType(Container))
              .first,
        );
        return (row.decoration! as BoxDecoration).border! as Border;
      }

      // Serbian labels sort Ostava before Povrće.
      expect(borderOf('brašno').bottom, isNot(BorderSide.none));
      // Last of its block, not of the card: keeps its hairline.
      expect(borderOf('šećer').bottom, isNot(BorderSide.none));
      // Last row of the card: the card's edge does the separating.
      expect(borderOf('luk').bottom, BorderSide.none);
    },
  );

  group('the saved-copy line', () {
    testWidgets('is onSurfaceVariant, not error -- offline is calm', (
      tester,
    ) async {
      await _pump(
        tester,
        initial: _list(<ShoppingItem>[_item('brašno')]),
        networkStatus: Reachability.offline,
      );
      final ColorScheme scheme = AppTheme.light().colorScheme;
      final Text line = tester.widget<Text>(
        find.textContaining('Showing your saved copy'),
      );
      expect(line.style?.color, scheme.onSurfaceVariant);
      expect(line.style?.color, isNot(scheme.error));
    });

    testWidgets('does not render online', (tester) async {
      await _pump(
        tester,
        initial: _list(<ShoppingItem>[_item('brašno')]),
        networkStatus: Reachability.online,
      );
      expect(find.textContaining('Showing your saved copy'), findsNothing);
    });
  });

  testWidgets(
    'an English list under a Serbian reader is tagged EN, in the reader\'s '
    'Serbian, and its document strings stay English (D94 as designed -- '
    'part 1\'s "untranslated strings" report)',
    (tester) async {
      await _pump(
        tester,
        locale: srLatn,
        initial: _list(<ShoppingItem>[
          _item('flour', id: 'i-f'),
          _item(
            'salt',
            id: 'i-so',
            staple: true,
            quantities: <ItemQuantity>[_q(5, UnitFamily.mass, 'g')],
          ),
        ], locale: 'en'),
      );

      // The code is the document's language, the sentence is chrome.
      expect(find.text('EN'), findsOneWidget);
      expect(find.text(AppLocalizationsSr().listIsInEnglish), findsOneWidget);
      // The document itself stays in the language it was generated in.
      expect(find.text('Probably have (1)'), findsOneWidget);
      expect(find.text('Verovatno imate (1)'), findsNothing);
    },
  );

  testWidgets('a Serbian list is tagged SR', (tester) async {
    await _pump(tester, initial: _list(<ShoppingItem>[_item('brašno')]));

    expect(find.text('SR'), findsOneWidget);
    expect(find.text(AppLocalizationsEn().listIsInSerbian), findsOneWidget);
  });

  testWidgets(
    'Serbian at 360x780 lays out without overflow, with a list and staples '
    '-- part 2\'s three-line range header lived exactly here',
    (tester) async {
      await _pump(
        tester,
        locale: srLatn,
        surface: const Size(360, 780),
        networkStatus: Reachability.offline,
        initial: _list(<ShoppingItem>[
          _item(
            'brašno',
            id: 'i-b',
            quantities: <ItemQuantity>[
              _q(1200, UnitFamily.mass, 'g'),
              _q(480, UnitFamily.volume, 'ml'),
            ],
          ),
          _item(
            'paradajz pelat u konzervi, seckani, bez dodatog šećera',
            id: 'i-p',
            category: 'produce',
            quantities: <ItemQuantity>[_q(3, UnitFamily.count, 'kom')],
          ),
          _item(
            'so',
            id: null,
            unmatched: <String>[
              'so i biber po ukusu, po mogućstvu krupna morska so',
            ],
          ),
          _item(
            'ulje',
            id: 'i-u',
            staple: true,
            quantities: <ItemQuantity>[_q(50, UnitFamily.volume, 'ml')],
          ),
        ]),
      );
      expect(tester.takeException(), isNull);

      final AppLocalizationsSr sr = AppLocalizationsSr();
      expect(find.text(sr.thisWeekButton), findsOneWidget);
      expect(find.text(sr.nextWeekButton), findsOneWidget);
      expect(find.text(sr.pickDatesSegment), findsOneWidget);

      await tester.tap(find.text(sr.probablyHaveHeading(1)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  group('the range bar', () {
    SegmentedButton<Object?> segmented(WidgetTester tester) =>
        tester.widget<SegmentedButton<Object?>>(
          find.byWidgetPredicate((Widget w) => w is SegmentedButton),
        );

    String selectedName(WidgetTester tester) =>
        (segmented(tester).selected.single! as Enum).name;

    testWidgets('selects this week by default, derived from the range', (
      tester,
    ) async {
      await _pump(tester, pinRange: false);
      expect(selectedName(tester), 'thisWeek');
    });

    testWidgets(
        'the selected segment carries no check -- its fill says it, and the '
        'check pushed Ova nedelja / This week onto two lines on the device '
        '(Phase 7 part 5\'s walk; the test font cannot measure that width)',
        (tester) async {
      await _pump(tester, pinRange: false, locale: srLatn);

      expect(segmented(tester).showSelectedIcon, isFalse);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('tapping Sledeća selects next week', (tester) async {
      await _pump(tester, pinRange: false, locale: srLatn);

      await tester.tap(find.text(AppLocalizationsSr().nextWeekButton));
      await tester.pumpAndSettle();

      expect(selectedName(tester), 'nextWeek');
    });

    testWidgets(
      'the range line is absent while the range is the list\'s own, and '
      'appears once a different range is set',
      (tester) async {
        await _pump(tester, initial: _list(<ShoppingItem>[_item('brašno')]));
        expect(find.textContaining('Next list:'), findsNothing);
        // A range off the clock reads as custom.
        expect(selectedName(tester), 'custom');

        ProviderScope.containerOf(
              tester.element(find.byType(ShoppingListScreen)),
            )
            .read(shoppingRangeProvider.notifier)
            .setRange(from: DateTime(2026, 7, 13), to: DateTime(2026, 7, 15));
        await tester.pumpAndSettle();

        expect(
          find.text(
            AppLocalizationsEn().nextListRangeLine(
              shortDateLabel(DateTime(2026, 7, 13), 'en'),
              shortDateLabel(DateTime(2026, 7, 15), 'en'),
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('re-tapping the already-selected Dates segment reopens the '
        'picker', (tester) async {
      // The pinned July range is custom against today's clock.
      await _pump(tester, initial: _list(<ShoppingItem>[_item('brašno')]));
      expect(selectedName(tester), 'custom');

      await tester.tap(find.text('Dates'));
      await tester.pumpAndSettle();

      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });
  });
}
