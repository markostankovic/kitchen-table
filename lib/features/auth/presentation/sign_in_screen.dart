import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env/env.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/auth_providers.dart';
import 'sign_in_illustration.dart';

/// The way in: Google, the only path (D96).
///
/// Always renders Serbian in practice (D77): nobody is signed in, so there is
/// no `profiles.locale` to read and the app never consults the device locale.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _signingInWithGoogle = false;

  /// One slot, not one per path: only one of the two can be in flight, and
  /// whichever ran last is the one whose outcome the reader is waiting on.
  AppFailure? _failure;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _signingInWithGoogle = true;
      _failure = null;
    });

    try {
      // Deliberately no navigation here; the redirect handles it. A
      // successful `signInWithIdToken` is an ordinary Supabase session, so the
      // centralized redirect in `core/router/app_router.dart` moves the user
      // on -- to the household they already have, or to CreateHouseholdRoute.
      //
      // A null return is a dismissed account chooser, not a failure: nothing
      // to show, nothing to navigate to, just back to idle (D92 has no
      // sentence for it that would not be a lie).
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _signingInWithGoogle = false);
    }
  }

  /// The emulator-only path ([Env.hasDevLogin]); same shape as Google's.
  Future<void> _signInWithDevLogin() async {
    setState(() {
      _signingInWithGoogle = true;
      _failure = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(
            email: Env.devLoginEmail,
            password: Env.devLoginPassword,
          );
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _signingInWithGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    final ColorScheme scheme = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;
    const Widget spinner = SizedBox.square(
      dimension: AppSizes.iconInMeta,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SignInIllustration(),
                        const SizedBox(height: AppSpacing.xxl + AppSpacing.sm),
                        // The brand name, not chrome -- never localized, the
                        // same way 'Srpski'/'English' are never localized
                        // either. So an English-only lockup is right in `sr`.
                        Image.asset(
                          'assets/brand/lockup_${dark ? 'dark' : 'light'}.png',
                          height: AppSizes.lockup,
                          semanticLabel: 'Kitchen Table',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            loc.signInTagline,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_failure != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _failure!.localized(loc),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Outlined and neutral, with the official G, per Google's own
              // branding -- so this screen has no filled button, the way the
              // household screen has none either (D137).
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.signInButton),
                  backgroundColor: scheme.surfaceContainerLowest,
                  foregroundColor: scheme.onSurface,
                  side: BorderSide(color: scheme.outline),
                ),
                onPressed: _signingInWithGoogle ? null : _signInWithGoogle,
                icon: _signingInWithGoogle
                    ? spinner
                    : Image.asset(
                        'assets/brand/google_g.png',
                        width: AppSizes.iconInButton,
                        height: AppSizes.iconInButton,
                      ),
                label: Text(loc.signInWithGoogle),
              ),
              if (Env.hasDevLogin) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                // Developer chrome in emulator builds only, never seen by a
                // user -- so not localized, like the brand name above.
                OutlinedButton(
                  onPressed: _signingInWithGoogle ? null : _signInWithDevLogin,
                  child: Text('Dev login: ${Env.devLoginEmail}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
