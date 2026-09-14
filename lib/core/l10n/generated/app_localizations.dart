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

  /// Sign-in screen subtitle.
  ///
  /// In sr, this message translates to:
  /// **'Prijavite se kodom poslatim na vaš imejl.'**
  String get signInSubtitle;

  /// Sign-in screen, the email field's label.
  ///
  /// In sr, this message translates to:
  /// **'Imejl'**
  String get emailLabel;

  /// Sign-in screen, validator error when the email field is blank.
  ///
  /// In sr, this message translates to:
  /// **'Unesite svoju imejl adresu.'**
  String get emailEmptyError;

  /// Sign-in screen, validator error when the email field is not an address.
  ///
  /// In sr, this message translates to:
  /// **'To ne izgleda kao imejl adresa.'**
  String get emailInvalidError;

  /// Sign-in screen, the submit button.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji kod'**
  String get sendCode;

  /// Verify-OTP screen title.
  ///
  /// In sr, this message translates to:
  /// **'Proverite imejl'**
  String get checkEmailTitle;

  /// Verify-OTP screen subtitle, naming the address the code went to.
  ///
  /// In sr, this message translates to:
  /// **'Poslali smo kod na {email}.'**
  String codeSentTo(String email);

  /// Verify-OTP screen, shown when the code field is submitted blank.
  ///
  /// In sr, this message translates to:
  /// **'Unesite kod iz imejla.'**
  String get codeEmptyError;

  /// Verify-OTP screen, the submit button.
  ///
  /// In sr, this message translates to:
  /// **'Potvrdi'**
  String get verify;

  /// Verify-OTP screen, the resend link.
  ///
  /// In sr, this message translates to:
  /// **'Pošalji novi kod'**
  String get resendCode;

  /// Verify-OTP screen, the SnackBar shown after a successful resend.
  ///
  /// In sr, this message translates to:
  /// **'Novi kod je poslat.'**
  String get newCodeSent;

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

  /// Failure vocabulary (D92), FailureCode.codeNotAccepted -- invalid_code/invalid_body/method_not_allowed, and a verifyOTP call that returned no user.
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
