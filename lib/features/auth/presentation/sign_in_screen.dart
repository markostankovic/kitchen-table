import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../application/auth_providers.dart';

/// The way in: Google, or step one of email OTP.
///
/// Both paths are live on purpose (D96). Google is the replacement, but email
/// OTP is the only thing that works on hosted today, and part 4 is what
/// removes it -- deleting the working path first would leave the app
/// unsignable-into.
///
/// Always renders Serbian in practice (D77): nobody is signed in, so there is
/// no `profiles.locale` to read and the app never consults the device locale.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _sending = false;
  bool _signingInWithGoogle = false;

  /// One slot, not one per path: only one of the two can be in flight, and
  /// whichever ran last is the one whose outcome the reader is waiting on.
  AppFailure? _failure;

  bool get _busy => _sending || _signingInWithGoogle;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _sending = true;
      _failure = null;
    });

    final String email = _email.text.trim();
    try {
      await ref.read(authRepositoryProvider).requestOtp(email);
      if (!mounted) return;
      VerifyOtpRoute(email: email).go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // The brand name, not chrome -- never localized, the same
                  // way 'Srpski'/'English' are never localized either.
                  Text('Kitchen Table',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    loc.signInSubtitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: loc.emailLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (String? value) {
                      final String v = (value ?? '').trim();
                      if (v.isEmpty) return loc.emailEmptyError;
                      if (!v.contains('@') || !v.contains('.')) {
                        return loc.emailInvalidError;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_failure != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      _failure!.localized(loc),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _sending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Text(loc.sendCode),
                  ),
                  const SizedBox(height: 24),
                  _OrDivider(label: loc.orDivider),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _busy ? null : _signInWithGoogle,
                    child: _signingInWithGoogle
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Text(loc.signInWithGoogle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal rule with a word in the middle.
///
/// The point is that the email form above it stays obviously usable while
/// both paths are live (D96) -- without it the two buttons read as a primary
/// action and its alternative, rather than as two separate ways in.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
