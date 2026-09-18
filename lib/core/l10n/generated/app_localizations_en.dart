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
  String get orDivider => 'or';

  @override
  String get signInWithGoogle => 'Sign in with Google';

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
  String get failureGoogleSignInFailed => 'Google sign-in failed. Try again.';

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

  @override
  String get offlineBannerMessage =>
      'You\'re offline — showing saved copies. Changes won\'t save.';

  @override
  String recipeServingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '$count serving',
    );
    return '$_temp0';
  }

  @override
  String recipePrepMinutes(int minutes) {
    return '$minutes min prep';
  }

  @override
  String recipeCookMinutes(int minutes) {
    return '$minutes min cook';
  }

  @override
  String get ingredientOptionalTrailer => 'optional';

  @override
  String get ingredientNotMatchedTooltip => 'Not matched to an ingredient';

  @override
  String snackSlotCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count snack slots',
      one: '$count snack slot',
    );
    return '$_temp0';
  }

  @override
  String ingredientsMatchedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingredients',
      one: '$count ingredient',
    );
    return '$_temp0';
  }

  @override
  String get addRecipeTooltip => 'Add a recipe';

  @override
  String get newRecipeMenuItem => 'New recipe';

  @override
  String get importFromLinkMenuItem => 'Import from a link';

  @override
  String get pasteRecipeMenuItem => 'Paste a recipe';

  @override
  String get photographPageMenuItem => 'Photograph a page';

  @override
  String get searchRecipesHint => 'Search recipes';

  @override
  String get noRecipesMatch => 'No recipes match that.';

  @override
  String get noRecipesYet => 'No recipes yet.\n\nAdd one you know by heart.';

  @override
  String get newRecipeTitle => 'New recipe';

  @override
  String get editRecipeTitle => 'Edit recipe';

  @override
  String get servingsFieldLabel => 'Servings';

  @override
  String get prepMinutesFieldLabel => 'Prep (min)';

  @override
  String get cookMinutesFieldLabel => 'Cook (min)';

  @override
  String get writtenInFieldLabel => 'Written in';

  @override
  String get statusFieldLabel => 'Status';

  @override
  String get testedStatusLabel => 'Tested';

  @override
  String get tagsFieldLabel => 'Tags';

  @override
  String get tagsHelperText => 'Separated by commas';

  @override
  String get addIngredientButton => 'Add ingredient';

  @override
  String get addStepButton => 'Add step';

  @override
  String get saveButton => 'Save';

  @override
  String get cameraButton => 'Camera';

  @override
  String get galleryButton => 'Gallery';

  @override
  String get removePhotoTooltip => 'Remove photo';

  @override
  String get removeTooltip => 'Remove';

  @override
  String get wholeNumberError => 'Whole number.';

  @override
  String atLeastError(int minimum) {
    return 'At least $minimum.';
  }

  @override
  String get ingredientLineHint => '2 cups all-purpose flour';

  @override
  String get ingredientNoMatchLabel => 'No match';

  @override
  String ingredientSuggestionLabel(String name) {
    return '$name?';
  }

  @override
  String ingredientPickerQuestion(String query) {
    return 'Which ingredient is “$query”?';
  }

  @override
  String get ingredientPickerNoMatches => 'Nothing in the catalog matches.';

  @override
  String ingredientPickerCreateNew(String query) {
    return 'Create “$query”';
  }

  @override
  String get ingredientPickerCreateNewSubtitle =>
      'Adds it to the catalog for the household';

  @override
  String ingredientPickerMatchedByAlias(String name) {
    return 'matched “$name”';
  }

  @override
  String get ingredientPickerUnverifiedTooltip =>
      'Added by someone, not from the curated list';

  @override
  String get addNoteInsteadMenuItem => 'Add a note instead';

  @override
  String get addNoteInsteadSubtitle =>
      '\"leftovers\", \"eating out\" -- no recipe';

  @override
  String get addNoteDialogTitle => 'Add a note';

  @override
  String get addNoteHint => 'e.g. leftovers';

  @override
  String get addButton => 'Add';

  @override
  String get createHouseholdTitle => 'Name your household';

  @override
  String get createHouseholdSubtitle =>
      'Recipes and meal plans are shared with everyone in it.';

  @override
  String get householdNameFieldLabel => 'Household name';

  @override
  String get householdNameEmptyError => 'Enter a name.';

  @override
  String get createHouseholdButton => 'Create';

  @override
  String get haveInviteCodeButton => 'I have an invite code';

  @override
  String get householdScreenTitle => 'Household';

  @override
  String get noHouseholdYet => 'No household yet.';

  @override
  String get membersSectionTitle => 'Members';

  @override
  String get inviteSomeoneSectionTitle => 'Invite someone';

  @override
  String get loadingEllipsis => 'Loading...';

  @override
  String get noActiveCodesMessage =>
      'No active codes. Create one and read it out to whoever is joining.';

  @override
  String get copyCodeTooltip => 'Copy code';

  @override
  String get creatingEllipsis => 'Creating...';

  @override
  String get createInviteCodeButton => 'Create invite code';

  @override
  String get codeCopiedSnackbar => 'Code copied.';

  @override
  String get inviteExpiresWithinHour => 'Expires within the hour';

  @override
  String inviteExpiresInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expires in $count hours',
      one: 'Expires in $count hour',
    );
    return '$_temp0';
  }

  @override
  String inviteExpiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expires in $count days',
      one: 'Expires in $count day',
    );
    return '$_temp0';
  }

  @override
  String get householdRoleOwner => 'Owner';

  @override
  String get householdRoleAdult => 'Member';

  @override
  String get unknownDisplayName => 'Unknown';

  @override
  String get joinHouseholdTitle => 'Enter your invite code';

  @override
  String get joinHouseholdSubtitle =>
      'Ask someone in the household to generate a code for you.';

  @override
  String get joinButton => 'Join';

  @override
  String get createHouseholdInsteadButton => 'Create a household instead';

  @override
  String get importPasteTitle => 'Paste a recipe';

  @override
  String get importPasteBody =>
      'Paste the whole thing -- ingredients, method, whatever else came with it. Extra text around the recipe is fine.';

  @override
  String get importPasteHint =>
      'Carrot cake\n\n200 g carrots\n2 cups all-purpose flour…';

  @override
  String get importSourceFieldLabel => 'Where it came from (optional)';

  @override
  String get importSourceHelperText => 'Stored and shown with the recipe.';

  @override
  String get readRecipeButton => 'Read this recipe';

  @override
  String get importPhotoTitle => 'Photograph a page';

  @override
  String get importPhotoBody =>
      'Fill the frame with the recipe. A whole page is fine -- two columns, a sidebar of ingredients, a photo of the dish. Anything it credits is saved with the recipe.';

  @override
  String get takePhotoButton => 'Take a photo';

  @override
  String get choosePhotoButton => 'Choose a photo';

  @override
  String get importUrlTitle => 'Import from a link';

  @override
  String get importUrlBody =>
      'Paste the address of a recipe page. Whatever the page credits as its source is saved with the recipe.';

  @override
  String get linkFieldLabel => 'Link';

  @override
  String get reviewImportTitle => 'Review import';

  @override
  String get readingRecipeEllipsis => 'Reading the recipe...';

  @override
  String get queuedEllipsis => 'Queued...';

  @override
  String get importWaitingHint =>
      'This takes a few seconds. You can leave and come back.';

  @override
  String get discardImportButton => 'Discard this import';

  @override
  String get openRecipeButton => 'Open the recipe';

  @override
  String get methodHeading => 'Method';

  @override
  String get saveRecipeButton => 'Save recipe';

  @override
  String importMatchedOfTotal(int matched, String totalPhrase) {
    return '$matched of $totalPhrase matched';
  }

  @override
  String importWorthALook(int attention) {
    return '$attention worth a look before saving';
  }

  @override
  String get thisWeekTooltip => 'This week';

  @override
  String get previousWeekTooltip => 'Previous week';

  @override
  String get nextWeekTooltip => 'Next week';

  @override
  String get savedCopyOfflineMessage =>
      'Showing your saved copy — no connection.';

  @override
  String get mealSlotBreakfast => 'Breakfast';

  @override
  String get mealSlotLunch => 'Lunch';

  @override
  String get mealSlotDinner => 'Dinner';

  @override
  String get mealSlotSnack => 'Snack';

  @override
  String get snackRepeatWarningTitle => 'Already planned recently';

  @override
  String snackRepeatWarningBody(String countPhrase) {
    return 'Already in $countPhrase this fortnight.';
  }

  @override
  String get addAnywayButton => 'Add anyway';

  @override
  String get openRecipeMenuItem => 'Open recipe';

  @override
  String get cookingForMenuItem => 'Cooking for...';

  @override
  String get asTheRecipeSaysLabel => 'As the recipe says';

  @override
  String asTheRecipeSaysWithCount(int count) {
    return 'As the recipe says ($count)';
  }

  @override
  String get planLeftoversMenuItem => 'Plan leftovers...';

  @override
  String get moveToMenuItem => 'Move to...';

  @override
  String get moveUpMenuItem => 'Move up';

  @override
  String get moveDownMenuItem => 'Move down';

  @override
  String get cookingForDialogTitle => 'Cooking for';

  @override
  String get servingsUnknownExplanation =>
      'This recipe does not say how many it serves, so the shopping list cannot scale it.';

  @override
  String get servingsScalesExplanation =>
      'The shopping list scales this meal\'s ingredients to match.';

  @override
  String get moveToDialogTitle => 'Move to';

  @override
  String get dayFieldLabel => 'Day';

  @override
  String get slotFieldLabel => 'Slot';

  @override
  String get moveButton => 'Move';

  @override
  String get planLeftoversDialogTitle => 'Plan leftovers';

  @override
  String leftoverEntryLabel(String title) {
    return 'Leftovers: $title';
  }

  @override
  String get regenerateTooltip => 'Regenerate';

  @override
  String get pickDatesTooltip => 'Pick dates';

  @override
  String get thisWeekButton => 'This week';

  @override
  String get nextWeekButton => 'Next';

  @override
  String get noListYetTitle => 'No list yet.';

  @override
  String get noListYetBody =>
      'Generate one from what you have planned for these dates.';

  @override
  String get generateListButton => 'Generate list';

  @override
  String get nothingToBuyMessage =>
      'Nothing to buy -- there was nothing planned for these dates.';

  @override
  String probablyHaveHeading(int count) {
    return 'Probably have ($count)';
  }

  @override
  String get cupboardStaplesSubtitle => 'Cupboard staples';

  @override
  String generatedForRangeLine(String generatedDate, String from, String to) {
    return 'Generated $generatedDate for $from – $to';
  }

  @override
  String get categoryProduce => 'Produce';

  @override
  String get categoryFruit => 'Fruit';

  @override
  String get categoryDairy => 'Dairy';

  @override
  String get categoryMeat => 'Meat';

  @override
  String get categoryFish => 'Fish';

  @override
  String get categoryPantry => 'Pantry';

  @override
  String get categorySpice => 'Spices';

  @override
  String get categoryBakery => 'Bakery';

  @override
  String get categoryBeverage => 'Beverages';

  @override
  String get categoryNuts => 'Nuts';

  @override
  String get categoryOther => 'Other';

  @override
  String markedAsStapleSnackbar(String name) {
    return '$name marked as always in the cupboard. Takes effect next time you generate.';
  }

  @override
  String willBeOnListSnackbar(String name) {
    return '$name will be on the list from now on.';
  }
}
