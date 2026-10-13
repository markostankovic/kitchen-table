// Phase 7 part 15 (D137) -- create and join household, top-aligned per the
// design: a headlineSmall title on the left, the buttons pinned to the bottom.
//
// Built on sign_in_screen_test.dart's harness: a ProviderScope and a Serbian
// MaterialApp. The layout tests submit nothing, so the household repository
// is never read and needs no override. The submit tests (multi-household-b,
// D169) override it with a fake and check that create and join end on the
// NEW household, through CurrentHousehold.switchTo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/household/current_household.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/theme/app_sizes.dart';
import 'package:kitchen_table/core/theme/app_spacing.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/presentation/create_household_screen.dart';
import 'package:kitchen_table/features/households/presentation/join_household_screen.dart';
import 'package:kitchen_table/features/households/presentation/onboarding_mark.dart';

import '../../helpers/fake_household_repository.dart';

final AppLocalizations sr = AppLocalizationsSr();

const Size _phone = Size(360, 760);

Future<ThemeData> _pump(
  WidgetTester tester,
  Widget screen, {
  FakeHouseholdRepository? repo,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final ThemeData theme = AppTheme.light();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repo != null) ...[
          householdRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWith(
            (Ref ref) => Stream<String?>.value('u1'),
          ),
        ],
      ],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        locale: const Locale('sr'),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return theme;
}

void main() {
  for (final (String name, Widget screen, String title, String button)
      in <(String, Widget, String, String)>[
        (
          'create',
          const CreateHouseholdScreen(),
          sr.createHouseholdTitle,
          sr.createHouseholdButton,
        ),
        (
          'join',
          const JoinHouseholdScreen(),
          sr.joinHouseholdTitle,
          sr.joinButton,
        ),
      ]) {
    testWidgets('$name: the title is headlineSmall, left-aligned', (
      WidgetTester tester,
    ) async {
      final ThemeData theme = await _pump(tester, screen);

      final Text text = tester.widget<Text>(find.text(title));
      expect(text.style?.fontSize, theme.textTheme.headlineSmall?.fontSize);
      expect(
        text.textAlign == null || text.textAlign == TextAlign.start,
        isTrue,
      );
    });

    // phase9-household-create-join-another added an in-app "another" mode
    // to both screens; onboarding keeps its mark, no app bar, and the
    // cross-link.
    testWidgets('$name: onboarding keeps the mark and the cross-link, no bar', (
      WidgetTester tester,
    ) async {
      await _pump(tester, screen);

      expect(find.byType(OnboardingMark), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('$name: the buttons are pinned to the bottom', (
      WidgetTester tester,
    ) async {
      await _pump(tester, screen);

      // The filled button, then `sm`, then the full-width text button, whose
      // bottom sits `xxl` above the screen's -- and nothing scrolls, so that
      // air is on screen rather than below the fold.
      final double filled = tester
          .getBottomLeft(find.widgetWithText(FilledButton, button))
          .dy;
      final double last = tester.getBottomLeft(find.byType(TextButton)).dy;
      expect(_phone.height - last, AppSpacing.xxl);
      expect(last - filled, AppSpacing.sm + AppSizes.button);
      expect(
        tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(CustomScrollView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .maxScrollExtent,
        0,
      );
    });

    // The emulator's device walk could not open a full keyboard (Gboard stays
    // in its stylus toolbar), so the keyboard case is checked here: an
    // overflow would fail the pump, and the buttons scroll into reach.
    testWidgets('$name: with the keyboard open, nothing overflows', (
      WidgetTester tester,
    ) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await _pump(tester, screen);

      final Finder filled = find.widgetWithText(FilledButton, button);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.byType(TextButton)).dy,
        lessThanOrEqualTo(_phone.height - 300),
      );
      expect(filled.hitTestable(), findsOneWidget);
    });
  }

  testWidgets('join: the code field has its label', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const JoinHouseholdScreen());

    expect(find.text(sr.inviteCodeFieldLabel), findsOneWidget);
  });

  group('submit lands in the new household (D169)', () {
    // An existing household, so "the oldest" and "the new one" differ: only
    // a real switch makes the new one current.
    const Household existing =
        Household(id: 'existing', name: 'Existing', createdBy: 'u1');

    ProviderContainer containerOf(WidgetTester tester, Type screen) =>
        ProviderScope.containerOf(tester.element(find.byType(screen)));

    /// Listens the way app_router.dart's `ref.listen` does in the app, which
    /// is what keeps `currentUserIdProvider` live underneath it -- an
    /// unlistened provider is paused, and `switchTo` would read no user.
    Future<void> listenLikeTheRouter(WidgetTester tester, Type screen) async {
      containerOf(tester, screen).listen(currentHouseholdProvider, (_, _) {});
      await tester.pumpAndSettle();
    }

    Future<String?> currentId(WidgetTester tester, Type screen) =>
        containerOf(tester, screen).read(currentHouseholdIdProvider.future);

    testWidgets('create switches to the id create returned', (
      WidgetTester tester,
    ) async {
      final FakeHouseholdRepository repo =
          FakeHouseholdRepository(<Household>[existing]);
      await _pump(tester, const CreateHouseholdScreen(), repo: repo);
      await listenLikeTheRouter(tester, CreateHouseholdScreen);

      await tester.enterText(find.byType(TextFormField), 'Vikendica');
      await tester.tap(
        find.widgetWithText(FilledButton, sr.createHouseholdButton),
      );
      await tester.pumpAndSettle();

      expect(repo.selectCalls, <String>['created-2']);
      expect(
        await currentId(tester, CreateHouseholdScreen),
        'created-2',
      );
    });

    testWidgets('join switches to the id redeemInvite returned', (
      WidgetTester tester,
    ) async {
      final FakeHouseholdRepository repo =
          FakeHouseholdRepository(<Household>[existing]);
      await _pump(tester, const JoinHouseholdScreen(), repo: repo);
      await listenLikeTheRouter(tester, JoinHouseholdScreen);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.widgetWithText(FilledButton, sr.joinButton));
      await tester.pumpAndSettle();

      expect(repo.selectCalls, <String>['joined-123456']);
      expect(
        await currentId(tester, JoinHouseholdScreen),
        'joined-123456',
      );
    });
  });
}
