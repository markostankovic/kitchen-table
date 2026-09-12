import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../application/auth_providers.dart';

/// Step one of email OTP: ask for the address.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    final String email = _email.text.trim();
    try {
      await ref.read(authRepositoryProvider).requestOtp(email);
      if (!mounted) return;
      VerifyOtpRoute(email: email).go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
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
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Text(loc.sendCode),
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
