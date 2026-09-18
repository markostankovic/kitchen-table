/// Renders an [AppFailure] in the reader's locale (D92).
///
/// Presentation-side, so it may import Flutter: `tool/check_layers.dart`
/// derives a layer only from `lib/features/<name>/<layer>/`, so nothing under
/// `lib/core/` is subject to rule 7's ban -- `core/l10n/app_locale.dart` is
/// the standing precedent (D77), and `test/tool/check_layers_test.dart` pins
/// this file as the case that proves it deliberately. `app_failure.dart`
/// itself stays pure Dart, which is why this is a sibling function rather
/// than a method on the variants.
library;

import '../l10n/generated/app_localizations.dart';
import 'app_failure.dart';

/// The invariant: [AppFailure.code] null means [AppFailure.message] came
/// from somewhere that knows more than this client does, and is shown
/// verbatim; otherwise the code wins outright and [AppFailure.message] is
/// only ever a log line.
String localizedFailureMessage(AppFailure failure, AppLocalizations l10n) {
  final FailureCode? code = failure.code;
  return code == null ? failure.message : _sentence(code, l10n);
}

/// The entry point for an `AsyncValue.error`, whose `Object` is not
/// necessarily an [AppFailure]. Anything else renders [AppLocalizations
/// .failureUnknown] -- a raw `toString()` on screen is a driver message
/// leaking past the very boundary [AppFailure] exists to hold.
String localizedErrorMessage(Object error, AppLocalizations l10n) =>
    error is AppFailure
        ? localizedFailureMessage(error, l10n)
        : l10n.failureUnknown;

extension AppFailureL10n on AppFailure {
  /// `e.localized(l10n)` -- the shorthand for [localizedFailureMessage] at an
  /// `on AppFailure catch (e)` site, where the static type is already known.
  String localized(AppLocalizations l10n) =>
      localizedFailureMessage(this, l10n);
}

/// No `default` arm, deliberately: a new [FailureCode] must not compile until
/// it has a sentence here.
String _sentence(FailureCode code, AppLocalizations l10n) => switch (code) {
      FailureCode.offline => l10n.failureOffline,
      FailureCode.serverTooSlow => l10n.failureServerTooSlow,
      FailureCode.offlineNoSavedRecipes => l10n.failureOfflineNoSavedRecipes,
      FailureCode.offlineNoSavedPlan => l10n.failureOfflineNoSavedPlan,
      FailureCode.offlineNoSavedList => l10n.failureOfflineNoSavedList,
      FailureCode.signInAgain => l10n.failureSignInAgain,
      FailureCode.noHousehold => l10n.failureNoHousehold,
      FailureCode.tooManyAttempts => l10n.failureTooManyAttempts,
      FailureCode.googleSignInFailed => l10n.failureGoogleSignInFailed,
      FailureCode.notFound => l10n.failureNotFound,
      FailureCode.recipeNotFound => l10n.failureRecipeNotFound,
      FailureCode.noTranslationToReview => l10n.noTranslationToReview,
      FailureCode.inviteNotFound => l10n.failureInviteNotFound,
      FailureCode.inviteAlreadyUsed => l10n.failureInviteAlreadyUsed,
      FailureCode.inviteExpired => l10n.failureInviteExpired,
      FailureCode.codeNotAccepted => l10n.failureCodeNotAccepted,
      FailureCode.alreadyExists => l10n.failureAlreadyExists,
      FailureCode.aiAllowanceUsedUp => l10n.failureAiAllowanceUsedUp,
      FailureCode.unavailableTryLater => l10n.failureUnavailableTryLater,
      FailureCode.importPhotoFailed => l10n.failureImportPhotoFailed,
      FailureCode.invalidUrl => l10n.failureInvalidUrl,
      FailureCode.importTextTooLong => l10n.failureImportTextTooLong,
      FailureCode.importUnreadable => l10n.failureImportUnreadable,
      FailureCode.couldNotReadRecipe => l10n.failureCouldNotReadRecipe,
      FailureCode.alreadyInThatLanguage => l10n.failureAlreadyInThatLanguage,
      FailureCode.siteUnreachable => l10n.failureSiteUnreachable,
      FailureCode.notAWebPage => l10n.failureNotAWebPage,
      FailureCode.importTooLarge => l10n.failureImportTooLarge,
      FailureCode.importNotFound => l10n.failureImportNotFound,
      FailureCode.importAlreadySaved => l10n.failureImportAlreadySaved,
      FailureCode.importNotReadyYet => l10n.failureImportNotReadyYet,
      FailureCode.noRecipeOnPage => l10n.failureNoRecipeOnPage,
      FailureCode.couldNotMakeCode => l10n.failureCouldNotMakeCode,
      FailureCode.unexpectedServerReply => l10n.failureUnexpectedServerReply,
      FailureCode.unknown => l10n.failureUnknown,
    };
