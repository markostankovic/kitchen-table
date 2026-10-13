import '../../features/households/domain/household_member.dart';
import '../l10n/generated/app_localizations.dart';

/// A [HouseholdRole]'s label, shared by the Households list and the household
/// switch sheet so the role `switch` has one home.
///
/// No `default` arm, as on the Household screen: a new `HouseholdRole` must
/// not compile until it has a label.
String householdRoleLabel(HouseholdRole role, AppLocalizations l10n) =>
    switch (role) {
      HouseholdRole.owner => l10n.householdRoleOwner,
      HouseholdRole.adult => l10n.householdRoleAdult,
    };
