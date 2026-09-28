import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_monogram_tile.dart';
import '../../../core/widgets/app_section_heading.dart';
import '../application/auth_providers.dart';
import '../domain/app_user.dart';
import '../domain/profile.dart';

/// The Settings tab: who you are, the way in to household management, and
/// the language toggle (D77).
///
/// Owned by `auth/` because everything on it is account state. The household
/// half lives on its own screen in `features/households/` -- which is not
/// merely rule-following: the member list and invite flow arriving next slice
/// need a screen of their own regardless.
///
/// Navigation between the two goes through `core/router/routes.dart`, which
/// belongs to no feature, so neither feature imports the other.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final AsyncValue<Profile?> profile = ref.watch(ownProfileProvider);
    final AsyncValue<AppUser?> user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc.navSettings)),
      body: ListView(
        children: <Widget>[
          profile.when(
            loading: () => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(loc.profileLoading),
            ),
            error: (Object e, _) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(loc.profileLoadError),
              subtitle: Text(localizedErrorMessage(e, loc)),
            ),
            data: (Profile? p) => ListTile(
              leading: AppMonogramTile(
                letter: _initial(p?.displayName),
                size: AppSizes.avatar,
                circular: true,
              ),
              title: Text(p?.displayName ?? loc.profileNone),
              subtitle: Text(user.value?.email ?? ''),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppSectionHeading(text: loc.languageSectionTitle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            // Language names are never translated -- 'Srpski' and 'English'
            // read the same in both locales, the same choice
            // `recipe_edit_screen.dart`'s "Written in" toggle already made.
            child: SegmentedButton<AppLocale>(
              segments: const <ButtonSegment<AppLocale>>[
                ButtonSegment<AppLocale>(
                  value: AppLocale.sr,
                  label: Text('Srpski'),
                ),
                ButtonSegment<AppLocale>(
                  value: AppLocale.en,
                  label: Text('English'),
                ),
              ],
              selected: <AppLocale>{profile.value?.locale ?? AppLocale.sr},
              onSelectionChanged: (Set<AppLocale> selection) =>
                  _setLocale(context, ref, selection.first),
            ),
          ),
          // The theme's Divider takes 1dp of space, so without this the
          // hairline sits flush under the toggle (Phase 7 part 8's walk).
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(loc.householdMenuItem),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const HouseholdRoute().go(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(loc.signOut),
            onTap: () => _signOut(ref),
          ),
        ],
      ),
    );
  }

  /// The avatar's letter. `substring(0, 1)` rather than `package:characters`
  /// (rule 8), on `RecipeCard._monogram`'s precedent; empty when there is no
  /// name, so the circle still holds the row's alignment.
  static String _initial(String? name) {
    final String trimmed = (name ?? '').trim();
    return trimmed.isEmpty ? '' : trimmed.substring(0, 1).toUpperCase();
  }

  /// Writes the choice, then invalidates `ownProfileProvider` -- the write
  /// alone changes nothing on screen, since nothing re-fetches on its own;
  /// the invalidation is what makes `appLocaleProvider` recompute and the
  /// whole app re-render (`core/l10n/app_locale.dart`).
  ///
  /// A failure surfaces in a `SnackBar` rather than inline, on the verify
  /// screen's resend precedent -- this is a transient action on an otherwise
  /// static row, not a form with a field to attach an error to.
  Future<void> _setLocale(
    BuildContext context,
    WidgetRef ref,
    AppLocale locale,
  ) async {
    try {
      await ref.read(authRepositoryProvider).updateLocale(locale);
      ref.invalidate(ownProfileProvider);
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      final AppLocalizations loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(loc))));
    }
  }

  /// Wipes the household-scoped cache before signing out -- a shopping list
  /// left behind on a shared device after sign-out is a privacy question,
  /// so the wipe goes first rather than racing a rebuild that might read it
  /// (D70). Best-effort: the cache wipe must not block signing out, so a
  /// failure to clear it is not awaited into a user-visible error --
  /// `AppDatabase.clearHouseholdCache` already logs and swallows its own
  /// failures (D69/D70).
  Future<void> _signOut(WidgetRef ref) async {
    await ref.read(appDatabaseProvider).clearHouseholdCache();
    await ref.read(authRepositoryProvider).signOut();
  }
}
