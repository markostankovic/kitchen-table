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

  @override
  String get offlineBannerMessage =>
      'Nema veze -- prikazane su sačuvane kopije. Izmene se neće sačuvati.';

  @override
  String recipeServingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count porcija',
      few: '$count porcije',
      one: '$count porcija',
    );
    return '$_temp0';
  }

  @override
  String recipePrepMinutes(int minutes) {
    return '$minutes min priprema';
  }

  @override
  String recipeCookMinutes(int minutes) {
    return '$minutes min kuvanja';
  }

  @override
  String get ingredientOptionalTrailer => 'opciono';

  @override
  String get ingredientNotMatchedTooltip => 'Nije povezano sa sastojkom';

  @override
  String snackSlotCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obroka',
      few: '$count obroka',
      one: '$count obroku',
    );
    return '$_temp0';
  }

  @override
  String ingredientsMatchedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sastojaka',
      few: '$count sastojka',
      one: '$count sastojak',
    );
    return '$_temp0';
  }

  @override
  String get addRecipeTooltip => 'Dodaj recept';

  @override
  String get newRecipeMenuItem => 'Novi recept';

  @override
  String get importFromLinkMenuItem => 'Uvezi sa linka';

  @override
  String get pasteRecipeMenuItem => 'Nalepi recept';

  @override
  String get photographPageMenuItem => 'Fotografiši stranicu';

  @override
  String get searchRecipesHint => 'Pretraži recepte';

  @override
  String get noRecipesMatch => 'Nema recepata koji se poklapaju.';

  @override
  String get noRecipesYet =>
      'Još nema recepata.\n\nDodajte jedan koji znate napamet.';

  @override
  String get newRecipeTitle => 'Novi recept';

  @override
  String get editRecipeTitle => 'Izmena recepta';

  @override
  String get servingsFieldLabel => 'Porcije';

  @override
  String get prepMinutesFieldLabel => 'Priprema (min)';

  @override
  String get cookMinutesFieldLabel => 'Kuvanje (min)';

  @override
  String get writtenInFieldLabel => 'Napisano na';

  @override
  String get statusFieldLabel => 'Status';

  @override
  String get testedStatusLabel => 'Isprobano';

  @override
  String get tagsFieldLabel => 'Oznake';

  @override
  String get tagsHelperText => 'Odvojene zarezima';

  @override
  String get addIngredientButton => 'Dodaj sastojak';

  @override
  String get addStepButton => 'Dodaj korak';

  @override
  String get saveButton => 'Sačuvaj';

  @override
  String get cameraButton => 'Kamera';

  @override
  String get galleryButton => 'Galerija';

  @override
  String get removePhotoTooltip => 'Ukloni fotografiju';

  @override
  String get removeTooltip => 'Ukloni';

  @override
  String get wholeNumberError => 'Ceo broj.';

  @override
  String atLeastError(int minimum) {
    return 'Najmanje $minimum.';
  }

  @override
  String get ingredientLineHint => '2 šolje glatkog brašna';

  @override
  String get ingredientNoMatchLabel => 'Nema poklapanja';

  @override
  String ingredientSuggestionLabel(String name) {
    return '$name?';
  }

  @override
  String ingredientPickerQuestion(String query) {
    return 'Koji sastojak je „$query”?';
  }

  @override
  String get ingredientPickerNoMatches => 'Ništa u katalogu se ne poklapa.';

  @override
  String ingredientPickerCreateNew(String query) {
    return 'Napravi „$query”';
  }

  @override
  String get ingredientPickerCreateNewSubtitle =>
      'Dodaje ga u katalog domaćinstva';

  @override
  String ingredientPickerMatchedByAlias(String name) {
    return 'poklopio „$name”';
  }

  @override
  String get ingredientPickerUnverifiedTooltip =>
      'Dodao je neko drugi, nije sa zvaničnog spiska';

  @override
  String get addNoteInsteadMenuItem => 'Dodaj napomenu umesto recepta';

  @override
  String get addNoteInsteadSubtitle =>
      '„ostaci”, „jedemo napolju” -- bez recepta';

  @override
  String get addNoteDialogTitle => 'Dodaj napomenu';

  @override
  String get addNoteHint => 'npr. ostaci';

  @override
  String get addButton => 'Dodaj';

  @override
  String get createHouseholdTitle => 'Imenujte svoje domaćinstvo';

  @override
  String get createHouseholdSubtitle =>
      'Recepti i planovi obroka se dele sa svima u njemu.';

  @override
  String get householdNameFieldLabel => 'Naziv domaćinstva';

  @override
  String get householdNameEmptyError => 'Unesite naziv.';

  @override
  String get createHouseholdButton => 'Napravi';

  @override
  String get haveInviteCodeButton => 'Imam pozivni kod';

  @override
  String get householdScreenTitle => 'Domaćinstvo';

  @override
  String get noHouseholdYet => 'Još nema domaćinstva.';

  @override
  String get membersSectionTitle => 'Članovi';

  @override
  String get inviteSomeoneSectionTitle => 'Pozovi nekoga';

  @override
  String get loadingEllipsis => 'Učitavanje...';

  @override
  String get noActiveCodesMessage =>
      'Nema aktivnih kodova. Napravite jedan i pročitajte ga onome ko se priključuje.';

  @override
  String get copyCodeTooltip => 'Kopiraj kod';

  @override
  String get creatingEllipsis => 'Pravljenje...';

  @override
  String get createInviteCodeButton => 'Napravi pozivni kod';

  @override
  String get codeCopiedSnackbar => 'Kod kopiran.';

  @override
  String get inviteExpiresWithinHour => 'Ističe za manje od sat vremena';

  @override
  String inviteExpiresInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ističe za $count sati',
      few: 'Ističe za $count sata',
      one: 'Ističe za $count sat',
    );
    return '$_temp0';
  }

  @override
  String inviteExpiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ističe za $count dana',
      few: 'Ističe za $count dana',
      one: 'Ističe za $count dan',
    );
    return '$_temp0';
  }

  @override
  String get householdRoleOwner => 'Vlasnik';

  @override
  String get householdRoleAdult => 'Član';

  @override
  String get unknownDisplayName => 'Nepoznato';

  @override
  String get joinHouseholdTitle => 'Unesite svoj pozivni kod';

  @override
  String get joinHouseholdSubtitle =>
      'Zamolite nekoga iz domaćinstva da vam napravi kod.';

  @override
  String get joinButton => 'Priključi se';

  @override
  String get createHouseholdInsteadButton => 'Napravi domaćinstvo umesto toga';

  @override
  String get importPasteTitle => 'Nalepi recept';

  @override
  String get importPasteBody =>
      'Nalepite ceo tekst -- sastojke, postupak, šta god je stiglo uz recept. Nije problem ako ima i dodatnog teksta oko recepta.';

  @override
  String get importPasteHint =>
      'Šargarepa torta\n\n200 g šargarepe\n2 šolje brašna…';

  @override
  String get importSourceFieldLabel => 'Odakle je (opcionalno)';

  @override
  String get importSourceHelperText => 'Čuva se i prikazuje uz recept.';

  @override
  String get readRecipeButton => 'Pročitaj ovaj recept';

  @override
  String get importPhotoTitle => 'Fotografiši stranicu';

  @override
  String get importPhotoBody =>
      'Uklopite recept u kadar. U redu je i cela stranica -- dve kolone, spisak sastojaka postrani, fotografija jela. Sve što je navedeno kao izvor se čuva uz recept.';

  @override
  String get takePhotoButton => 'Fotografiši';

  @override
  String get choosePhotoButton => 'Izaberi fotografiju';

  @override
  String get importUrlTitle => 'Uvezi sa linka';

  @override
  String get importUrlBody =>
      'Nalepite adresu stranice sa receptom. Šta god stranica navede kao izvor se čuva uz recept.';

  @override
  String get linkFieldLabel => 'Link';

  @override
  String get reviewImportTitle => 'Pregled uvoza';

  @override
  String get readingRecipeEllipsis => 'Čitanje recepta...';

  @override
  String get queuedEllipsis => 'U redu čekanja...';

  @override
  String get importWaitingHint =>
      'Ovo traje nekoliko sekundi. Možete izaći i vratiti se.';

  @override
  String get discardImportButton => 'Odbaci ovaj uvoz';

  @override
  String get openRecipeButton => 'Otvori recept';

  @override
  String get methodHeading => 'Postupak';

  @override
  String get saveRecipeButton => 'Sačuvaj recept';

  @override
  String importMatchedOfTotal(int matched, String totalPhrase) {
    return 'Poklopljeno $matched od $totalPhrase';
  }

  @override
  String importWorthALook(int attention) {
    return '$attention vredno pažnje pre čuvanja';
  }
}
