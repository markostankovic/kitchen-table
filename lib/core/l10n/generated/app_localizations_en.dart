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
}
