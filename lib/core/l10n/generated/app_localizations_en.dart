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
}
