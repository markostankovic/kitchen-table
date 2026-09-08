/// Delivers a share to the right importer, once the app can receive it.
///
/// Wraps the router rather than living inside it: it needs to outlive any one
/// screen, and it navigates with `GoRouter.go` rather than a `BuildContext`,
/// so there is nothing for it to be below.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/households/application/household_providers.dart';
import '../../features/households/domain/household.dart';
import '../router/app_router.dart';
import '../router/routes.dart';
import 'share_providers.dart';
import 'shared_import.dart';

class SharedImportListener extends ConsumerWidget {
  const SharedImportListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Arriving shares are parked rather than acted on, because the app may not
    // be able to act yet.
    ref.listen(incomingSharesProvider, (
      AsyncValue<SharedImport>? _,
      AsyncValue<SharedImport> next,
    ) {
      final SharedImport? share = next.value;
      if (share != null) ref.read(pendingShareProvider.notifier).receive(share);
    });

    final SharedImport? pending = ref.watch(pendingShareProvider);
    final AsyncValue<Household?> household =
        ref.watch(currentHouseholdProvider);

    // The same two gates the router's redirect checks, in the same order. A
    // share that arrives at the sign-in screen waits here and is delivered
    // after onboarding finishes, rather than being bounced to /sign-in and
    // lost -- the redirect returns a bare path and carries no destination.
    if (pending != null && household.value != null) {
      // Navigation cannot happen during a build. The share is cleared in the
      // same callback so one share opens exactly one screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pendingShareProvider.notifier).clear();
        ref.read(goRouterProvider).go(_locationFor(pending));
      });
    }

    return child;
  }
}

/// Which importer a share opens, prefilled.
///
/// Prefilled rather than submitted: sharing the wrong page is easy, and a tap
/// costs less than a model call somebody did not ask for.
String _locationFor(SharedImport share) => switch (share) {
      SharedUrl(url: final String url) => ImportUrlRoute(url: url).location,
      SharedText(text: final String text, sourceUrl: final String? source) =>
        ImportPasteRoute(text: text, sourceUrl: source).location,
    };
