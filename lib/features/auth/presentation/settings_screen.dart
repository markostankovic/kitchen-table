import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/household/current_household.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_mode.dart';
import '../../../core/widgets/app_monogram_tile.dart';
import '../application/auth_providers.dart';
import '../domain/app_user.dart';
import '../domain/profile.dart';

/// The Settings tab, in groups (Phase 7 part 9b): who you are, Appearance
/// (Light/Dark, D128), Language (D77), the way in to the household screen,
/// and -- set apart below a hairline -- sign-out.
///
/// Owned by `auth/` because everything on it is account state, apart from
/// the theme (device-local, reached through `core/theme/`) and the household
/// row's name and count (reached through `core/household/`, D52). The
/// household itself lives on its own screen in `features/households/`.
///
/// Navigation between the two goes through `core/router/routes.dart`, which
/// belongs to no feature, so neither feature imports the other.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final AsyncValue<Profile?> profile = ref.watch(ownProfileProvider);
    final AsyncValue<AppUser?> user = ref.watch(authStateProvider);
    final ThemeMode themeMode =
        ref.watch(appThemeModeProvider).value ?? ThemeMode.light;
    final ({String name, int memberCount})? household = ref
        .watch(currentHouseholdSummaryProvider)
        .value;

    return Scaffold(
      appBar: AppBar(title: Text(loc.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          _SettingsCard(
            child: profile.when(
              loading: () => _ProfileRow(
                leading: const Icon(Icons.person_outline),
                title: loc.profileLoading,
              ),
              error: (Object e, _) => _ProfileRow(
                leading: const Icon(Icons.person_outline),
                title: loc.profileLoadError,
                lines: <String>[localizedErrorMessage(e, loc)],
              ),
              data: (Profile? p) => _ProfileRow(
                leading: AppMonogramTile(
                  letter: _initial(p?.displayName),
                  size: AppSizes.avatar,
                  circular: true,
                ),
                title: p?.displayName ?? loc.profileNone,
                email: user.value?.email,
                lines: <String>[loc.signedInWithGoogle],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _GroupHeader(text: loc.appearanceSectionTitle),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(loc.themeTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  loc.themeSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ThemeMode>(
                  // The mock keeps the sun/moon on the selected segment, not
                  // a check.
                  showSelectedIcon: false,
                  segments: <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(loc.themeLight),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(loc.themeDark),
                    ),
                  ],
                  selected: <ThemeMode>{themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) => ref
                      .read(appThemeModeProvider.notifier)
                      .set(selection.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _GroupHeader(text: loc.languageSectionTitle),
          _SettingsCard(
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
          const SizedBox(height: AppSpacing.xl),
          _GroupHeader(text: loc.householdSectionTitle),
          _HouseholdRow(
            name: household?.name ?? loc.householdScreenTitle,
            memberCount: household?.memberCount,
            onTap: () => const HouseholdRoute().go(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.xl),
          _GroupHeader(text: loc.accountSectionTitle),
          // Neutral, not destructive: signing out loses nothing, and it has
          // no confirm dialog. `onSurface`, never `error`.
          OutlinedButton.icon(
            onPressed: () => _signOut(ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: theme.colorScheme.outline),
            ),
            icon: const Icon(Icons.logout),
            label: Text(loc.signOut),
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

/// One settings group's body: the theme `Card`, padded `lg`.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    ),
  );
}

/// A group header, `sm` above its card.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The profile card's contents: avatar, then name / email / any further
/// lines. The loading and error states reuse it with an icon in place of
/// the avatar, so all three hold the same shape.
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.leading,
    required this.title,
    this.email,
    this.lines = const <String>[],
  });

  final Widget leading;
  final String title;
  final String? email;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? emailText = email;
    return Row(
      children: <Widget>[
        leading,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleMedium),
              if (emailText != null && emailText.isNotEmpty)
                Text(
                  emailText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              for (final String line in lines)
                Text(
                  line,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The household group's one row: the whole card is the tap target.
/// [memberCount] is null while the members are still loading, and the line
/// is then left out rather than guessed.
class _HouseholdRow extends StatelessWidget {
  const _HouseholdRow({
    required this.name,
    required this.memberCount,
    required this.onTap,
  });

  final String name;
  final int? memberCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations loc = AppLocalizations.of(context);
    final int? count = memberCount;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.home_outlined,
                size: AppSizes.icon,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name, style: theme.textTheme.titleMedium),
                    if (count != null)
                      Text(
                        loc.householdMemberCount(count),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
