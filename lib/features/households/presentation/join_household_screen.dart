import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_field_label.dart';
import '../application/household_providers.dart';
import 'onboarding_mark.dart';

/// Onboarding: the signed-in user has an invite code for someone else's
/// household.
///
/// The other branch out of onboarding is [CreateHouseholdScreen]. Both are
/// top-level routes outside the shell, and both are listed in the router's
/// `onboarding` check -- without that, the redirect bounces this screen
/// straight back to create-household.
class JoinHouseholdScreen extends ConsumerStatefulWidget {
  const JoinHouseholdScreen({super.key});

  @override
  ConsumerState<JoinHouseholdScreen> createState() =>
      _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends ConsumerState<JoinHouseholdScreen> {
  final TextEditingController _code = TextEditingController();
  bool _joining = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _joining = true;
      _failure = null;
    });

    try {
      await ref.read(householdRepositoryProvider).redeemInvite(_code.text);
      // Refetch so the router's redirect sees the household and lets the user
      // out of onboarding. The await matters: invalidate is lazy, and the
      // redirect reads the value synchronously.
      ref.invalidate(currentHouseholdProvider);
      await ref.read(currentHouseholdProvider.future);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            // Fills the screen when there is room, so the Spacer pins the
            // buttons to the bottom; scrolls when the keyboard takes it. The
            // padding is inside: a trailing SliverPadding sits past the filled
            // extent, pushing the bottom air off-screen.
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xxl + AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OnboardingMark(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.joinHouseholdTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.joinHouseholdSubtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppFieldLabel(text: l10n.inviteCodeFieldLabel),
                    const SizedBox(height: AppSpacing.sm),
                    // A code rather than prose, so titleLarge, spaced out,
                    // with every digit the same width.
                    TextField(
                      controller: _code,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: theme.textTheme.titleLarge?.copyWith(
                        letterSpacing: AppSpacing.sm,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(counterText: ''),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_failure != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _failure!.localized(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    const Spacer(),
                    FilledButton(
                      onPressed: _joining ? null : _submit,
                      child: _joining
                          ? const SizedBox.square(
                              dimension: AppSizes.iconInMeta,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.joinButton),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(AppSizes.button),
                      ),
                      onPressed: _joining
                          ? null
                          : () => const CreateHouseholdRoute().go(context),
                      child: Text(l10n.createHouseholdInsteadButton),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
