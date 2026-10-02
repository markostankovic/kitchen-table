import 'package:flutter/material.dart';
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

/// Onboarding: the signed-in user has no household yet.
///
/// The other way out of onboarding is [JoinHouseholdScreen], for someone who
/// was handed an invite code instead.
class CreateHouseholdScreen extends ConsumerStatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  ConsumerState<CreateHouseholdScreen> createState() =>
      _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends ConsumerState<CreateHouseholdScreen> {
  final TextEditingController _name = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _failure = null;
    });

    try {
      await ref.read(householdRepositoryProvider).create(_name.text.trim());
      // Refetch so the router's redirect sees the new household and lets the
      // user out of onboarding.
      ref.invalidate(currentHouseholdProvider);
      await ref.read(currentHouseholdProvider.future);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                        l10n.createHouseholdTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.createHouseholdSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppFieldLabel(text: l10n.householdNameFieldLabel),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _name,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        style: theme.textTheme.bodyMedium,
                        validator: (String? value) =>
                            (value ?? '').trim().isEmpty
                            ? l10n.householdNameEmptyError
                            : null,
                        onFieldSubmitted: (_) => _submit(),
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
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: AppSizes.iconInMeta,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.createHouseholdButton),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppSizes.button),
                        ),
                        onPressed: _saving
                            ? null
                            : () => const JoinHouseholdRoute().go(context),
                        child: Text(l10n.haveInviteCodeButton),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
