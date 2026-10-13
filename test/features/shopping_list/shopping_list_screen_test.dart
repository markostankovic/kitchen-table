import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/household/current_household.dart';
import 'package:kitchen_table/core/household/widgets/household_switch_placeholder.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_line_row.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/date_labels.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_en.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/net/network_status.dart';
import 'package:kitchen_table/core/refresh/data_revision.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_empty_state.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/shopping_list/application/shopping_list_providers.dart';
import 'package:kitchen_table/features/shopping_list/domain/rational.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_item.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_list.dart';

import '../../helpers/household_switch_harness.dart';
import 'package:kitchen_table/features/shopping_list/presentation/shopping_list_screen.dart';

/// Captured calls, kept off the notifier: `riverpod_lint`'s
/// `avoid_public_notifier_properties` forbids public fields on a `Notifier`
/// subclass, so the spy lives here (the same arrangement
/// `meal_plan_screen_test.dart` uses).
class _Calls {
  int generated = 0;
  int regenerated = 0;

  /// Every `setPantryPref` call in order, so a pick and its Undo can be told
  /// apart.
  final List<({String ingredientId, bool? alwaysHave})> pantryPrefs =
      <({String ingredientId, bool? alwaysHave})>[];

  ({String ingredientId, bool? alwaysHave})? get pantryPref =>
      pantryPrefs.isEmpty ? null : pantryPrefs.last;
}

/// Overridden through Riverpod rather than mocked -- no mocking package, so
/// rule 8 is never triggered. Every write is replaced because a real one
/// would reach `currentHouseholdIdProvider` and on to
/// `Supabase.instance.client`, which this suite deliberately never provides.
class _StubList extends CurrentShoppingList {
  _StubList(
    this.initial,
    this.calls, {
    this.failure,
    this.regenerateFailure,
    this.pantryPrefFailure,
    this.reloadOnRegenerate = false,
  });

  final ShoppingList? initial;
  final _Calls calls;
  final AppFailure? failure;

  /// Fails `regenerateCurrent()` alone, so a long-press whose preference
  /// saved but whose regeneration did not can be told apart.
  final AppFailure? regenerateFailure;

  /// Fails every `setPantryPref` after the first, so an Undo can fail while
  /// the pick it undoes succeeded.
  final AppFailure? pantryPrefFailure;

  /// Makes `regenerateCurrent()` bump the revision the way the real one
  /// does, so `build()` re-runs as a reload and takes a second to answer --
  /// longer than `tester.longPress`'s own pump, which would otherwise finish
  /// the reload before the test can look at it.
  final bool reloadOnRegenerate;

  @override
  Stream<ShoppingList?> build() async* {
    if (reloadOnRegenerate && ref.watch(shoppingListRevisionProvider) > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    yield initial;
  }

  @override
  Future<void> generate() async {
    calls.generated++;
    final AppFailure? f = failure;
    if (f != null) throw f;
  }

  @override
  Future<void> regenerateCurrent() async {
    calls.regenerated++;
    final AppFailure? f = regenerateFailure ?? failure;
    if (f != null) throw f;
    if (reloadOnRegenerate) {
      ref.read(shoppingListRevisionProvider.notifier).bump();
    }
  }

  @override
  Future<void> setPantryPref({
    required String ingredientId,
    required bool? alwaysHave,
  }) async {
    calls.pantryPrefs.add((ingredientId: ingredientId, alwaysHave: alwaysHave));
    final AppFailure? f = pantryPrefFailure;
    if (f != null && calls.pantryPrefs.length > 1) throw f;
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

const Size _phone = Size(800, 600);

Future<_Calls> _pump(
  WidgetTester tester, {
  ShoppingList? initial,
  AppFailure? failure,
  AppFailure? regenerateFailure,
  AppFailure? pantryPrefFailure,
  bool reloadOnRegenerate = false,
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
            .overrideWith(() => _StubList(
              initial,
              calls,
              failure: failure,
              regenerateFailure: regenerateFailure,
              pantryPrefFailure: pantryPrefFailure,
              reloadOnRegenerate: reloadOnRegenerate,
            )),
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

/// Long-presses [target], lets the menu open at the finger, then picks its
/// one item.
Future<void> _pickFromMenu(
  WidgetTester tester,
  Finder target,
  String menuItem,
) async {
  await tester.longPress(target);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, menuItem));
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

  testWidgets(
      'the no-list state is carded, with the basket glyph and one tonal '
      'action (D138, frame 19)', (tester) async {
    await _pump(tester);

    expect(
      tester.widget<AppEmptyState>(find.byType(AppEmptyState)).card,
      isTrue,
    );
    expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
    expect(find.byIcon(Icons.playlist_add_check_outlined), findsNothing);

    // The resolved fill, read off the button's own Material: less brittle
    // than resolving `style ?? filledButtonTheme` by hand, and it proves
    // the theme's tonal variant rather than how the button was built.
    final Material fill = tester.widget<Material>(
      find
          .descendant(
            of: find.ancestor(
              of: find.text('Generate list'),
              matching: find.byWidgetPredicate((Widget w) => w is FilledButton),
            ),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(fill.color, AppTheme.light().colorScheme.secondaryContainer);
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

  // Pull means generate, like the app-bar button (D147). These pump a
  // phone-sized surface: RefreshIndicator arms at a quarter of the
  // viewport's height, which a 300px fling never reaches on the suite's
  // default 3000px-tall surface.
  testWidgets('pulling down on a list generates', (tester) async {
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('brašno')]),
      surface: _phone,
    );

    await tester.fling(find.text('brašno'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(calls.generated, 1);
  });

  testWidgets('pulling down on the empty state generates', (tester) async {
    final _Calls calls = await _pump(tester, surface: _phone);

    await tester.fling(find.text('No list yet.'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(calls.generated, 1);
  });

  testWidgets('a pull whose generation fails shows the failure',
      (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('brašno')]),
      failure: const NetworkFailure(),
      surface: _phone,
    );

    await tester.fling(find.text('brašno'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(find.text(AppLocalizationsEn().failureOffline), findsOneWidget);
    // The saved list stays on screen.
    expect(find.text('brašno'), findsOneWidget);
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

    // The first family in the amount, the second stacked under it in the
    // same right-aligned column -- nothing under the name.
    final Finder first = find.byKey(const Key('ingredientAmount'));
    final Finder extra = find.byKey(const Key('ingredientExtraAmount'));
    expect(tester.widget<Text>(first).textSpan!.toPlainText(), '480 ml');
    expect(tester.widget<Text>(extra).textSpan!.toPlainText(), '+ 300 g');
    expect(tester.getTopRight(extra).dx, tester.getTopRight(first).dx);
    expect(
      tester.getTopLeft(extra).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(first).dy),
    );
    expect(find.text('brašno'), findsOneWidget);
    expect(find.textContaining('300'), findsOneWidget);
  });

  testWidgets(
      'an unmatched item says Not added up, in the reader\'s locale, not the '
      'list\'s', (tester) async {
    // An `sr` list under the harness's English chrome.
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('so', id: null, unmatched: <String>['so po ukusu']),
      ]),
    );

    expect(find.text('Not added up\nso po ukusu'), findsOneWidget);
    expect(find.textContaining('Nije sabrano'), findsNothing);
  });

  testWidgets(
      'an unmatched item with an amount shows the amount, not Not added up',
      (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('1 manji koren peršuna',
            id: null,
            quantities: <ItemQuantity>[_q(2, UnitFamily.count, 'kom')]),
      ]),
    );

    expect(find.text('2 kom'), findsOneWidget);
    expect(find.byKey(const Key('unmatchedMarker')), findsOneWidget);
    expect(find.textContaining('Not added up'), findsNothing);
  });

  testWidgets('a matched item has no Not added up trailer', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('brašno',
            quantities: <ItemQuantity>[_q(500, UnitFamily.mass, 'g')]),
      ]),
    );

    expect(find.textContaining('Not added up'), findsNothing);
  });

  testWidgets('a staple in Probably have carries the pin; a to-buy row does '
      'not', (tester) async {
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
    // The to-buy row is on screen; the staple is not yet.
    expect(find.text('500 g'), findsOneWidget);
    expect(find.byKey(const Key('stapleMarker')), findsNothing);

    await tester.tap(find.text('Probably have (1)'));
    await tester.pumpAndSettle();

    // One pin: the staple's, not the to-buy row's.
    final Finder pin = find.byKey(const Key('stapleMarker'));
    expect(pin, findsOneWidget);
    expect(
      tester.widget<Icon>(pin).color,
      AppTheme.light().colorScheme.outline,
    );
    expect(
      find.ancestor(of: pin, matching: find.byType(Tooltip)),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Tooltip>(
            find.ancestor(of: pin, matching: find.byType(Tooltip)),
          )
          .message,
      'Always in Probably have',
    );
  });

  testWidgets(
      'the Probably have subline teaches the long-press, collapsed then '
      'expanded, in the reader\'s locale', (tester) async {
    // An `sr` list under English chrome: the heading is the document's, the
    // hint the reader's.
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('so',
            id: 'i-so',
            staple: true,
            quantities: <ItemQuantity>[_q(5, UnitFamily.mass, 'g')]),
      ]),
    );

    expect(find.text('Verovatno imate (1)'), findsOneWidget);
    expect(find.text('Long-press any item to move it here.'), findsOneWidget);
    expect(find.text('Long-press an item to move it back.'), findsNothing);

    await tester.tap(find.text('Verovatno imate (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Long-press an item to move it back.'), findsOneWidget);
    expect(find.text('Long-press any item to move it here.'), findsNothing);
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

  testWidgets('long-pressing an item and picking the menu item records a '
      'pantry override', (tester) async {
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('brašno', id: 'i-brasno')]),
    );

    await _pickFromMenu(tester, find.text('brašno'), 'Always in Probably have');
    await tester.pumpAndSettle();

    expect(calls.pantryPref?.ingredientId, 'i-brasno');
    expect(calls.pantryPref?.alwaysHave, isTrue);
    // The same list is regenerated at once, so the item moves now (D147).
    expect(calls.regenerated, 1);
    expect(find.text('brašno moved to Probably have.'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);
    // The menu has closed and taken the pressed-row fill with it.
    expect(find.byType(MenuItemButton), findsNothing);
    expect(find.byKey(const Key('pressedRowFill')), findsNothing);
  });

  testWidgets(
      'a long-press keeps the list on screen and its scroll position while '
      'the list reloads (Phase 8 part 1\'s walk: it blanked and jumped to '
      'the top)', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        for (int i = 0; i < 20; i++) _item('item $i', id: 'i-$i'),
      ]),
      reloadOnRegenerate: true,
      surface: _phone,
    );

    final Finder scrollable = find
        .descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.drag(scrollable, const Offset(0, -3000));
    await tester.pumpAndSettle();
    final double offset =
        tester.state<ScrollableState>(scrollable).position.pixels;
    expect(offset, greaterThan(0));

    await _pickFromMenu(tester, find.text('item 19'), 'Always in Probably have');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    // Mid-reload: the provider is loading again, the list is still there.
    expect(find.text('item 19'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    expect(find.text('item 19 moved to Probably have.'), findsOneWidget);
  });

  testWidgets('a long-press whose regeneration fails shows the failure only',
      (tester) async {
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('brašno', id: 'i-brasno')]),
      regenerateFailure: const NetworkFailure(),
    );

    await _pickFromMenu(tester, find.text('brašno'), 'Always in Probably have');
    await tester.pumpAndSettle();

    expect(calls.pantryPref?.ingredientId, 'i-brasno');
    expect(calls.regenerated, 1);
    expect(find.text(AppLocalizationsEn().failureOffline), findsOneWidget);
    expect(find.textContaining('moved to Probably have'), findsNothing);
  });

  testWidgets('an unmatched item cannot be given a pantry override',
      (tester) async {
    // There is no ingredient id to hang the preference off, so no menu.
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('so po ukusu', id: null)]),
    );

    await tester.longPress(find.textContaining('so po ukusu'));
    await tester.pumpAndSettle();

    expect(find.byType(MenuItemButton), findsNothing);
    expect(calls.pantryPref, isNull);
    expect(calls.regenerated, 0);
  });

  testWidgets('a to-buy row offers Always in Probably have; a Probably-have '
      'row offers Always on the list', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('brašno', id: 'i-brasno'),
        _item('sirće', id: 'i-sirce', staple: true),
      ], locale: 'en'),
    );

    await tester.longPress(find.text('brašno'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsOneWidget);
    expect(
      find.widgetWithText(MenuItemButton, 'Always in Probably have'),
      findsOneWidget,
    );
    // The pressed row holds the fill while its menu is open.
    final Finder fill = find.byKey(const Key('pressedRowFill'));
    expect(fill, findsOneWidget);
    expect(
      (tester.widget<DecoratedBox>(fill).decoration as BoxDecoration).color,
      AppTheme.light().colorScheme.surfaceContainerHighest,
    );
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Probably have (1)'));
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('sirće'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsOneWidget);
    expect(
      find.widgetWithText(MenuItemButton, 'Always on the list'),
      findsOneWidget,
    );
  });

  testWidgets('dismissing the menu records nothing and regenerates nothing',
      (tester) async {
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('brašno', id: 'i-brasno')]),
    );

    await tester.longPress(find.text('brašno'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsOneWidget);

    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    expect(find.byType(MenuItemButton), findsNothing);
    expect(find.byKey(const Key('pressedRowFill')), findsNothing);
    expect(calls.pantryPref, isNull);
    expect(calls.regenerated, 0);
  });

  testWidgets('Undo records the opposite override and regenerates again, '
      'with no second snackbar', (tester) async {
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('sirće', id: 'i-sirce', staple: true),
      ], locale: 'en'),
    );

    await tester.tap(find.text('Probably have (1)'));
    await tester.pumpAndSettle();
    await _pickFromMenu(tester, find.textContaining('sirće'), 'Always on the list');
    await tester.pumpAndSettle();
    expect(find.text('sirće is back on the list.'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await tester.pumpAndSettle();

    expect(calls.pantryPrefs, <({String ingredientId, bool? alwaysHave})>[
      (ingredientId: 'i-sirce', alwaysHave: false),
      (ingredientId: 'i-sirce', alwaysHave: true),
    ]);
    expect(calls.regenerated, 2);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a failed Undo shows the failure snackbar', (tester) async {
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('brašno', id: 'i-brasno')]),
      pantryPrefFailure: const NetworkFailure(),
    );

    await _pickFromMenu(tester, find.text('brašno'), 'Always in Probably have');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await tester.pumpAndSettle();

    expect(calls.pantryPrefs, hasLength(2));
    // The Undo's write failed, so nothing was regenerated a second time.
    expect(calls.regenerated, 1);
    expect(find.text(AppLocalizationsEn().failureOffline), findsOneWidget);
  });

  testWidgets('the menu and Undo render in Serbian under sr', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('brašno', id: 'i-brasno')]),
      locale: const Locale('sr'),
    );

    await _pickFromMenu(tester, find.text('brašno'), 'Uvek u Verovatno imate');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SnackBarAction, 'Poništi'), findsOneWidget);
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
    'every to-buy row draws its divider, the last row of a category block '
    'included; only the card\'s last row drops it (Phase 7 part 5\'s walk: '
    'block-end gaps with no divider read as uneven spacing, not grouping)',
    (tester) async {
      await _pump(
        tester,
        initial: _list(<ShoppingItem>[
          _item('brašno', id: 'i-b', category: 'pantry'),
          _item('šećer', id: 'i-s', category: 'pantry'),
          _item('luk', id: 'i-l', category: 'produce'),
        ]),
      );

      Finder dividerOf(String name) => find.descendant(
        of: find
            .ancestor(
              of: find.text(name),
              matching: find.byType(IngredientLineRow),
            )
            .first,
        matching: find.byKey(const Key('ingredientDivider')),
      );

      // Serbian labels sort Ostava before Povrće.
      expect(dividerOf('brašno'), findsOneWidget);
      // Last of its block, not of the card: keeps its divider.
      expect(dividerOf('šećer'), findsOneWidget);
      // Last row of the card: the card's edge does the separating.
      expect(dividerOf('luk'), findsNothing);
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

  // phase9-household-switch-loading -- between a switch and its data.
  group('household switch', () {
    testWidgets('mid-switch: the placeholder, none of the old list, Copy and '
        'Regenerate disabled; then the new household\'s empty state', (
      WidgetTester tester,
    ) async {
      final HeldHouseholdRepository repo =
          HeldHouseholdRepository(<Household>[_homeHousehold, _weekend]);
      final ProviderContainer container = await _pumpSwitchable(tester, repo);
      expect(find.text('Mleko'), findsOneWidget);
      expect(_action(tester, Icons.copy_outlined).onPressed, isNotNull);

      repo.currentHold = Completer<void>();
      final Future<void> switching = container
          .read(currentHouseholdProvider.notifier)
          .switchTo('weekend');
      await tester.pump();
      await tester.pump();

      expect(find.byType(HouseholdSwitchPlaceholder), findsOneWidget);
      expect(find.byType(HouseholdSwitchProgressBar), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget,
          reason: 'the 4dp bar alone, never the 2dp one beside it');
      expect(find.text('Mleko'), findsNothing);
      expect(_action(tester, Icons.copy_outlined).onPressed, isNull);
      expect(_action(tester, Icons.refresh_outlined).onPressed, isNull);

      repo.currentHold!.complete();
      await switching;
      await tester.pumpAndSettle();
      expect(find.byType(HouseholdSwitchPlaceholder), findsNothing);
      expect(find.byType(HouseholdSwitchProgressBar), findsNothing);
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Mleko'), findsNothing);
      // No list: today's rule hides both again.
      expect(find.byIcon(Icons.copy_outlined), findsNothing);
      expect(find.byIcon(Icons.refresh_outlined), findsNothing);
    });

    testWidgets('one household: the first load is still the 2dp bar', (
      WidgetTester tester,
    ) async {
      final HeldHouseholdRepository repo =
          HeldHouseholdRepository(<Household>[_homeHousehold])
            ..currentHold = Completer<void>();
      await _pumpSwitchable(tester, repo, settle: false);

      final LinearProgressIndicator bar = tester.widget(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.minHeight, 2);
      expect(find.byType(HouseholdSwitchPlaceholder), findsNothing);
      expect(find.byType(HouseholdSwitchProgressBar), findsNothing);

      repo.currentHold!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Mleko'), findsOneWidget);
      expect(find.byType(HouseholdSwitchPlaceholder), findsNothing);
    });
  });
}

const Household _homeHousehold =
    Household(id: 'h1', name: 'Kod Mire', createdBy: 'u1');
const Household _weekend =
    Household(id: 'weekend', name: 'Vikendica', createdBy: 'u1');

/// [currentShoppingListProvider] answering per household, the way the real
/// one keys on `currentHouseholdIdProvider`: a list for `h1`, none for the
/// weekend household.
class _HouseholdList extends _StubList {
  _HouseholdList() : super(null, _Calls());

  @override
  Stream<ShoppingList?> build() async* {
    final String? id = await ref.watch(currentHouseholdIdProvider.future);
    yield id == 'h1' ? _list(<ShoppingItem>[_item('Mleko')]) : null;
  }
}

Future<ProviderContainer> _pumpSwitchable(
  WidgetTester tester,
  HeldHouseholdRepository repo, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...householdSwitchOverrides(repo),
        currentShoppingListProvider.overrideWith(_HouseholdList.new),
        shoppingRangeProvider.overrideWith(() => _PinnedRange()),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: const ShoppingListScreen(),
      ),
    ),
  );
  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(ShoppingListScreen)),
  );
  container.listen(currentUserIdProvider, (_, _) {});
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return container;
}

IconButton _action(WidgetTester tester, IconData icon) =>
    tester.widget<IconButton>(
      find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
    );
