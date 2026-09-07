import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/household_repository.dart';
import '../domain/household.dart';
import '../domain/household_invite.dart';
import '../domain/household_member.dart';

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

/// Everyone in the caller's household, for the member list.
///
/// Display names depend on `profiles_select_co_member`; without that policy
/// every co-member renders as unknown.
@riverpod
Future<List<HouseholdMember>> householdMembers(Ref ref) async {
  final Household? household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return const <HouseholdMember>[];
  return ref.watch(householdRepositoryProvider).fetchMembers(household.id);
}

/// Invite codes that can still be redeemed, newest first.
@riverpod
Future<List<HouseholdInvite>> liveInvites(Ref ref) async {
  final Household? household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return const <HouseholdInvite>[];
  return ref.watch(householdRepositoryProvider).fetchLiveInvites(household.id);
}
