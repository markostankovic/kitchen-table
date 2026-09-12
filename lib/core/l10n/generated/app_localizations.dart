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
