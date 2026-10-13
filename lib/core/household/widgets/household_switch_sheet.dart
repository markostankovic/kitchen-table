import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../error/failure_l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_error_view.dart';
import '../../../features/households/application/household_providers.dart';
import '../../../features/households/domain/household_membership.dart';
import '../current_household.dart';
import '../household_role_label.dart';
import 'household_row.dart';

/// What the caller decided in the household switch sheet.
///
/// The sheet performs no writes of its own -- it returns the decision and
/// its caller switches, the same split `showRecipePicker` and
/// `showMealSlotPicker` use.
sealed class HouseholdSwitchPick {
  const HouseholdSwitchPick();
}

/// Another household, picked from the list. [name] rides along for the
/// "Now in X." snackbar.
class SwitchToHousehold extends HouseholdSwitchPick {
  const SwitchToHousehold(this.id, this.name);

  final String id;
  final String name;
}

/// The Manage households row: open Settings › Households.
class ManageHouseholds extends HouseholdSwitchPick {
  const ManageHouseholds();
}

/// Lists the caller's households, in join order, to switch between
/// (phase9-household-switcher). Opened from `HouseholdTabTitle` on the
/// Recipes, Plan and List tabs.
///
/// The theme's sheet fill and a `titleMedium` title, as Add meal has.
Future<HouseholdSwitchPick?> showHouseholdSwitchSheet(BuildContext context) =>
    showModalBottomSheet<HouseholdSwitchPick>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => const _HouseholdSwitchSheet(),
    );

class _HouseholdSwitchSheet extends ConsumerWidget {
  const _HouseholdSwitchSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AsyncValue<List<HouseholdMembership>> mine = ref.watch(
      myHouseholdsProvider,
    );
    final String? currentId = ref.watch(currentHouseholdIdProvider).value;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.switchHouseholdSheetTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            ...mine.when(
              loading: () => <Widget>[
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (Object e, _) => <Widget>[
                AppErrorView(message: localizedErrorMessage(e, l10n)),
              ],
              data: (List<HouseholdMembership> memberships) => <Widget>[
                // No hairlines between rows (the canvas).
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final HouseholdMembership m in memberships)
                        _row(context, m, currentId, l10n),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            ListTile(
              leading: Icon(
                Icons.settings_outlined,
                size: AppSizes.icon,
                color: colors.onSurfaceVariant,
              ),
              title: Text(
                l10n.manageHouseholdsAction,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: AppSizes.icon,
                color: colors.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              onTap: () => Navigator.of(context).pop(const ManageHouseholds()),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    HouseholdMembership m,
    String? currentId,
    AppLocalizations l10n,
  ) {
    final String id = m.household.id;
    final bool isCurrent = id == currentId;
    return HouseholdRow(
      name: m.household.name,
      meta: l10n.householdListRowMeta(
        l10n.householdMemberCount(m.memberCount),
        householdRoleLabel(m.role, l10n),
      ),
      isCurrent: isCurrent,
      onTap: isCurrent
          ? null
          : () => Navigator.of(context).pop(
              SwitchToHousehold(id, m.household.name),
            ),
    );
  }
}
