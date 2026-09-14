// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get navRecipes => 'Recepti';

  @override
  String get navPlan => 'Plan';

  @override
  String get navList => 'Lista';

  @override
  String get navSettings => 'Podešavanja';

  @override
  String get profileLoading => 'Učitavanje...';

  @override
  String get profileLoadError => 'Nije moguće učitati profil';

  @override
  String get profileNone => 'Nema profila';

  @override
  String get householdMenuItem => 'Domaćinstvo';

  @override
  String get signOut => 'Odjavi se';

  @override
  String get languageSectionTitle => 'Jezik';

  @override
  String get signInSubtitle => 'Prijavite se kodom poslatim na vaš imejl.';

  @override
  String get emailLabel => 'Imejl';

  @override
  String get emailEmptyError => 'Unesite svoju imejl adresu.';

  @override
  String get emailInvalidError => 'To ne izgleda kao imejl adresa.';

  @override
  String get sendCode => 'Pošalji kod';

  @override
  String get checkEmailTitle => 'Proverite imejl';

  @override
  String codeSentTo(String email) {
    return 'Poslali smo kod na $email.';
  }

  @override
  String get codeEmptyError => 'Unesite kod iz imejla.';

  @override
  String get verify => 'Potvrdi';

  @override
  String get resendCode => 'Pošalji novi kod';

  @override
  String get newCodeSent => 'Novi kod je poslat.';

  @override
  String get recipeDetailFallbackTitle => 'Recept';

  @override
  String get couldNotLoadRecipe => 'Nije moguće učitati ovaj recept.';

  @override
  String get editTooltip => 'Izmeni';

  @override
  String get deleteRecipeMenuItem => 'Obriši recept';

  @override
  String get deleteRecipeDialogTitle => 'Obrisati ovaj recept?';

  @override
  String get deleteRecipeDialogBody =>
      'Neće se više pojavljivati u receptima vašeg domaćinstva.';

  @override
  String get cancelButton => 'Otkaži';

  @override
  String get deleteButton => 'Obriši';

  @override
  String get ingredientsHeading => 'Sastojci';

  @override
  String get stepsHeading => 'Koraci';

  @override
  String get noIngredientsYet => 'Još nema sastojaka.';

  @override
  String get noStepsYet => 'Još nema koraka.';

  @override
  String get draftChipLabel => 'Nacrt';

  @override
  String get machineTranslationChipLabel => 'Mašinski prevod';

  @override
  String translateAction(String language) {
    return 'Prevedi na $language';
  }

  @override
  String get languageEnglish => 'engleski';

  @override
  String get languageSerbian => 'srpski';

  @override
  String get reviewTranslationMenuItem => 'Pregledaj prevod';

  @override
  String get reviewTranslationTitle => 'Pregled prevoda';

  @override
  String originalTextLabel(String language) {
    return 'Original ($language)';
  }

  @override
  String get titleLabel => 'Naslov';

  @override
  String get descriptionLabel => 'Opis';

  @override
  String stepLabel(int number) {
    return 'Korak $number';
  }

  @override
  String get titleRequiredError => 'Unesite naslov.';

  @override
  String get saveReviewButton => 'Sačuvaj i potvrdi';

  @override
  String get noTranslationToReview => 'Još nema prevoda za pregled.';

  @override
  String get failureOffline => 'Nema veze sa internetom.';

  @override
  String get failureServerTooSlow => 'Server je previše sporo odgovorio.';

  @override
  String get failureOfflineNoSavedRecipes =>
      'Nema veze, a na telefonu još nema sačuvanih recepata.';

  @override
  String get failureOfflineNoSavedPlan =>
      'Nema veze, a na telefonu još nema sačuvanog plana.';

  @override
  String get failureOfflineNoSavedList =>
      'Nema veze, a na telefonu još nema sačuvane liste.';

  @override
  String get failureSignInAgain => 'Prijavite se ponovo.';

  @override
  String get failureNoHousehold => 'Još niste u domaćinstvu.';

  @override
  String get failureTooManyAttempts =>
      'Previše pokušaja. Sačekajte minut i pokušajte ponovo.';

  @override
  String get failureNotFound => 'Nije pronađeno.';

  @override
  String get failureRecipeNotFound => 'Taj recept nije dostupan.';

  @override
  String get failureInviteNotFound => 'Taj kod nije važeći.';

  @override
  String get failureInviteAlreadyUsed => 'Taj kod je već iskorišćen.';

  @override
  String get failureInviteExpired => 'Taj kod je istekao.';

  @override
  String get failureCodeNotAccepted => 'Taj kod nije prihvaćen.';

  @override
  String get failureAlreadyExists => 'To već postoji.';

  @override
  String get failureAiAllowanceUsedUp =>
      'Ovo domaćinstvo je potrošilo mesečnu AI kvotu.';

  @override
  String get failureUnavailableTryLater =>
      'To trenutno nije dostupno. Pokušajte kasnije.';

  @override
  String get failureImportPhotoFailed => 'Tu fotografiju nije moguće uvesti.';

  @override
  String get failureInvalidUrl => 'To ne izgleda kao link.';

  @override
  String get failureImportTextTooLong =>
      'Taj tekst je previše dugačak za uvoz.';

  @override
  String get failureImportUnreadable => 'Taj tekst nije moguće uvesti.';

  @override
  String get failureCouldNotReadRecipe => 'Nije moguće očitati taj recept.';

  @override
  String get failureAlreadyInThatLanguage =>
      'Ovaj recept je već napisan na tom jeziku.';

  @override
  String get failureSiteUnreachable => 'Ta stranica nije dostupna.';

  @override
  String get failureNotAWebPage => 'Taj link nije veb stranica.';

  @override
  String get failureImportTooLarge => 'To je previše veliko za uvoz.';

  @override
  String get failureImportNotFound => 'Taj uvoz nije pronađen.';

  @override
  String get failureImportAlreadySaved => 'Ovaj uvoz je već sačuvan.';

  @override
  String get failureImportNotReadyYet => 'Ovaj uvoz još nije spreman.';

  @override
  String get failureNoRecipeOnPage => 'Na toj stranici nije pronađen recept.';

  @override
  String get failureCouldNotMakeCode => 'Nije moguće napraviti kod.';

  @override
  String get failureUnexpectedServerReply =>
      'Server je poslao neočekivan odgovor.';

  @override
  String get failureUnknown => 'Nešto je pošlo naopako.';

  @override
  String get photoCouldNotBeOpened => 'Tu fotografiju nije moguće otvoriti.';
}
