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
/// Phase 7 part 2 restyles it calm (D118): an inset rounded card in
/// [KitchenColors.offline] -- a neutral container tone -- rather than the
/// full-bleed `errorContainer` strip it used to be. Offline is a frequent,
/// ordinary state in this app, not a fault; the banner informs, it does not
/// alarm. Where it lives and when it shows are untouched.
///
/// Renders nothing on [Reachability.unknown] as well as [Reachability
/// .online]: `unknown` means no read has completed yet this session, and a
/// banner before anything has actually failed would be a guess dressed as a
/// fact.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/kitchen_colors.dart';
import 'network_status.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool offline =
        ref.watch(networkStatusProvider) == Reachability.offline;
    if (!offline) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final KitchenColors colors = theme.extension<KitchenColors>()!;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.offline,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.cloud_off,
                  size: AppSizes.iconInButton,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).offlineBannerMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onOffline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
