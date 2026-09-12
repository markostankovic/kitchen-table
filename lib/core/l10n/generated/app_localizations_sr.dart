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
}
