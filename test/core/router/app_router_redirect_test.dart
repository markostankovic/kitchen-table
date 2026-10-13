// phase9-household-create-join-another -- the in-app create / join routes
// need no entry in the redirect: it rewrites only sign-in and the two
// onboarding paths. Calls the real router's top-level redirect directly,
// rather than building the shell and its screens around it.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_table/core/router/app_router.dart';
import 'package:kitchen_table/core/router/routes.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';

import '../../helpers/fixed_current_household.dart';

const Household _home = Household(id: 'home', name: 'Kod kuće', createdBy: 'u1');

/// Signed in as `u1`, with [household] current (or none), both resolved
/// before the redirect reads them synchronously.
Future<GoRouter> _router(Household? household) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWith(
        (Ref ref) => Stream<String?>.value('u1'),
      ),
      currentHouseholdProvider.overrideWith(
        () => FixedCurrentHousehold(() async => household),
      ),
    ],
  );
  addTearDown(container.dispose);
  container
    ..listen(currentUserIdProvider, (_, _) {})
    ..listen(currentHouseholdProvider, (_, _) {});
  await container.read(currentUserIdProvider.future);
  await container.read(currentHouseholdProvider.future);
  return container.read(goRouterProvider);
}

Future<String?> _redirect(
  WidgetTester tester,
  GoRouter router,
  String location,
) async {
  await tester.pumpWidget(const SizedBox());
  return router.configuration.topRedirect(
    tester.element(find.byType(SizedBox)),
    GoRouterState(
      router.configuration,
      uri: Uri.parse(location),
      matchedLocation: location,
      fullPath: location,
      pathParameters: const <String, String>{},
      pageKey: ValueKey<String>(location),
    ),
  );
}

void main() {
  for (final String path in <String>[
    CreateAnotherHouseholdRoute.path,
    JoinAnotherHouseholdRoute.path,
  ]) {
    testWidgets('with a household, $path is not redirected', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await tester.runAsync(() => _router(_home))
          as GoRouter;

      expect(await _redirect(tester, router, path), isNull);
    });

    testWidgets('with no household, $path goes to create-household', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await tester.runAsync(() => _router(null))
          as GoRouter;

      expect(
        await _redirect(tester, router, path),
        CreateHouseholdRoute.path,
      );
    });
  }

  testWidgets('with a household, onboarding still goes to Recipes', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await tester.runAsync(() => _router(_home))
        as GoRouter;

    expect(
      await _redirect(tester, router, CreateHouseholdRoute.path),
      RecipesRoute.path,
    );
  });
}
