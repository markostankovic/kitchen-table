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
/// -- oldest undeleted household the caller belongs to). A repository-level
/// helper here would have meant a second definition of that tiebreak, in a
/// second place, and a Postgres round trip on every write this id feeds.
/// Riverpod's own caching means deriving it costs nothing extra.
///
/// Only the id is exposed here, not `currentHouseholdProvider` itself: the id
/// is what a second feature needs to scope its own writes, but the
/// `Household` model -- its name, who created it -- is the households
/// feature's business, the same way `core/ingredients/` exposes the catalog's
/// providers without becoming a second owner of `Ingredient`.
///
/// `core/` may depend on `features/` (docs/ARCHITECTURE.md); `tool/check_layers.dart`
/// derives layer and feature only from `lib/features` paths and does not
/// apply the cross-feature rule here, which is what makes this the sanctioned
/// place for a second feature to reach a first feature's output (D43 made the
/// same move for the ingredient catalog).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/households/application/household_providers.dart';
import '../../features/households/domain/household.dart';

part 'current_household.g.dart';

@Riverpod(keepAlive: true)
Future<String?> currentHouseholdId(Ref ref) async {
  final Household? household = await ref.watch(currentHouseholdProvider.future);
  return household?.id;
}
