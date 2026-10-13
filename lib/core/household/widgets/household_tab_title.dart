import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../error/app_failure.dart';
import '../../error/failure_l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../router/routes.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../../features/households/application/household_providers.dart';
import '../current_household.dart';
import 'household_switch_sheet.dart';

/// A tab root's app bar title -- Recipes, Plan, List -- with the current
/// household's name and a ▾ under it when there are others to switch to
/// (phase9-household-switcher). Tapping it opens the switch sheet.
///
/// With one household, while that is unknown, or offline
/// ([householdSwitcherNameProvider] null, loading or error), it is the plain
/// title, the same pixels as before: every tab bar sets `titleSpacing:
/// AppSpacing.sm` and this supplies the other `sm`, so the title sits at 16
/// in both modes.
class HouseholdTabTitle extends ConsumerStatefulWidget {
  const HouseholdTabTitle({required this.title, super.key});

  final String title;

  @override
  ConsumerState<HouseholdTabTitle> createState() => _HouseholdTabTitleState();
}

class _HouseholdTabTitleState extends ConsumerState<HouseholdTabTitle> {
  /// True while a switch is in flight; the block is inert meanwhile.
  bool _switching = false;

  /// Undo runs on the captured notifier and messenger, not `ref` or
  /// `context`: the tab may have rebuilt or gone by the time it is tapped.
  Future<void> _openSheet() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final CurrentHousehold notifier = ref.read(
      currentHouseholdProvider.notifier,
    );
    // From `currentHouseholdProvider`, which the header's own condition
    // already resolved, rather than `currentHouseholdIdProvider`, which may
    // not have been read yet and so still be loading.
    final String? previousId = ref.read(currentHouseholdProvider).value?.id;

    final HouseholdSwitchPick? pick = await showHouseholdSwitchSheet(context);
    if (!mounted) return;
    switch (pick) {
      case null:
        return;
      case ManageHouseholds():
        const HouseholdsRoute().go(context);
      case SwitchToHousehold(:final String id, :final String name):
        setState(() => _switching = true);
        try {
          await notifier.switchTo(id);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.nowInHousehold(name)),
                // A snackbar with an action persists by default in this
                // Flutter; keep the usual 4 s auto-dismiss (D152's precedent).
                persist: false,
                action: previousId == null
                    ? null
                    : SnackBarAction(
                        label: l10n.undoSnackbarAction,
                        onPressed: () => _undo(notifier, previousId, messenger,
                            l10n),
                      ),
              ),
            );
        } on AppFailure catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(e.localized(l10n))));
        } finally {
          if (mounted) setState(() => _switching = false);
        }
    }
  }

  /// No second snackbar on success; a failure shows the localized error.
  static Future<void> _undo(
    CurrentHousehold notifier,
    String previousId,
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
  ) async {
    try {
      await notifier.switchTo(previousId);
    } on AppFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? name = ref.watch(householdSwitcherNameProvider).value;
    if (name == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(widget.title),
      );
    }

    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Color secondary = theme.colorScheme.onSurfaceVariant;
    // The app bar's `titleLarge`, read above the [Material]: a Material
    // resets the default text style to `bodyMedium` for what is under it.
    final TextStyle titleStyle = DefaultTextStyle.of(context).style;
    return Semantics(
      button: true,
      onTapHint: l10n.switchHouseholdSheetTitle,
      child: SizedBox(
        // Fills the bar less `xs` top and bottom.
        height: AppSizes.appBar - 2 * AppSpacing.xs,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: _switching ? null : _openSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: secondary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.expand_more,
                        size: AppSizes.iconInButton,
                        color: secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
