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
/// [householdSwitcherName] is the second, narrower still: just the current
/// household's name when there are others to switch to, for the tab header
/// (phase9-household-switcher).
/// [householdSwitchPending] and [householdSwitchTargetName] are the switch's
/// own two facts (phase9-household-switch-loading): whether one is in flight,
/// so Recipes, Plan and List can hold their loading state until their data is
/// the new household's, and the name it is switching to, so the header shows
/// it at once. A bool and a string, not the in-flight notifier, for the same
/// reason as above.
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

/// The current household's name when the caller has others to switch to;
/// null with one, while unknown, or offline (myHouseholds is network-only)
/// -- the tab header's whole condition for showing its second line.
///
/// Reads no members, unlike [currentHouseholdSummary]: the header must not
/// wait on a member-count query.
@riverpod
Future<String?> householdSwitcherName(Ref ref) async {
  final Household? household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return null;
  try {
    final List<HouseholdMembership> mine = await ref.watch(
      myHouseholdsProvider.future,
    );
    if (mine.length < 2) return null;
  } on AppFailure {
    return null;
  }
  return household.name;
}

/// Whether a household switch is in flight (`CurrentHousehold.switchTo`,
/// from the header, its Undo, or the Households list).
@riverpod
bool householdSwitchPending(Ref ref) =>
    ref.watch(householdSwitchInFlightProvider) != null;

/// The name of the household a switch in flight is switching to; null when
/// none is, or while the caller's households are not yet known.
///
/// `myHouseholds` reloads during a switch but keeps its previous value, so
/// `.value` is still the list the sheet was built from.
@riverpod
String? householdSwitchTargetName(Ref ref) {
  final String? id = ref.watch(householdSwitchInFlightProvider);
  if (id == null) return null;
  final List<HouseholdMembership>? mine = ref.watch(myHouseholdsProvider).value;
  if (mine == null) return null;
  for (final HouseholdMembership m in mine) {
    if (m.household.id == id) return m.household.name;
  }
  return null;
}
