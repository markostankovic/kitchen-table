/// The caller's current household id, as one cross-feature currency.
///
/// D33 named the trigger for this exact move: `RecipeRepository`'s own
/// `_currentHouseholdId` comment said "if a third feature needs it, that is
/// the signal to revisit D33 rather than to write a third copy." `meal_plan`
/// is that third feature (D52), and this closes the note rather than adding a
/// third copy of the query.
///
/// Derived from `currentHouseholdProvider` rather than a new
/// `households`-table query: that provider is already `keepAlive` and already
/// the one definition of "which household" (`HouseholdRepository.fetchCurrent`
/// -- the household selected on this device, else the oldest, D169). A
/// repository-level helper here would have meant a second definition of that
/// tiebreak, in a second place, and a Postgres round trip on every write this
/// id feeds.
/// Riverpod's own caching means deriving it costs nothing extra.
///
/// Only the id is exposed here, not `currentHouseholdProvider` itself: the id
/// is what a second feature needs to scope its own writes, but the
/// `Household` model -- its name, who created it -- is the households
/// feature's business, the same way `core/ingredients/` exposes the catalog's
/// providers without becoming a second owner of `Ingredient`.
///
/// [currentHouseholdSummary] is the one exception, and a narrow one (Phase 7
/// part 9b): the Settings screen (`features/auth/`) shows the household's
/// name and member count on the row that opens the household screen. It
/// also carries the household's id, so Settings can route to that
/// household's screen, and how many other households the caller is in, so
/// the row can open the Households list instead (phase9-household-list). It
/// crosses as a record of exactly those facts, not the `Household` model,
/// so this file still hands out no households-feature types.
///
/// `core/` may depend on `features/` (docs/ARCHITECTURE.md); `tool/check_layers.dart`
/// derives layer and feature only from `lib/features` paths and does not
/// apply the cross-feature rule here, which is what makes this the sanctioned
/// place for a second feature to reach a first feature's output (D43 made the
/// same move for the ingredient catalog).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../error/app_failure.dart';
import '../../features/households/application/household_providers.dart';
import '../../features/households/domain/household.dart';
import '../../features/households/domain/household_member.dart';
import '../../features/households/domain/household_membership.dart';

part 'current_household.g.dart';

@Riverpod(keepAlive: true)
Future<String?> currentHouseholdId(Ref ref) async {
  final Household? household = await ref.watch(currentHouseholdProvider.future);
  return household?.id;
}

/// The current household's id, name and member count, and how many other
/// households the caller is in; or null when there is no household -- see
/// this file's doc comment for why a record.
///
/// [otherHouseholdCount] falls to 0 on an [AppFailure]: `myHouseholds` is
/// network-only while the current household has a cache, so offline the row
/// takes the one-household look rather than failing whole.
@riverpod
Future<({String id, String name, int memberCount, int otherHouseholdCount})?>
currentHouseholdSummary(Ref ref) async {
  final Household? household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return null;
  final List<HouseholdMember> members = await ref.watch(
    householdMembersProvider(household.id).future,
  );
  int others;
  try {
    final List<HouseholdMembership> mine = await ref.watch(
      myHouseholdsProvider.future,
    );
    others = mine.length - 1;
  } on AppFailure {
    others = 0;
  }
  return (
    id: household.id,
    name: household.name,
    memberCount: members.length,
    otherHouseholdCount: others < 0 ? 0 : others,
  );
}
