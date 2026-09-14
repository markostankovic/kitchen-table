/// The app's one resolved `Locale`, derived from `profiles.locale` (D77).
///
/// `profiles.locale` is the single source of truth for what language a cook
/// reads in -- not a device setting, not a local-only preference. It is
/// already there (migration 2), already portable across a second device, and
/// it is the same field a later Phase 3 part will use to pick which
/// `recipe_translations` row to show. A second, device-local notion of
/// "current language" would be exactly the split D1 exists to prevent, one
/// phase before the question gets harder.
///
/// Falls back to [AppLocale.sr] whenever there is no profile to read yet --
/// signed out, or still loading. CLAUDE.md is explicit that this app is
/// Serbian-first, so the sign-in screen (which has no profile at all: nobody
/// is authenticated yet) renders Serbian by default rather than guessing at
/// a device locale it does not otherwise consult anywhere.
///
/// `core/` rather than `features/auth/`, on `current_household.dart`'s own
/// precedent (D52): the app root and, later, the recipe detail screen both
/// need this, and `core/` is the sanctioned place for something more than one
/// feature reaches for -- `tool/check_layers.dart` derives layer and feature
/// only from `lib/features/` paths, so this cross-feature dependency on
/// `features/auth/application/` is legal here and would not be from another
/// feature's `data/` or `application/`.
///
/// **D91: Serbian is always [srLatn], never a bare `Locale('sr')`.**
/// CLAUDE.md is "Latin script only for display", but `Locale('sr')` alone
/// resolves Flutter's own Material/Cupertino strings to their CYRILLIC
/// bundle -- verified directly against the pinned SDK
/// (`packages/flutter_localizations/lib/src/l10n/generated_material_localizations.dart`):
/// the `'sr'` case only picks the Latin bundle when `scriptCode == 'Latn'`,
/// and otherwise falls through to the Cyrillic one. Every string this app
/// does not own -- the text-selection toolbar, the back-button tooltip, a
/// date-range picker's chrome -- was rendering Cyrillic until this fix,
/// invisible because this app's OWN strings (the ARB files) were always
/// correct. `profiles.locale` keeps storing the bare code `'sr'` -- CLAUDE.md's
/// "Locale codes are `sr` and `en`. Nothing else." is about that column, not
/// about the `Locale` object a reader of it is turned into -- and every
/// consumer of [appLocaleProvider] reads `.languageCode`, which this leaves
/// unchanged, so the split is invisible to everything but `MaterialApp`
/// itself.
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/profile.dart';
import 'generated/app_localizations.dart';

part 'app_locale.g.dart';

/// Serbian, Latin script -- see this file's own doc comment (D91).
const Locale srLatn = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

/// What `MaterialApp.supportedLocales` must be given, in place of the
/// generated [AppLocalizations.supportedLocales] -- that list carries a bare
/// `Locale('sr')`, and Flutter's locale resolution matches on `languageCode`
/// first, so it would silently accept requests for the scriptless locale and
/// hand [srLatn] straight back out unresolved on some platforms. Listing
/// [srLatn] itself is what keeps the script tag through resolution.
const List<Locale> appSupportedLocales = <Locale>[Locale('en'), srLatn];

@riverpod
Locale appLocale(Ref ref) {
  final AppLocale locale =
      ref.watch(ownProfileProvider).value?.locale ?? AppLocale.sr;
  return switch (locale) {
    AppLocale.sr => srLatn,
    AppLocale.en => const Locale('en'),
  };
}
