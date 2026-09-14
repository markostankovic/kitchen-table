// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navRecipes => 'Recipes';

  @override
  String get navPlan => 'Plan';

  @override
  String get navList => 'List';

  @override
  String get navSettings => 'Settings';

  @override
  String get profileLoading => 'Loading...';

  @override
  String get profileLoadError => 'Could not load your profile';

  @override
  String get profileNone => 'No profile';

  @override
  String get householdMenuItem => 'Household';

  @override
  String get signOut => 'Sign out';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get signInSubtitle => 'Sign in with a code sent to your email.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailEmptyError => 'Enter your email address.';

  @override
  String get emailInvalidError => 'That does not look like an email address.';

  @override
  String get sendCode => 'Send code';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String codeSentTo(String email) {
    return 'We sent a code to $email.';
  }

  @override
  String get codeEmptyError => 'Enter the code from your email.';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Send a new code';

  @override
  String get newCodeSent => 'New code sent.';

  @override
  String get recipeDetailFallbackTitle => 'Recipe';

  @override
  String get couldNotLoadRecipe => 'Could not load this recipe.';

  @override
  String get editTooltip => 'Edit';

  @override
  String get deleteRecipeMenuItem => 'Delete recipe';

  @override
  String get deleteRecipeDialogTitle => 'Delete this recipe?';

  @override
  String get deleteRecipeDialogBody =>
      'It will stop appearing in your household’s recipes.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get ingredientsHeading => 'Ingredients';

  @override
  String get stepsHeading => 'Steps';

  @override
  String get noIngredientsYet => 'No ingredients yet.';

  @override
  String get noStepsYet => 'No steps yet.';

  @override
  String get draftChipLabel => 'Draft';

  @override
  String get machineTranslationChipLabel => 'Machine translation';

  @override
  String translateAction(String language) {
    return 'Translate to $language';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSerbian => 'Serbian';

  @override
  String get reviewTranslationMenuItem => 'Review translation';

  @override
  String get reviewTranslationTitle => 'Review translation';

  @override
  String originalTextLabel(String language) {
    return 'Original ($language)';
  }

  @override
  String get titleLabel => 'Title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String stepLabel(int number) {
    return 'Step $number';
  }

  @override
  String get titleRequiredError => 'Enter a title.';

  @override
  String get saveReviewButton => 'Save and approve';

  @override
  String get noTranslationToReview => 'There is no translation to review yet.';

  @override
  String get failureOffline => 'No connection.';

  @override
  String get failureServerTooSlow => 'The server took too long to respond.';

  @override
  String get failureOfflineNoSavedRecipes =>
      'No connection, and no saved recipes on this phone yet.';

  @override
  String get failureOfflineNoSavedPlan =>
      'No connection, and no saved plan on this phone yet.';

  @override
  String get failureOfflineNoSavedList =>
      'No connection, and no saved list on this phone yet.';

  @override
  String get failureSignInAgain => 'Please sign in again.';

  @override
  String get failureNoHousehold => 'You are not in a household yet.';

  @override
  String get failureTooManyAttempts =>
      'Too many attempts. Wait a minute and try again.';

  @override
  String get failureNotFound => 'Not found.';

  @override
  String get failureRecipeNotFound => 'That recipe is not available.';

  @override
  String get failureInviteNotFound => 'That code is not valid.';

  @override
  String get failureInviteAlreadyUsed => 'That code has already been used.';

  @override
  String get failureInviteExpired => 'That code has expired.';

  @override
  String get failureCodeNotAccepted => 'That code was not accepted.';

  @override
  String get failureAlreadyExists => 'That already exists.';

  @override
  String get failureAiAllowanceUsedUp =>
      'This household has used its AI allowance for the month.';

  @override
  String get failureUnavailableTryLater =>
      'That is unavailable right now. Try again later.';

  @override
  String get failureImportPhotoFailed => 'That photo could not be imported.';

  @override
  String get failureInvalidUrl => 'That does not look like a link.';

  @override
  String get failureImportTextTooLong => 'That text is too long to import.';

  @override
  String get failureImportUnreadable => 'That text could not be imported.';

  @override
  String get failureCouldNotReadRecipe => 'Could not read that recipe.';

  @override
  String get failureAlreadyInThatLanguage =>
      'This recipe is already written in that language.';

  @override
  String get failureSiteUnreachable => 'That site could not be reached.';

  @override
  String get failureNotAWebPage => 'That link is not a web page.';

  @override
  String get failureImportTooLarge => 'That is too large to import.';

  @override
  String get failureImportNotFound => 'That import was not found.';

  @override
  String get failureImportAlreadySaved => 'This import has already been saved.';

  @override
  String get failureImportNotReadyYet => 'This import is not ready yet.';

  @override
  String get failureNoRecipeOnPage => 'No recipe was found on that page.';

  @override
  String get failureCouldNotMakeCode => 'Could not create a code.';

  @override
  String get failureUnexpectedServerReply =>
      'The server sent an unexpected reply.';

  @override
  String get failureUnknown => 'Something went wrong.';

  @override
  String get photoCouldNotBeOpened => 'That photo could not be opened.';
}
