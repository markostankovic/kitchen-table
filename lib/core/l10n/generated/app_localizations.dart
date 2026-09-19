import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sr'),
  ];

  /// Bottom nav label and AppBar title for the Recipes tab.
  ///
  /// In sr, this message translates to:
  /// **'Recepti'**
  String get navRecipes;

  /// Bottom nav label and AppBar title for the meal-plan tab.
  ///
  /// In sr, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// Bottom nav label and AppBar title for the shopping-list tab.
  ///
  /// In sr, this message translates to:
  /// **'Lista'**
  String get navList;

  /// Bottom nav label and AppBar title for the Settings tab.
  ///
  /// In sr, this message translates to:
  /// **'Podešavanja'**
  String get navSettings;

  /// Settings screen, shown while the caller's own profile is loading.
  ///
  /// In sr, this message translates to:
  /// **'Učitavanje...'**
  String get profileLoading;

  /// Settings screen, shown if the profile fetch fails.
  ///
  /// In sr, this message translates to:
  /// **'Nije moguće učitati profil'**
  String get profileLoadError;

  /// Settings screen, fallback when there is no display name yet.
  ///
  /// In sr, this message translates to:
  /// **'Nema profila'**
  String get profileNone;

  /// Settings screen, the row that opens the household screen.
  ///
  /// In sr, this message translates to:
  /// **'Domaćinstvo'**
  String get householdMenuItem;

  /// Settings screen, the sign-out row.
  ///
  /// In sr, this message translates to:
  /// **'Odjavi se'**
  String get signOut;

  /// Settings screen, heading above the language toggle.
  ///
  /// In sr, this message translates to:
  /// **'Jezik'**
  String get languageSectionTitle;

  /// Sign-in screen subtitle. The screen is Google-only.
  ///
  /// In sr, this message translates to:
  /// **'Prijavite se svojim Google nalogom.'**
  String get signInSubtitle;

  /// Sign-in screen, the Google sign-in button. 'Google' is a brand name and stays untranslated, the same way 'Kitchen Table' does.
  ///
  /// In sr, this message translates to:
  /// **'Prijavi se Google nalogom'**
  String get signInWithGoogle;

  /// Recipe detail screen, AppBar title shown before the recipe has loaded.
  ///
  /// In sr, this message translates to:
  /// **'Recept'**
  String get recipeDetailFallbackTitle;

  /// Recipe detail screen, shown above the error when the fetch fails.
  ///
  /// In sr, this message translates to:
  /// **'Nije moguće učitati ovaj recept.'**
  String get couldNotLoadRecipe;

  /// Recipe detail screen, the Edit icon button's tooltip.
  ///
  /// In sr, this message translates to:
  /// **'Izmeni'**
  String get editTooltip;

  /// Recipe detail screen, the overflow menu's delete item.
  ///
  /// In sr, this message translates to:
  /// **'Obriši recept'**
  String get deleteRecipeMenuItem;

  /// Recipe detail screen, the delete-confirmation dialog's title.
  ///
  /// In sr, this message translates to:
  /// **'Obrisati ovaj recept?'**
  String get deleteRecipeDialogTitle;

  /// Recipe detail screen, the delete-confirmation dialog's body.
  ///
  /// In sr, this message translates to:
  /// **'Neće se više pojavljivati u receptima vašeg domaćinstva.'**
  String get deleteRecipeDialogBody;

  /// Recipe detail screen, the delete-confirmation dialog's Cancel button.
  ///
  /// In sr, this message translates to:
  /// **'Otkaži'**
  String get cancelButton;

  /// Recipe detail screen, the delete-confirmation dialog's Delete button.
  ///
  /// In sr, this message translates to:
  /// **'Obriši'**
  String get deleteButton;

  /// Recipe detail screen, the ingredients section heading.
  ///
  /// In sr, this message translates to:
  /// **'Sastojci'**
  String get ingredientsHeading;

  /// Recipe detail screen, the steps section heading.
  ///
  /// In sr, this message translates to:
  /// **'Koraci'**
  String get stepsHeading;

  /// Recipe detail screen, shown when a recipe has no ingredient lines.
  ///
  /// In sr, this message translates to:
  /// **'Još nema sastojaka.'**
  String get noIngredientsYet;

  /// Recipe detail screen, shown when a recipe has no steps.
  ///
  /// In sr, this message translates to:
  /// **'Još nema koraka.'**
  String get noStepsYet;

  /// Recipe detail screen, the chip shown on an untested recipe.
  ///
  /// In sr, this message translates to:
  /// **'Nacrt'**
  String get draftChipLabel;

  /// Recipe detail screen, the chip shown when the title/description/steps on screen came from translate-recipe rather than a human (Phase 3, part 2).
  ///
  /// In sr, this message translates to:
  /// **'Mašinski prevod'**
  String get machineTranslationChipLabel;

  /// Recipe detail screen, the overflow menu's translate item -- {language} is one of languageEnglish/languageSerbian.
  ///
  /// In sr, this message translates to:
  /// **'Prevedi na {language}'**
  String translateAction(String language);

  /// A target language's own name, used inside translateAction -- not the Settings toggle's untranslated 'English' (D77).
  ///
  /// In sr, this message translates to:
  /// **'engleski'**
  String get languageEnglish;

  /// A target language's own name, used inside translateAction -- not the Settings toggle's untranslated 'Srpski' (D77).
  ///
  /// In sr, this message translates to:
  /// **'srpski'**
  String get languageSerbian;

  /// Recipe detail screen, the overflow menu's item that opens the translation review screen (Phase 3, part 3). Shown exactly when translateAction is not -- RecipeDetail.canReview and .canTranslate are mutually exclusive.
  ///
  /// In sr, this message translates to:
  /// **'Pregledaj prevod'**
  String get reviewTranslationMenuItem;

  /// Translation review screen, the AppBar title.
  ///
  /// In sr, this message translates to:
  /// **'Pregled prevoda'**
  String get reviewTranslationTitle;

  /// Translation review screen, the read-only label above the recipe's own text in its own language -- {language} is one of languageEnglish/languageSerbian.
  ///
  /// In sr, this message translates to:
  /// **'Original ({language})'**
  String originalTextLabel(String language);

  /// Translation review screen, the editable title field's label.
  ///
  /// In sr, this message translates to:
  /// **'Naslov'**
  String get titleLabel;

  /// Translation review screen, the editable description field's label.
  ///
  /// In sr, this message translates to:
  /// **'Opis'**
  String get descriptionLabel;

  /// Translation review screen, the editable label above each translated step -- {number} is 1-based, the source step's own position.
  ///
  /// In sr, this message translates to:
  /// **'Korak {number}'**
  String stepLabel(int number);

  /// Translation review screen, validator error when the title field is blank -- mirrors review_recipe_translation's own guard.
  ///
  /// In sr, this message translates to:
  /// **'Unesite naslov.'**
  String get titleRequiredError;

  /// Translation review screen, the save button -- saves the edits AND stamps the review, so the label says both.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj i potvrdi'**
  String get saveReviewButton;

  /// Translation review screen, shown if it is opened (e.g. a stale deep link) with no translation for the reading locale yet.
  ///
  /// In sr, this message translates to:
  /// **'Još nema prevoda za pregled.'**
  String get noTranslationToReview;

  /// Failure vocabulary (D92), FailureCode.offline -- offline, DNS failure, or an Edge Function that was never reached.
  ///
  /// In sr, this message translates to:
  /// **'Nema veze sa internetom.'**
  String get failureOffline;

  /// Failure vocabulary (D92), FailureCode.serverTooSlow -- a request timed out.
  ///
  /// In sr, this message translates to:
  /// **'Server je previše sporo odgovorio.'**
  String get failureServerTooSlow;

  /// Failure vocabulary (D92), FailureCode.offlineNoSavedRecipes -- a cold recipe cache with no network to fill it.
  ///
  /// In sr, this message translates to:
  /// **'Nema veze, a na telefonu još nema sačuvanih recepata.'**
  String get failureOfflineNoSavedRecipes;

  /// Failure vocabulary (D92), FailureCode.offlineNoSavedPlan -- a cold meal-plan cache with no network to fill it.
  ///
  /// In sr, this message translates to:
  /// **'Nema veze, a na telefonu još nema sačuvanog plana.'**
  String get failureOfflineNoSavedPlan;

  /// Failure vocabulary (D92), FailureCode.offlineNoSavedList -- a cold shopping-list cache with no network to fill it.
  ///
  /// In sr, this message translates to:
  /// **'Nema veze, a na telefonu još nema sačuvane liste.'**
  String get failureOfflineNoSavedList;

  /// Failure vocabulary (D92), FailureCode.signInAgain -- an expired session, an RLS denial, or the unauthenticated/not_a_member Edge Function slugs.
  ///
  /// In sr, this message translates to:
  /// **'Prijavite se ponovo.'**
  String get failureSignInAgain;

  /// Failure vocabulary (D92), FailureCode.noHousehold -- the caller has no household yet.
  ///
  /// In sr, this message translates to:
  /// **'Još niste u domaćinstvu.'**
  String get failureNoHousehold;

  /// Failure vocabulary (D92), FailureCode.tooManyAttempts -- GoTrue's rate limit on sign-in attempts.
  ///
  /// In sr, this message translates to:
  /// **'Previše pokušaja. Sačekajte minut i pokušajte ponovo.'**
  String get failureTooManyAttempts;

  /// Failure vocabulary (D92), FailureCode.googleSignInFailed -- every GoogleSignInException code except canceled, which returns null instead of throwing.
  ///
  /// In sr, this message translates to:
  /// **'Prijava Google nalogom nije uspela. Pokušajte ponovo.'**
  String get failureGoogleSignInFailed;

  /// Failure vocabulary (D92), FailureCode.notFound -- the generic row-absent-or-invisible case.
  ///
  /// In sr, this message translates to:
  /// **'Nije pronađeno.'**
  String get failureNotFound;

  /// Failure vocabulary (D92), FailureCode.recipeNotFound -- the recipe_not_found Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'Taj recept nije dostupan.'**
  String get failureRecipeNotFound;

  /// Failure vocabulary (D92), FailureCode.inviteNotFound -- the invite_not_found Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'Taj kod nije važeći.'**
  String get failureInviteNotFound;

  /// Failure vocabulary (D92), FailureCode.inviteAlreadyUsed -- the invite_already_used and already_in_household Edge Function slugs.
  ///
  /// In sr, this message translates to:
  /// **'Taj kod je već iskorišćen.'**
  String get failureInviteAlreadyUsed;

  /// Failure vocabulary (D92), FailureCode.inviteExpired -- the invite_expired Edge Function slug, split from the generic codeNotAccepted.
  ///
  /// In sr, this message translates to:
  /// **'Taj kod je istekao.'**
  String get failureInviteExpired;

  /// Failure vocabulary (D92), FailureCode.codeNotAccepted -- invalid_code/invalid_body/method_not_allowed.
  ///
  /// In sr, this message translates to:
  /// **'Taj kod nije prihvaćen.'**
  String get failureCodeNotAccepted;

  /// Failure vocabulary (D92), FailureCode.alreadyExists -- a unique-violation conflict.
  ///
  /// In sr, this message translates to:
  /// **'To već postoji.'**
  String get failureAlreadyExists;

  /// Failure vocabulary (D92), FailureCode.aiAllowanceUsedUp -- the quota_exceeded Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'Ovo domaćinstvo je potrošilo mesečnu AI kvotu.'**
  String get failureAiAllowanceUsedUp;

  /// Failure vocabulary (D92), FailureCode.unavailableTryLater -- quota_unavailable/ai_rate_limited/ai_unavailable, "not now" rather than "not ever" (D17).
  ///
  /// In sr, this message translates to:
  /// **'To trenutno nije dostupno. Pokušajte kasnije.'**
  String get failureUnavailableTryLater;

  /// Failure vocabulary (D92), FailureCode.importPhotoFailed -- invalid_storage_path/image_not_found/not_an_image.
  ///
  /// In sr, this message translates to:
  /// **'Tu fotografiju nije moguće uvesti.'**
  String get failureImportPhotoFailed;

  /// Failure vocabulary (D92), FailureCode.invalidUrl -- the invalid_url Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'To ne izgleda kao link.'**
  String get failureInvalidUrl;

  /// Failure vocabulary (D92), FailureCode.importTextTooLong -- the input_too_large Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'Taj tekst je previše dugačak za uvoz.'**
  String get failureImportTextTooLong;

  /// Failure vocabulary (D92), FailureCode.importUnreadable -- the degenerate (no server message) arm of empty_input, and import_confirm.dart's own throw for an unreadable job.
  ///
  /// In sr, this message translates to:
  /// **'Taj tekst nije moguće uvesti.'**
  String get failureImportUnreadable;

  /// Failure vocabulary (D92), FailureCode.couldNotReadRecipe -- the degenerate (no server message) arm of ai_failed.
  ///
  /// In sr, this message translates to:
  /// **'Nije moguće očitati taj recept.'**
  String get failureCouldNotReadRecipe;

  /// Failure vocabulary (D92), FailureCode.alreadyInThatLanguage -- the same_locale Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'Ovaj recept je već napisan na tom jeziku.'**
  String get failureAlreadyInThatLanguage;

  /// Failure vocabulary (D92), FailureCode.siteUnreachable -- the fetch_failed Edge Function slug (D45's SSRF-guarded fetch could not reach the host).
  ///
  /// In sr, this message translates to:
  /// **'Ta stranica nije dostupna.'**
  String get failureSiteUnreachable;

  /// Failure vocabulary (D92), FailureCode.notAWebPage -- the not_html Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'Taj link nije veb stranica.'**
  String get failureNotAWebPage;

  /// Failure vocabulary (D92), FailureCode.importTooLarge -- page_too_large (import-url) and image_too_large (import-photo), one sentence for both.
  ///
  /// In sr, this message translates to:
  /// **'To je previše veliko za uvoz.'**
  String get failureImportTooLarge;

  /// Failure vocabulary (D92), FailureCode.importNotFound -- the job_not_found Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'Taj uvoz nije pronađen.'**
  String get failureImportNotFound;

  /// Failure vocabulary (D92), FailureCode.importAlreadySaved -- the job_already_done Edge Function slug (D44's retry guard).
  ///
  /// In sr, this message translates to:
  /// **'Ovaj uvoz je već sačuvan.'**
  String get failureImportAlreadySaved;

  /// Failure vocabulary (D92), FailureCode.importNotReadyYet -- the job_not_parsed Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'Ovaj uvoz još nije spreman.'**
  String get failureImportNotReadyYet;

  /// Failure vocabulary (D92), FailureCode.noRecipeOnPage -- the no_recipe_found Edge Function slug.
  ///
  /// In sr, this message translates to:
  /// **'Na toj stranici nije pronađen recept.'**
  String get failureNoRecipeOnPage;

  /// Failure vocabulary (D92), FailureCode.couldNotMakeCode -- the code_generation_failed Edge Function slug from create-invite.
  ///
  /// In sr, this message translates to:
  /// **'Nije moguće napraviti kod.'**
  String get failureCouldNotMakeCode;

  /// Failure vocabulary (D92), FailureCode.unexpectedServerReply -- a decoder found a shape it did not expect.
  ///
  /// In sr, this message translates to:
  /// **'Server je poslao neočekivan odgovor.'**
  String get failureUnexpectedServerReply;

  /// Failure vocabulary (D92), FailureCode.unknown -- also what a non-AppFailure error renders as, never that error's own toString().
  ///
  /// In sr, this message translates to:
  /// **'Nešto je pošlo naopako.'**
  String get failureUnknown;

  /// Failure vocabulary (D92) -- image_picker's own PlatformException, outside the FailureCode mechanism since it never becomes an AppFailure.
  ///
  /// In sr, this message translates to:
  /// **'Tu fotografiju nije moguće otvoriti.'**
  String get photoCouldNotBeOpened;

  /// OfflineBanner, rendered above every tab's body while Reachability.offline (D76).
  ///
  /// In sr, this message translates to:
  /// **'Nema veze -- prikazane su sačuvane kopije. Izmene se neće sačuvati.'**
  String get offlineBannerMessage;

  /// Recipe detail and list screens, the meta line's servings count. This repo's first ICU plural -- Serbian needs one/few/other, which English's plain 's' suffix does not reach.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{{count} porcija} few{{count} porcije} other{{count} porcija}}'**
  String recipeServingsCount(int count);

  /// Recipe detail and list screens, the meta line's prep-time minutes. Plain int, not a plural -- 'min' is a unit abbreviation and does not decline.
  ///
  /// In sr, this message translates to:
  /// **'{minutes} min priprema'**
  String recipePrepMinutes(int minutes);

  /// Recipe detail and list screens, the meta line's cook-time minutes.
  ///
  /// In sr, this message translates to:
  /// **'{minutes} min kuvanja'**
  String recipeCookMinutes(int minutes);

  /// Recipe detail screen, shown after an ingredient line when it is marked optional and has no note of its own.
  ///
  /// In sr, this message translates to:
  /// **'opciono'**
  String get ingredientOptionalTrailer;

  /// Recipe detail screen, the icon tooltip on an ingredient line the catalog did not match.
  ///
  /// In sr, this message translates to:
  /// **'Nije povezano sa sastojkom'**
  String get ingredientNotMatchedTooltip;

  /// Meal plan screen (part 6), the repeat-warning dialog's count of snack slots already holding this recipe. Added here alongside the other plurals so the vocabulary is complete before that screen's own part localizes the sentence around it.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{{count} obroku} few{{count} obroka} other{{count} obroka}}'**
  String snackSlotCount(int count);

  /// Import review screen (part 5), the summary card's count of matched ingredient lines. Added here for the same reason as snackSlotCount.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{{count} sastojak} few{{count} sastojka} other{{count} sastojaka}}'**
  String ingredientsMatchedCount(int count);

  /// Recipe list screen, the FAB's tooltip.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj recept'**
  String get addRecipeTooltip;

  /// Recipe list screen, the FAB menu's manual-entry item.
  ///
  /// In sr, this message translates to:
  /// **'Novi recept'**
  String get newRecipeMenuItem;

  /// Recipe list screen, the FAB menu's import-from-URL item.
  ///
  /// In sr, this message translates to:
  /// **'Uvezi sa linka'**
  String get importFromLinkMenuItem;

  /// Recipe list screen, the FAB menu's paste-text item.
  ///
  /// In sr, this message translates to:
  /// **'Nalepi recept'**
  String get pasteRecipeMenuItem;

  /// Recipe list screen, the FAB menu's photo-import item.
  ///
  /// In sr, this message translates to:
  /// **'Fotografiši stranicu'**
  String get photographPageMenuItem;

  /// Recipe list screen's search field, and the recipe picker sheet's own (core/recipes/widgets/recipe_picker_sheet.dart) -- one key, since both search the same recipes by the same concept.
  ///
  /// In sr, this message translates to:
  /// **'Pretraži recepte'**
  String get searchRecipesHint;

  /// Recipe list screen, the empty state while a search query matches nothing.
  ///
  /// In sr, this message translates to:
  /// **'Nema recepata koji se poklapaju.'**
  String get noRecipesMatch;

  /// Recipe list screen, the empty state with no search in progress.
  ///
  /// In sr, this message translates to:
  /// **'Još nema recepata.\n\nDodajte jedan koji znate napamet.'**
  String get noRecipesYet;

  /// Recipe edit screen, the AppBar title for a recipe that does not exist yet.
  ///
  /// In sr, this message translates to:
  /// **'Novi recept'**
  String get newRecipeTitle;

  /// Recipe edit screen, the AppBar title for an existing recipe.
  ///
  /// In sr, this message translates to:
  /// **'Izmena recepta'**
  String get editRecipeTitle;

  /// Recipe edit screen, the servings number field's label -- distinct from recipeServingsCount, which is the read-only display elsewhere.
  ///
  /// In sr, this message translates to:
  /// **'Porcije'**
  String get servingsFieldLabel;

  /// Recipe edit screen, the prep-time number field's label.
  ///
  /// In sr, this message translates to:
  /// **'Priprema (min)'**
  String get prepMinutesFieldLabel;

  /// Recipe edit screen, the cook-time number field's label.
  ///
  /// In sr, this message translates to:
  /// **'Kuvanje (min)'**
  String get cookMinutesFieldLabel;

  /// Recipe edit screen, the label above the Srpski/English segmented button -- the language names themselves stay untranslated (D77).
  ///
  /// In sr, this message translates to:
  /// **'Napisano na'**
  String get writtenInFieldLabel;

  /// Recipe edit screen, the label above the Draft/Tested segmented button.
  ///
  /// In sr, this message translates to:
  /// **'Status'**
  String get statusFieldLabel;

  /// Recipe edit screen, the status segmented button's tested option -- draftChipLabel is its Draft counterpart, shared with the chip elsewhere since both name the same status.
  ///
  /// In sr, this message translates to:
  /// **'Isprobano'**
  String get testedStatusLabel;

  /// Recipe edit screen, the tags field's label.
  ///
  /// In sr, this message translates to:
  /// **'Oznake'**
  String get tagsFieldLabel;

  /// Recipe edit screen, the tags field's helper text.
  ///
  /// In sr, this message translates to:
  /// **'Odvojene zarezima'**
  String get tagsHelperText;

  /// Recipe edit and import review screens, the button that appends a blank ingredient line.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj sastojak'**
  String get addIngredientButton;

  /// Recipe edit and import review screens, the button that appends a blank step.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj korak'**
  String get addStepButton;

  /// Recipe edit screen, the save button -- distinct from saveReviewButton, which also stamps a review.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj'**
  String get saveButton;

  /// Recipe edit screen, the photo field's camera button.
  ///
  /// In sr, this message translates to:
  /// **'Kamera'**
  String get cameraButton;

  /// Recipe edit screen, the photo field's gallery-picker button.
  ///
  /// In sr, this message translates to:
  /// **'Galerija'**
  String get galleryButton;

  /// Recipe edit screen, the photo field's remove-photo icon button.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni fotografiju'**
  String get removePhotoTooltip;

  /// Recipe edit and import review screens, the tooltip on the icon that removes one ingredient or step row.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni'**
  String get removeTooltip;

  /// Recipe edit screen, the servings/prep/cook number fields' validator error when the value does not parse as an integer.
  ///
  /// In sr, this message translates to:
  /// **'Ceo broj.'**
  String get wholeNumberError;

  /// Recipe edit screen, the servings/prep/cook number fields' validator error when the value is below the column's minimum.
  ///
  /// In sr, this message translates to:
  /// **'Najmanje {minimum}.'**
  String atLeastError(int minimum);

  /// Ingredient line field, an example of what to type. Looked up by the RECIPE's own language (widget.locale via lookupAppLocalizations), never the reader's chrome locale -- an English reader typing an English recipe should not be shown a Serbian example (D86's own reasoning, one screen over).
  ///
  /// In sr, this message translates to:
  /// **'2 šolje glatkog brašna'**
  String get ingredientLineHint;

  /// Ingredient match chip, shown when the search found nothing. Looked up by the recipe's own language, on ingredientLineHint's own precedent -- this chip sits beside catalog names that are never in the reader's chrome locale either.
  ///
  /// In sr, this message translates to:
  /// **'Nema poklapanja'**
  String get ingredientNoMatchLabel;

  /// Ingredient match chip, offering a candidate that did not clear the auto-accept bar -- tapping opens the picker. Same locale rule as ingredientNoMatchLabel.
  ///
  /// In sr, this message translates to:
  /// **'{name}?'**
  String ingredientSuggestionLabel(String name);

  /// Ingredient picker sheet, the title asking which catalog entry a typed word means. Locale rule: the recipe's own language (widget.locale), same as ingredientNoMatchLabel -- this sheet is opened from the match chip.
  ///
  /// In sr, this message translates to:
  /// **'Koji sastojak je „{query}”?'**
  String ingredientPickerQuestion(String query);

  /// Ingredient picker sheet, shown when the search returns nothing.
  ///
  /// In sr, this message translates to:
  /// **'Ništa u katalogu se ne poklapa.'**
  String get ingredientPickerNoMatches;

  /// Ingredient picker sheet, the always-last row that creates a new catalog ingredient from the typed word.
  ///
  /// In sr, this message translates to:
  /// **'Napravi „{query}”'**
  String ingredientPickerCreateNew(String query);

  /// Ingredient picker sheet, the create-new row's subtitle.
  ///
  /// In sr, this message translates to:
  /// **'Dodaje ga u katalog domaćinstva'**
  String get ingredientPickerCreateNewSubtitle;

  /// Ingredient picker sheet, a candidate row's subtitle when it matched through a different name than the one displayed -- an alias or an inflected form.
  ///
  /// In sr, this message translates to:
  /// **'poklopio „{name}”'**
  String ingredientPickerMatchedByAlias(String name);

  /// Ingredient picker sheet, a candidate row's tooltip when it came from a household's own entry rather than the curated catalog.
  ///
  /// In sr, this message translates to:
  /// **'Dodao je neko drugi, nije sa zvaničnog spiska'**
  String get ingredientPickerUnverifiedTooltip;

  /// Recipe picker sheet (core/recipes/widgets), the row offering a free-text note instead of a recipe.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj napomenu umesto recepta'**
  String get addNoteInsteadMenuItem;

  /// Recipe picker sheet, the add-note row's subtitle giving examples.
  ///
  /// In sr, this message translates to:
  /// **'„ostaci”, „jedemo napolju” -- bez recepta'**
  String get addNoteInsteadSubtitle;

  /// Recipe picker sheet, the note-entry dialog's title.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj napomenu'**
  String get addNoteDialogTitle;

  /// Recipe picker sheet, the note-entry dialog's text field hint.
  ///
  /// In sr, this message translates to:
  /// **'npr. ostaci'**
  String get addNoteHint;

  /// Recipe picker sheet, the note-entry dialog's confirm button -- a bare 'Add', distinct from addIngredientButton/addStepButton which name what they add.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj'**
  String get addButton;

  /// Create-household screen (onboarding), the headline.
  ///
  /// In sr, this message translates to:
  /// **'Imenujte svoje domaćinstvo'**
  String get createHouseholdTitle;

  /// Create-household screen, the subtitle under the headline.
  ///
  /// In sr, this message translates to:
  /// **'Recepti i planovi obroka se dele sa svima u njemu.'**
  String get createHouseholdSubtitle;

  /// Create-household screen's text field label, and the household screen's own subtitle under the household's name -- same phrase, both places.
  ///
  /// In sr, this message translates to:
  /// **'Naziv domaćinstva'**
  String get householdNameFieldLabel;

  /// Create-household screen, the name field's validator error when left blank.
  ///
  /// In sr, this message translates to:
  /// **'Unesite naziv.'**
  String get householdNameEmptyError;

  /// Create-household screen, the submit button.
  ///
  /// In sr, this message translates to:
  /// **'Napravi'**
  String get createHouseholdButton;

  /// Create-household screen, the link to the join-by-code screen instead.
  ///
  /// In sr, this message translates to:
  /// **'Imam pozivni kod'**
  String get haveInviteCodeButton;

  /// Household screen's AppBar title.
  ///
  /// In sr, this message translates to:
  /// **'Domaćinstvo'**
  String get householdScreenTitle;

  /// Household screen, shown if somehow reached with no household resolved yet.
  ///
  /// In sr, this message translates to:
  /// **'Još nema domaćinstva.'**
  String get noHouseholdYet;

  /// Household screen, the members list's section header.
  ///
  /// In sr, this message translates to:
  /// **'Članovi'**
  String get membersSectionTitle;

  /// Household screen, the invites list's section header.
  ///
  /// In sr, this message translates to:
  /// **'Pozovi nekoga'**
  String get inviteSomeoneSectionTitle;

  /// Household screen, the members and invites lists' own loading placeholder -- one word, used in both places rather than a per-list variant.
  ///
  /// In sr, this message translates to:
  /// **'Učitavanje...'**
  String get loadingEllipsis;

  /// Household screen, shown under Invite someone when there are no live invite codes.
  ///
  /// In sr, this message translates to:
  /// **'Nema aktivnih kodova. Napravite jedan i pročitajte ga onome ko se priključuje.'**
  String get noActiveCodesMessage;

  /// Household screen, the icon button that copies an invite code to the clipboard.
  ///
  /// In sr, this message translates to:
  /// **'Kopiraj kod'**
  String get copyCodeTooltip;

  /// Household screen, the create-invite button's own label while the request is in flight.
  ///
  /// In sr, this message translates to:
  /// **'Pravljenje...'**
  String get creatingEllipsis;

  /// Household screen, the button that requests a new invite code.
  ///
  /// In sr, this message translates to:
  /// **'Napravi pozivni kod'**
  String get createInviteCodeButton;

  /// Household screen, the SnackBar shown after copying an invite code.
  ///
  /// In sr, this message translates to:
  /// **'Kod kopiran.'**
  String get codeCopiedSnackbar;

  /// Household screen, an invite code's expiry line when under an hour remains.
  ///
  /// In sr, this message translates to:
  /// **'Ističe za manje od sat vremena'**
  String get inviteExpiresWithinHour;

  /// Household screen, an invite code's expiry line when between one hour and one day remains.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{Ističe za {count} sat} few{Ističe za {count} sata} other{Ističe za {count} sati}}'**
  String inviteExpiresInHours(int count);

  /// Household screen, an invite code's expiry line when a day or more remains.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{Ističe za {count} dan} few{Ističe za {count} dana} other{Ističe za {count} dana}}'**
  String inviteExpiresInDays(int count);

  /// Household screen, a member row's subtitle for HouseholdRole.owner.
  ///
  /// In sr, this message translates to:
  /// **'Vlasnik'**
  String get householdRoleOwner;

  /// Household screen, a member row's subtitle for HouseholdRole.adult -- previously rendered as the raw enum name ('owner'/'adult') in both languages.
  ///
  /// In sr, this message translates to:
  /// **'Član'**
  String get householdRoleAdult;

  /// Household screen, a member row's title when the co-member profile policy withheld the display name.
  ///
  /// In sr, this message translates to:
  /// **'Nepoznato'**
  String get unknownDisplayName;

  /// Join-household screen (onboarding), the headline.
  ///
  /// In sr, this message translates to:
  /// **'Unesite svoj pozivni kod'**
  String get joinHouseholdTitle;

  /// Join-household screen, the subtitle under the headline.
  ///
  /// In sr, this message translates to:
  /// **'Zamolite nekoga iz domaćinstva da vam napravi kod.'**
  String get joinHouseholdSubtitle;

  /// Join-household screen, the submit button.
  ///
  /// In sr, this message translates to:
  /// **'Priključi se'**
  String get joinButton;

  /// Join-household screen, the link back to create-household instead.
  ///
  /// In sr, this message translates to:
  /// **'Napravi domaćinstvo umesto toga'**
  String get createHouseholdInsteadButton;

  /// Import-by-paste screen's AppBar title.
  ///
  /// In sr, this message translates to:
  /// **'Nalepi recept'**
  String get importPasteTitle;

  /// Import-by-paste screen, the instruction line above the text field.
  ///
  /// In sr, this message translates to:
  /// **'Nalepite ceo tekst -- sastojke, postupak, šta god je stiglo uz recept. Nije problem ako ima i dodatnog teksta oko recepta.'**
  String get importPasteBody;

  /// Import-by-paste screen, the paste field's sample hint. Looked up by the READER's chrome locale, not a recipe's -- there is no recipe yet at this point, unlike ingredientLineHint's rule.
  ///
  /// In sr, this message translates to:
  /// **'Šargarepa torta\n\n200 g šargarepe\n2 šolje brašna…'**
  String get importPasteHint;

  /// Import-by-paste screen, the source-attribution field's label.
  ///
  /// In sr, this message translates to:
  /// **'Odakle je (opcionalno)'**
  String get importSourceFieldLabel;

  /// Import-by-paste screen, the source-attribution field's helper text.
  ///
  /// In sr, this message translates to:
  /// **'Čuva se i prikazuje uz recept.'**
  String get importSourceHelperText;

  /// The submit button shared by all three import entry screens (paste, photo, link).
  ///
  /// In sr, this message translates to:
  /// **'Pročitaj ovaj recept'**
  String get readRecipeButton;

  /// Import-by-photo screen's AppBar title.
  ///
  /// In sr, this message translates to:
  /// **'Fotografiši stranicu'**
  String get importPhotoTitle;

  /// Import-by-photo screen, the instruction line above the camera/gallery buttons.
  ///
  /// In sr, this message translates to:
  /// **'Uklopite recept u kadar. U redu je i cela stranica -- dve kolone, spisak sastojaka postrani, fotografija jela. Sve što je navedeno kao izvor se čuva uz recept.'**
  String get importPhotoBody;

  /// Import-by-photo screen, the camera-source button.
  ///
  /// In sr, this message translates to:
  /// **'Fotografiši'**
  String get takePhotoButton;

  /// Import-by-photo screen, the gallery-source button.
  ///
  /// In sr, this message translates to:
  /// **'Izaberi fotografiju'**
  String get choosePhotoButton;

  /// Import-by-link screen's AppBar title.
  ///
  /// In sr, this message translates to:
  /// **'Uvezi sa linka'**
  String get importUrlTitle;

  /// Import-by-link screen, the instruction line above the URL field.
  ///
  /// In sr, this message translates to:
  /// **'Nalepite adresu stranice sa receptom. Šta god stranica navede kao izvor se čuva uz recept.'**
  String get importUrlBody;

  /// Import-by-link screen, the URL field's label.
  ///
  /// In sr, this message translates to:
  /// **'Link'**
  String get linkFieldLabel;

  /// Import review screen's AppBar title.
  ///
  /// In sr, this message translates to:
  /// **'Pregled uvoza'**
  String get reviewImportTitle;

  /// Import review screen, the waiting state's status line while the job is processing.
  ///
  /// In sr, this message translates to:
  /// **'Čitanje recepta...'**
  String get readingRecipeEllipsis;

  /// Import review screen, the waiting state's status line while the job is still queued.
  ///
  /// In sr, this message translates to:
  /// **'U redu čekanja...'**
  String get queuedEllipsis;

  /// Import review screen, the waiting state's reassurance line.
  ///
  /// In sr, this message translates to:
  /// **'Ovo traje nekoliko sekundi. Možete izaći i vratiti se.'**
  String get importWaitingHint;

  /// Import review screen, the failed state's dismiss button.
  ///
  /// In sr, this message translates to:
  /// **'Odbaci ovaj uvoz'**
  String get discardImportButton;

  /// Import review screen, the already-saved state's button to the saved recipe.
  ///
  /// In sr, this message translates to:
  /// **'Otvori recept'**
  String get openRecipeButton;

  /// Import review screen, the steps section's heading (recipe_edit_screen's own steps section has no heading of its own to share).
  ///
  /// In sr, this message translates to:
  /// **'Postupak'**
  String get methodHeading;

  /// Import review screen, the save bar's submit button -- distinct from the generic saveButton ('Save') used elsewhere.
  ///
  /// In sr, this message translates to:
  /// **'Sačuvaj recept'**
  String get saveRecipeButton;

  /// Import review screen, the summary card's first line. {totalPhrase} is ingredientsMatchedCount(total), composed rather than duplicating its plural rule.
  ///
  /// In sr, this message translates to:
  /// **'Poklopljeno {matched} od {totalPhrase}'**
  String importMatchedOfTotal(int matched, String totalPhrase);

  /// Import review screen, the summary card's second line -- shown only when at least one line needs a look.
  ///
  /// In sr, this message translates to:
  /// **'{attention} vredno pažnje pre čuvanja'**
  String importWorthALook(int attention);

  /// Meal plan screen (part 6), the AppBar's jump-to-today icon tooltip.
  ///
  /// In sr, this message translates to:
  /// **'Ova nedelja'**
  String get thisWeekTooltip;

  /// Meal plan screen (part 6), the week bar's back-arrow tooltip.
  ///
  /// In sr, this message translates to:
  /// **'Prethodna nedelja'**
  String get previousWeekTooltip;

  /// Meal plan screen (part 6), the week bar's forward-arrow tooltip.
  ///
  /// In sr, this message translates to:
  /// **'Sledeća nedelja'**
  String get nextWeekTooltip;

  /// Meal plan and shopping list screens (part 6), the line under the AppBar shown only while offline and only over cached data -- byte-identical in both screens, one key. Narrower than offlineBannerMessage (D76): this is a provenance claim about the data on screen, not the session-wide connectivity fact.
  ///
  /// In sr, this message translates to:
  /// **'Prikazana je sačuvana kopija — nema veze.'**
  String get savedCopyOfflineMessage;

  /// Meal plan screen (part 6), a slot row's label and the day/move/leftover dialogs' slot dropdown -- one definition, MealSlot.breakfast.
  ///
  /// In sr, this message translates to:
  /// **'Doručak'**
  String get mealSlotBreakfast;

  /// Meal plan screen (part 6), MealSlot.lunch -- see mealSlotBreakfast.
  ///
  /// In sr, this message translates to:
  /// **'Ručak'**
  String get mealSlotLunch;

  /// Meal plan screen (part 6), MealSlot.dinner -- see mealSlotBreakfast.
  ///
  /// In sr, this message translates to:
  /// **'Večera'**
  String get mealSlotDinner;

  /// Meal plan screen (part 6), MealSlot.snack -- see mealSlotBreakfast.
  ///
  /// In sr, this message translates to:
  /// **'Užina'**
  String get mealSlotSnack;

  /// Meal plan screen (part 6), the snack-repeat confirmation dialog's title (D58 -- advisory, never blocking).
  ///
  /// In sr, this message translates to:
  /// **'Već nedavno planirano'**
  String get snackRepeatWarningTitle;

  /// Meal plan screen (part 6), the snack-repeat dialog's body. {countPhrase} is snackSlotCount(repeatCount), composed rather than duplicating its plural rule, on importMatchedOfTotal's own precedent.
  ///
  /// In sr, this message translates to:
  /// **'Već je u {countPhrase} u ovih 14 dana.'**
  String snackRepeatWarningBody(String countPhrase);

  /// Meal plan screen (part 6), the snack-repeat dialog's proceed-anyway button.
  ///
  /// In sr, this message translates to:
  /// **'Ipak dodaj'**
  String get addAnywayButton;

  /// Meal plan screen (part 6), the entry action sheet's open-recipe item -- distinct from openRecipeButton, which is the import review screen's already-saved state.
  ///
  /// In sr, this message translates to:
  /// **'Otvori recept'**
  String get openRecipeMenuItem;

  /// Meal plan screen (part 6), the entry action sheet's servings item.
  ///
  /// In sr, this message translates to:
  /// **'Kuvamo za...'**
  String get cookingForMenuItem;

  /// Meal plan screen (part 6), the servings dialog's default option and the action sheet's subtitle when no override is set.
  ///
  /// In sr, this message translates to:
  /// **'Kako piše u receptu'**
  String get asTheRecipeSaysLabel;

  /// Meal plan screen (part 6), the servings dialog's default option when the recipe's own servings count is known.
  ///
  /// In sr, this message translates to:
  /// **'Kako piše u receptu ({count})'**
  String asTheRecipeSaysWithCount(int count);

  /// Meal plan screen (part 6), the entry action sheet's item, shown only for a recipe entry (D55).
  ///
  /// In sr, this message translates to:
  /// **'Isplaniraj ostatke...'**
  String get planLeftoversMenuItem;

  /// Meal plan screen (part 6), the entry action sheet's item opening the move dialog.
  ///
  /// In sr, this message translates to:
  /// **'Premesti u...'**
  String get moveToMenuItem;

  /// Meal plan screen (part 6), the entry action sheet's reorder item, shown only when not already first.
  ///
  /// In sr, this message translates to:
  /// **'Pomeri gore'**
  String get moveUpMenuItem;

  /// Meal plan screen (part 6), the entry action sheet's reorder item, shown only when not already last.
  ///
  /// In sr, this message translates to:
  /// **'Pomeri dole'**
  String get moveDownMenuItem;

  /// Meal plan screen (part 6), the servings dialog's title.
  ///
  /// In sr, this message translates to:
  /// **'Kuvamo za'**
  String get cookingForDialogTitle;

  /// Meal plan screen (part 6), the servings dialog's explanation when the recipe has no servings count of its own.
  ///
  /// In sr, this message translates to:
  /// **'Ovaj recept ne kaže za koliko porcija je, pa lista za kupovinu ne može da ga preračuna.'**
  String get servingsUnknownExplanation;

  /// Meal plan screen (part 6), the servings dialog's explanation when the recipe does have a servings count.
  ///
  /// In sr, this message translates to:
  /// **'Lista za kupovinu preračunava sastojke ovog obroka prema tome.'**
  String get servingsScalesExplanation;

  /// Meal plan screen (part 6), the move dialog's title -- distinct from moveToMenuItem, which has a trailing ellipsis.
  ///
  /// In sr, this message translates to:
  /// **'Premesti u'**
  String get moveToDialogTitle;

  /// Meal plan screen (part 6), the move and leftover dialogs' day dropdown label.
  ///
  /// In sr, this message translates to:
  /// **'Dan'**
  String get dayFieldLabel;

  /// Meal plan screen (part 6), the move and leftover dialogs' slot dropdown label.
  ///
  /// In sr, this message translates to:
  /// **'Obrok'**
  String get slotFieldLabel;

  /// Meal plan screen (part 6), the move dialog's confirm button.
  ///
  /// In sr, this message translates to:
  /// **'Premesti'**
  String get moveButton;

  /// Meal plan screen (part 6), the leftover dialog's title -- distinct from planLeftoversMenuItem, which has a trailing ellipsis.
  ///
  /// In sr, this message translates to:
  /// **'Isplaniraj ostatke'**
  String get planLeftoversDialogTitle;

  /// Meal plan screen (part 6), a leftover entry's chip label -- MealPlanEntry can no longer compose this itself (a domain model cannot know a sentence, D92), so this is presentation-side, on failure_l10n.dart's own precedent.
  ///
  /// In sr, this message translates to:
  /// **'Ostaci: {title}'**
  String leftoverEntryLabel(String title);

  /// Shopping list screen (part 6), the AppBar's regenerate icon tooltip -- shown only once a list exists.
  ///
  /// In sr, this message translates to:
  /// **'Osveži'**
  String get regenerateTooltip;

  /// Shopping list screen (part 6), the range bar's date-range-picker icon tooltip.
  ///
  /// In sr, this message translates to:
  /// **'Izaberi datume'**
  String get pickDatesTooltip;

  /// Shopping list screen (part 6), the range bar's this-week shortcut -- distinct from thisWeekTooltip, a different widget on a different screen.
  ///
  /// In sr, this message translates to:
  /// **'Ova nedelja'**
  String get thisWeekButton;

  /// Shopping list screen (part 6), the range bar's next-week shortcut.
  ///
  /// In sr, this message translates to:
  /// **'Sledeća'**
  String get nextWeekButton;

  /// Shopping list screen (part 6), the empty state's title.
  ///
  /// In sr, this message translates to:
  /// **'Još nema liste.'**
  String get noListYetTitle;

  /// Shopping list screen (part 6), the empty state's body.
  ///
  /// In sr, this message translates to:
  /// **'Napravite je na osnovu onoga što ste isplanirali za ove datume.'**
  String get noListYetBody;

  /// Shopping list screen (part 6), the empty state's generate button.
  ///
  /// In sr, this message translates to:
  /// **'Napravi listu'**
  String get generateListButton;

  /// Shopping list screen (part 6), shown inside the list body when a generated list has no items at all. Renders in list.locale (the two-locale rule) -- this describes the snapshot's own content, not the reader's chrome.
  ///
  /// In sr, this message translates to:
  /// **'Nema ničega za kupovinu -- ništa nije planirano za ove datume.'**
  String get nothingToBuyMessage;

  /// Shopping list screen (part 6), the collapsed pantry-staples section's title. Renders in list.locale, on the two-locale rule -- this heading is part of the document, not the chrome.
  ///
  /// In sr, this message translates to:
  /// **'Verovatno imate ({count})'**
  String probablyHaveHeading(int count);

  /// Shopping list screen (part 6), the collapsed pantry-staples section's subtitle. Renders in list.locale, same as probablyHaveHeading.
  ///
  /// In sr, this message translates to:
  /// **'Namirnice iz ostave'**
  String get cupboardStaplesSubtitle;

  /// Shopping list screen (part 6), the snapshot's own provenance line. {generatedDate}/{from}/{to} are shortDateLabel(..., list.locale) results, composed rather than duplicated -- this whole line renders in list.locale (the two-locale rule), unlike the offline line beneath it (savedCopyOfflineMessage), which is the reader's own connectivity fact.
  ///
  /// In sr, this message translates to:
  /// **'Generisano {generatedDate} za {from} – {to}'**
  String generatedForRangeLine(String generatedDate, String from, String to);

  /// Shopping list screen (part 6), the ingredients.category code 'produce' as a section heading. Renders in list.locale -- see categoryOther for the uncategorised bucket and the fallback rule for an unrecognised code.
  ///
  /// In sr, this message translates to:
  /// **'Povrće'**
  String get categoryProduce;

  /// Shopping list screen (part 6), the category code 'fruit' -- see categoryProduce.
  ///
  /// In sr, this message translates to:
  /// **'Voće'**
  String get categoryFruit;

  /// Shopping list screen (part 6), the category code 'dairy' -- see categoryProduce.
  ///
  /// In sr, this message translates to:
  /// **'Mlečni proizvodi'**
  String get categoryDairy;

  /// Shopping list screen (part 6), the category code 'meat' -- see categoryProduce.
  ///
  /// In sr, this message translates to:
  /// **'Meso'**
  String get categoryMeat;

  /// Shopping list screen (part 6), the category code 'fish' -- see categoryProduce.
  ///
  /// In sr, this message translates to:
  /// **'Riba'**
  String get categoryFish;

  /// Shopping list screen (part 6), the category code 'pantry' -- see categoryProduce.
  ///
  /// In sr, this message translates to:
  /// **'Ostava'**
  String get categoryPantry;

  /// Shopping list screen (part 6), the category code 'spice' -- see categoryProduce.
  ///
  /// In sr, this message translates to:
  /// **'Začini'**
  String get categorySpice;

  /// Shopping list screen (part 6), the category code 'bakery' -- see categoryProduce.
  ///
  /// In sr, this message translates to:
  /// **'Pekarski proizvodi'**
  String get categoryBakery;

  /// Shopping list screen (part 6), the category code 'beverage' -- see categoryProduce. supabase/seeds/ingredients.csv's category comment wraps onto a second line ('beverage nuts') that the original slice plan's citation missed -- ten codes, not eight.
  ///
  /// In sr, this message translates to:
  /// **'Pića'**
  String get categoryBeverage;

  /// Shopping list screen (part 6), the category code 'nuts' -- see categoryBeverage.
  ///
  /// In sr, this message translates to:
  /// **'Orašasti plodovi'**
  String get categoryNuts;

  /// Shopping list screen (part 6), the uncategorised bucket (a null ingredients.category) -- no longer keyed by the literal string 'Other', which was both a display string and a map key before this part. An unrecognised code (neither this nor any of the ten known categories) falls through to itself rather than landing here.
  ///
  /// In sr, this message translates to:
  /// **'Ostalo'**
  String get categoryOther;

  /// Shopping list screen (part 6), the long-press confirmation when an item is marked always-have. Renders in the reader's locale (chrome) even though {name} itself (item.displayName) is snapshot data -- the same composition shape as leftoverEntryLabel.
  ///
  /// In sr, this message translates to:
  /// **'{name} označeno kao stalna namirnica iz ostave. Važi od sledeće liste.'**
  String markedAsStapleSnackbar(String name);

  /// Shopping list screen (part 6), the long-press confirmation when an item's always-have override is cleared.
  ///
  /// In sr, this message translates to:
  /// **'{name} će od sada biti na listi.'**
  String willBeOnListSnackbar(String name);

  /// Recipe detail screen (Phase 5, part 1), the AppBar star's tooltip when the recipe is not yet a favorite.
  ///
  /// In sr, this message translates to:
  /// **'Dodaj u omiljene'**
  String get addToFavoritesTooltip;

  /// Recipe detail screen (Phase 5, part 1), the AppBar star's tooltip when the recipe is already a favorite.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni iz omiljenih'**
  String get removeFromFavoritesTooltip;

  /// Recipe detail screen (Phase 5, part 1), the tooltip on a rating star that is not the current rating -- tapping it sets the rating to this many stars.
  ///
  /// In sr, this message translates to:
  /// **'{count, plural, one{{count} zvezdica} few{{count} zvezdice} other{{count} zvezdica}}'**
  String ratingStarsTooltip(int count);

  /// Recipe detail screen (Phase 5, part 1), the tooltip on the rating star that already is the current rating -- tapping it again clears the rating back to unrated.
  ///
  /// In sr, this message translates to:
  /// **'Ukloni ocenu'**
  String get clearRatingTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
