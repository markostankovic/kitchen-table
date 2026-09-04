import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'routes.dart';

part 'app_router.g.dart';

/// The application router.
///
/// `keepAlive` is justified: disposing the router would discard the entire
/// navigation stack, and it is watched by the root widget for the whole life
/// of the app (docs/ARCHITECTURE.md, "keepAlive only where justified").
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: RecipesRoute.path,
    routes: $appRoutes,
    // Auth redirect is centralized here -- no per-screen auth checks
    // (docs/ARCHITECTURE.md, "Routing"). It is a no-op until Phase 1a adds
    // Supabase Auth; the hook exists now so there is one obvious place for it.
    redirect: (_, _) => null,
  );
}
