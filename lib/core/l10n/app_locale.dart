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
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/profile.dart';

part 'app_locale.g.dart';

@riverpod
Locale appLocale(Ref ref) {
  final AppLocale locale =
      ref.watch(ownProfileProvider).value?.locale ?? AppLocale.sr;
  return Locale(locale.code);
}
