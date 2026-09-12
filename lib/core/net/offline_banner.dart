/// The global offline signal Phase 2's Done-when asks for (D76): a strip
/// [AppShell] renders above every tab's body, distinct from the narrower
/// per-screen "Showing your saved copy — no connection." lines on the
/// shopping list and meal plan screens (Phase 2 parts 5, 6b).
///
/// The two say different things and neither replaces the other. This one
/// says "the phone cannot reach the server, and nothing you change will
/// save" -- true of the whole session, including screens (Settings) with no
/// cache of their own to be stale. The per-screen line says "this
/// particular list/week is not what the server has right now" -- narrower,
/// and only rendered where a cache hit actually happened.
///
/// Renders nothing on [Reachability.unknown] as well as [Reachability
/// .online]: `unknown` means no read has completed yet this session, and a
/// banner before anything has actually failed would be a guess dressed as a
/// fact.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_status.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool offline =
        ref.watch(networkStatusProvider) == Reachability.offline;
    if (!offline) return const SizedBox.shrink();

    return ColoredBox(
      color: Theme.of(context).colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "You're offline — showing saved copies. Changes won't save.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
    );
  }
}
