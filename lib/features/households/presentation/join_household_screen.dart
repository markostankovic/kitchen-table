import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/kitchen_colors.dart';
import '../../../core/widgets/app_field_label.dart';
import '../application/household_providers.dart';
import '../domain/invite_redemption.dart';
import 'household_landing.dart';
import 'onboarding_mark.dart';

/// Onboarding: the signed-in user has an invite code for someone else's
/// household.
///
/// The other branch out of onboarding is [CreateHouseholdScreen]. Both are
/// top-level routes outside the shell, and both are listed in the router's
/// `onboarding` check -- without that, the redirect bounces this screen
/// straight back to create-household.
///
/// With [another], the in-app variant for someone who already has a
/// household (phase9-household-create-join-another): ✕ in an app bar, no
/// mark, a body naming the current household, and no cross-link. A fresh
/// join lands on Recipes with Undo. A code for a household the caller is
/// already in is not an error: a quiet panel says so, and the button becomes
/// Switch to it, or Done when it is the current one.
class JoinHouseholdScreen extends ConsumerStatefulWidget {
  const JoinHouseholdScreen({this.another = false, super.key});

  /// The in-app variant, pushed from Settings › Households.
  final bool another;

  @override
  ConsumerState<JoinHouseholdScreen> createState() =>
      _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends ConsumerState<JoinHouseholdScreen> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  bool _joining = false;
  AppFailure? _failure;

  /// "another" mode only: a code for a household the caller already belongs
  /// to. Shows the panel, and turns the button into Switch / Done.
  InviteRedemption? _redemption;

  @override
  void dispose() {
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _joining = true;
      _failure = null;
    });

    try {
      final InviteRedemption redemption = await ref
          .read(householdRepositoryProvider)
          .redeemInvite(_code.text);
      if (widget.another) {
        if (!mounted) return;
        if (redemption.alreadyMember) {
          setState(() => _redemption = redemption);
          return;
        }
        await landInHousehold(
          context,
          ref,
          id: redemption.householdId,
          name: redemption.householdName,
          action: HouseholdLandingAction.undo,
        );
        return;
      }
      // Onboarding ignores alreadyMember: with no household, it can only be
      // a retry after a lost response, and the switch is the same.
      //
      // Switch to it, which re-reads, so the router's redirect sees the
      // household and lets the user out of onboarding. The await matters:
      // invalidate is lazy, and the redirect reads the value synchronously.
      await ref
          .read(currentHouseholdProvider.notifier)
          .switchTo(redemption.householdId);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  /// The already-a-member panel's Switch: to a household the caller was
  /// already in, so the landing offers Undo, as a join does.
  Future<void> _switchToRedeemed(InviteRedemption redemption) async {
    setState(() {
      _joining = true;
      _failure = null;
    });
    try {
      await landInHousehold(
        context,
        ref,
        id: redemption.householdId,
        name: redemption.householdName,
        action: HouseholdLandingAction.undo,
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  /// Clears the field and the panel, and puts the cursor back in the field.
  void _useAnotherCode() {
    _code.clear();
    setState(() {
      _redemption = null;
      _failure = null;
    });
    _codeFocus.requestFocus();
  }

  /// The FilledButton's label and action. Join, until a code turns out to
  /// be for a household the caller is already in: then Done (pops back to
  /// the list) for the current one, Switch for another.
  (String, VoidCallback) _primary(AppLocalizations l10n) {
    final InviteRedemption? r = _redemption;
    if (r == null) return (l10n.joinButton, _submit);
    final String? currentId = ref.watch(currentHouseholdProvider).value?.id;
    if (r.householdId == currentId) {
      return (l10n.doneButton, () => Navigator.of(context).pop());
    }
    return (
      l10n.switchToHouseholdButton(r.householdName),
      () => _switchToRedeemed(r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool another = widget.another;
    final String currentName = another
        ? ref.watch(currentHouseholdProvider).value?.name ?? ''
        : '';
    final (String primaryLabel, VoidCallback primaryAction) = _primary(l10n);
    return Scaffold(
      appBar: another ? AppBar(leading: const CloseButton()) : null,
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
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  another ? AppSpacing.sm : AppSpacing.xxl + AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (!another) ...const <Widget>[
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OnboardingMark(),
                      ),
                      SizedBox(height: AppSpacing.xl),
                    ],
                    Text(
                      another
                          ? l10n.joinAnotherHouseholdTitle
                          : l10n.joinHouseholdTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      another
                          ? l10n.joinAnotherHouseholdBody(currentName)
                          : l10n.joinHouseholdSubtitle,
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
                      focusNode: _codeFocus,
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
                      onChanged: (_) {
                        if (_redemption != null) {
                          setState(() => _redemption = null);
                        }
                      },
                      onSubmitted: (_) => _redemption == null ? _submit() : null,
                    ),
                    if (_redemption != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      _AlreadyMemberPanel(
                        text: l10n.alreadyMemberOfHousehold(
                          _redemption!.householdName,
                        ),
                      ),
                    ],
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
                      onPressed: _joining ? null : primaryAction,
                      child: _joining
                          ? const SizedBox.square(
                              dimension: AppSizes.iconInMeta,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(primaryLabel),
                    ),
                    if (!another) ...<Widget>[
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
                    ] else if (_redemption != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppSizes.button),
                        ),
                        onPressed: _joining ? null : _useAnotherCode,
                        child: Text(l10n.useAnotherCodeButton),
                      ),
                    ],
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

/// A code for a household the caller is already in: said quietly, in the
/// card fill, never in `error` -- nothing went wrong.
class _AlreadyMemberPanel extends StatelessWidget {
  const _AlreadyMemberPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle body = theme.textTheme.bodyMedium!;
    final Color secondary = theme.colorScheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.extension<KitchenColors>()!.card,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Centred on the first line of text, however many it wraps to.
            SizedBox(
              height: body.fontSize! * body.height!,
              child: Icon(
                Icons.info_outline,
                size: AppSizes.iconInMeta,
                color: secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(text, style: body.copyWith(color: secondary)),
            ),
          ],
        ),
      ),
    );
  }
}
