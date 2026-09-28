import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env/env.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/auth_providers.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // The brand name, not chrome -- never localized, the
                        // same way 'Srpski'/'English' are never localized
                        // either.
                        Text(
                          'Kitchen Table',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          loc.signInTagline,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_failure != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _failure!.localized(loc),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // The screen's one action, so the one filled button -- in
              // `primary`, with no logo (the repo has no asset for one).
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.signInButton),
                ),
                onPressed: _signingInWithGoogle ? null : _signInWithGoogle,
                child: _signingInWithGoogle
                    ? const SizedBox.square(
                        dimension: AppSizes.iconInMeta,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.signInWithGoogle),
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
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
