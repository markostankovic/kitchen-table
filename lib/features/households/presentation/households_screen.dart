import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/household/current_household.dart';
import '../../../core/household/household_role_label.dart';
import '../../../core/household/widgets/household_row.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_error_view.dart';
import '../application/household_providers.dart';
import '../domain/household_membership.dart';

/// Every household the caller belongs to, in the order they joined. A row
/// switches to that household; its gear opens that household's screen,
/// current or not.
///
/// Reached from Settings only when there are two or more; with one, the
/// Settings row opens the Household screen directly.
class HouseholdsScreen extends ConsumerStatefulWidget {
  const HouseholdsScreen({super.key});

  @override
  ConsumerState<HouseholdsScreen> createState() => _HouseholdsScreenState();
}

class _HouseholdsScreenState extends ConsumerState<HouseholdsScreen> {
  /// True while a switch is in flight; every row is inert meanwhile, so
  /// nothing can be double-tapped.
  bool _switching = false;

  /// No success snackbar: the radio moving is the feedback here ("Now in X."
  /// is the switcher slice's).
  Future<void> _switchTo(String householdId, AppLocalizations l10n) async {
    setState(() => _switching = true);
    try {
      await ref.read(currentHouseholdProvider.notifier).switchTo(householdId);
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<HouseholdMembership>> mine = ref.watch(
      myHouseholdsProvider,
    );
    final String? currentId = ref.watch(currentHouseholdIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.householdsScreenTitle)),
      body: mine.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) =>
            AppErrorView(message: localizedErrorMessage(e, l10n)),
        data: (List<HouseholdMembership> memberships) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            Text(
              l10n.householdsIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  for (int n = 0; n < memberships.length; n++) ...<Widget>[
                    // Inset to line the hairline up with the names.
                    if (n > 0)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: AppSpacing.lg + AppSizes.icon + AppSpacing.lg,
                      ),
                    _row(memberships[n], currentId, l10n),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
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
      onTap: isCurrent || _switching ? null : () => _switchTo(id, l10n),
      onManage: () => HouseholdRoute(id).push<void>(context),
      manageTooltip: l10n.manageHouseholdTooltip(m.household.name),
    );
  }
}
