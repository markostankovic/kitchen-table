import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/households/application/household_providers.dart';
import '../../features/households/domain/household.dart';
import '../supabase/supabase_client.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// The application router.
///
/// `keepAlive` is justified: disposing the router would discard the entire
/// navigation stack, and it is watched by the root widget for the whole life
/// of the app (docs/ARCHITECTURE.md, "keepAlive only where justified").
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  // go_router re-runs `redirect` when this notifier fires. Bridging Riverpod
  // to it with `ref.listen` -- rather than `ref.watch` in the provider body --
  // is what keeps the router instance stable: watching would rebuild the
  // GoRouter on every auth change and reset the navigation stack.
  final _RouterRefresh refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);

  ref.listen(currentUserIdProvider, (_, _) => refresh.bump());
  ref.listen(currentHouseholdProvider, (_, _) => refresh.bump());

  return GoRouter(
    initialLocation: RecipesRoute.path,
    routes: $appRoutes,
    refreshListenable: refresh,

    /// Auth redirect is centralized here -- no per-screen auth checks
    /// (docs/ARCHITECTURE.md, "Routing").
    redirect: (_, GoRouterState state) {
      final AsyncValue<String?> auth = ref.read(currentUserIdProvider);

      // Session not yet known. Bounce nowhere rather than flashing the
      // sign-in screen at someone who is already signed in.
      if (!auth.hasValue) return null;

      final String location = state.matchedLocation;
      final bool signingIn = location == SignInRoute.path ||
          location.startsWith(VerifyOtpRoute.path);

      if (auth.value == null) {
        return signingIn ? null : SignInRoute.path;
      }

      final AsyncValue<Household?> household =
          ref.read(currentHouseholdProvider);
      if (!household.hasValue) return null;

      // Both onboarding branches must be listed. Omitting one bounces the
      // user back to create-household the moment they navigate to it,
      // which makes the screen unreachable rather than merely awkward.
      final bool onboarding = location == CreateHouseholdRoute.path ||
          location == JoinHouseholdRoute.path;
      if (household.value == null) {
        return onboarding ? null : CreateHouseholdRoute.path;
      }

      // Signed in and set up: nothing to do on the onboarding routes.
      if (signingIn || onboarding) return RecipesRoute.path;
      return null;
    },
  );
}

/// `notifyListeners` is protected on [ChangeNotifier], so a subclass exposes
/// it rather than an `// ignore:` at the call site.
class _RouterRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}
