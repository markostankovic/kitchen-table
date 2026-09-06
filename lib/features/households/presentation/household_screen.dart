import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/household_providers.dart';
import '../domain/household.dart';

/// Household management.
///
/// Currently just the household's identity. The member list and invite flow
/// land here in the next slice.
class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Household?> household =
        ref.watch(currentHouseholdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Household')),
      body: household.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your household.\n\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (Household? h) => h == null
            ? const Center(child: Text('No household yet.'))
            : ListView(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(h.name),
                    subtitle: const Text('Household name'),
                  ),
                ],
              ),
      ),
    );
  }
}
