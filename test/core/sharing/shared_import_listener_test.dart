// A share has to survive arriving too early.
//
// app_router.dart's redirect sends every location to /sign-in while nobody is
// signed in, and to /create-household while there is no household -- and it
// returns a bare path, carrying no destination. So navigating the moment a
// share arrives loses it. These tests are the rule that stops that.
//
// Pumps the whole app the way app_shell_test.dart does, with the share source
// overridden rather than mocked (rule 8).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/sharing/share_providers.dart';
import 'package:kitchen_table/core/sharing/shared_import.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/features/auth/application/auth_providers.dart';
import 'package:kitchen_table/features/auth/domain/app_user.dart';
import 'package:kitchen_table/features/auth/domain/profile.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/main.dart';

const AppUser _user = AppUser(id: 'u1', email: 'a@example.com');
const Profile _profile = Profile(id: 'u1', displayName: 'Marko');
const Household _household =
    Household(id: 'h1', name: 'Test Household', createdBy: 'u1');

const String _url = 'https://www.bbcgoodfood.com/recipes/classic-lasagne';

Future<void> _pump(
  WidgetTester tester, {
  required SharedImport? share,
  String? userId = 'u1',
  Household? household = _household,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        incomingSharesProvider.overrideWith((Ref ref) => share == null
            ? const Stream<SharedImport>.empty()
            : Stream<SharedImport>.value(share)),
        currentUserIdProvider
            .overrideWith((Ref ref) => Stream<String?>.value(userId)),
        currentHouseholdProvider.overrideWith((Ref ref) async => household),
        authStateProvider.overrideWith((Ref ref) =>
            Stream<AppUser?>.value(userId == null ? null : _user)),
        ownProfileProvider.overrideWith((Ref ref) async => _profile),
      ],
      child: const KitchenTableApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a shared link opens the link importer, prefilled', (
    WidgetTester tester,
  ) async {
    await _pump(tester, share: const SharedUrl(_url));

    expect(find.widgetWithText(AppBar, 'Import from a link'), findsOneWidget);
    expect(find.text(_url), findsOneWidget,
        reason: 'the shared link should already be in the field');
  });

  testWidgets('it is prefilled, NOT submitted', (WidgetTester tester) async {
    await _pump(tester, share: const SharedUrl(_url));

    // The button is still there and still enabled: sharing the wrong page
    // costs a tap, not a model call.
    expect(find.text('Read this recipe'), findsOneWidget);
    final FilledButton button =
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('shared prose opens the paste importer instead', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      share: const SharedText('200 g šargarepe', sourceUrl: 'https://x.test/r'),
    );

    expect(find.widgetWithText(AppBar, 'Paste a recipe'), findsOneWidget);
    expect(find.text('200 g šargarepe'), findsOneWidget);
    expect(find.text('https://x.test/r'), findsOneWidget,
        reason: 'the link that came with the text is attribution');
  });

  testWidgets('a share arriving signed OUT is held, not swallowed', (
    WidgetTester tester,
  ) async {
    // The case the pending provider exists for. The redirect would send this
    // to /sign-in and drop the URL on the floor.
    await _pump(tester, share: const SharedUrl(_url), userId: null,
        household: null);

    expect(find.text('Send code'), findsOneWidget,
        reason: 'sign-in still wins; the share must not jump the queue');
    expect(find.widgetWithText(AppBar, 'Import from a link'), findsNothing);
  });

  testWidgets('a share arriving before onboarding is held too', (
    WidgetTester tester,
  ) async {
    await _pump(tester, share: const SharedUrl(_url), household: null);

    expect(find.text('Name your household'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Import from a link'), findsNothing);
  });

  testWidgets('no share means the app opens where it always did', (
    WidgetTester tester,
  ) async {
    await _pump(tester, share: null);

    expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
  });
}
