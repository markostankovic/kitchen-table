import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../application/household_providers.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l10n.joinHouseholdTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  l10n.joinHouseholdSubtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_failure != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _failure!.localized(l10n),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _joining ? null : _submit,
                  child: _joining
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.joinButton),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _joining
                      ? null
                      : () => const CreateHouseholdRoute().go(context),
                  child: Text(l10n.createHouseholdInsteadButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
