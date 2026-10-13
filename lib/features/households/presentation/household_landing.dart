import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../application/household_providers.dart';

/// The snackbar action after landing in another household.
enum HouseholdLandingAction {
  /// After a create: opens the new household's screen, where "Create invite
  /// code" is. Navigates only -- it does not mint a code.
  invite,

  /// After a join: switches back to the household the caller was in.
  undo,
}

/// Switches to [id], lands on the Recipes root, and says "Now in [name]."
/// with [action] (phase9-household-create-join-another).
///
/// The shape of `HouseholdTabTitle`'s switch: the messenger, router, strings
/// and notifier are captured before the await, because the form that calls
/// this is gone once the router has gone to Recipes.
///
/// An [AppFailure] from the switch propagates; the caller shows it in its
/// own failure line and owns its busy flag and `mounted` checks.
Future<void> landInHousehold(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String name,
  required HouseholdLandingAction action,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final GoRouter router = GoRouter.of(context);
  final AppLocalizations l10n = AppLocalizations.of(context);
  final CurrentHousehold notifier = ref.read(currentHouseholdProvider.notifier);
  final String? previousId = ref.read(currentHouseholdProvider).value?.id;

  await notifier.switchTo(id);
  router.go(const RecipesRoute().location);

  final SnackBarAction? snackBarAction = switch (action) {
    HouseholdLandingAction.invite => SnackBarAction(
      label: l10n.inviteSnackbarAction,
      onPressed: () => router.go(HouseholdRoute(id).location),
    ),
    HouseholdLandingAction.undo when previousId != null => SnackBarAction(
      label: l10n.undoSnackbarAction,
      onPressed: () => _undo(notifier, previousId, messenger, l10n),
    ),
    HouseholdLandingAction.undo => null,
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.nowInHousehold(name)),
        // A snackbar with an action persists by default in this Flutter;
        // keep the usual 4 s auto-dismiss (D152's precedent).
        persist: false,
        action: snackBarAction,
      ),
    );
}

/// No second snackbar on success; a failure shows the localized error.
Future<void> _undo(
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
