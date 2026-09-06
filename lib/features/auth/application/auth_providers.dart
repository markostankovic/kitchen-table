import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/profile.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(supabaseClientProvider));

/// The signed-in user, or null.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation, and letting it dispose between listeners would resubscribe to
/// the auth stream on each route change.
@Riverpod(keepAlive: true)
Stream<AppUser?> authState(Ref ref) =>
    ref.watch(authRepositoryProvider).watchAuthState();

/// The caller's own profile, refetched whenever the signed-in user changes.
@riverpod
Future<Profile?> ownProfile(Ref ref) async {
  final AppUser? user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).fetchOwnProfile();
}
