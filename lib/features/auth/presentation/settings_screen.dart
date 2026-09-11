import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/router/routes.dart';
import '../application/auth_providers.dart';
import '../domain/app_user.dart';
import '../domain/profile.dart';

/// The Settings tab: who you are, and the way in to household management.
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
    final AsyncValue<Profile?> profile = ref.watch(ownProfileProvider);
    final AsyncValue<AppUser?> user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          profile.when(
            loading: () => const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Loading...'),
            ),
            error: (Object e, _) => ListTile(
              leading: Icon(Icons.person_outline,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Could not load your profile'),
              subtitle: Text('$e'),
            ),
            data: (Profile? p) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(p?.displayName ?? 'No profile'),
              subtitle: Text(user.value?.email ?? ''),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Household'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const HouseholdRoute().go(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => _signOut(ref),
          ),
        ],
      ),
    );
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
