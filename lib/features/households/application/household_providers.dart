import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/household_repository.dart';
import '../domain/household.dart';

part 'household_providers.g.dart';

@Riverpod(keepAlive: true)
HouseholdRepository householdRepository(Ref ref) =>
    HouseholdRepository(ref.watch(supabaseClientProvider));

/// The caller's current household, or null if they have not created one.
///
/// Watches `currentUserIdProvider` from `core/` rather than the auth feature's
/// own provider: a different user has a different household, and a signed-out
/// one has none -- but reaching into `features/auth/application/` would be the
/// cross-feature import CLAUDE.md forbids.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation to decide whether onboarding is finished.
@Riverpod(keepAlive: true)
Future<Household?> currentHousehold(Ref ref) async {
  final String? userId = ref.watch(currentUserIdProvider).value;
  if (userId == null) return null;
  return ref.watch(householdRepositoryProvider).fetchCurrent();
}
