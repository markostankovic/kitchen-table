import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../application/auth_providers.dart';

/// Step two of email OTP: enter the code.
///
/// On success nothing navigates explicitly -- the auth stream fires, the
/// router's redirect re-runs, and it decides where to land based on whether
/// the user has a household yet.
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final TextEditingController _code = TextEditingController();
  bool _verifying = false;

  /// Either a plain, already-localized validator string (`codeEmptyError`,
  /// looked up once at submit time) or an [AppFailure], localized lazily in
  /// [build] so a locale switch while the error is on screen still shows the
  /// right sentence -- the same reasoning [AppFailureL10n.localized]'s call
  /// sites elsewhere in this part follow.
  Object? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String token = _code.text.trim();
    if (token.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).codeEmptyError);
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(email: widget.email, token: token);
      // Deliberately no navigation here; the redirect handles it.
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await ref.read(authRepositoryProvider).requestOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).newCodeSent)),
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(loc.checkEmailTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  loc.codeSentTo(widget.email),
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
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _errorText(loc),
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _verifying ? null : _submit,
                  child: _verifying
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(loc.verify),
                ),
                TextButton(
                  onPressed: _verifying ? null : _resend,
                  child: Text(loc.resendCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [_error] is either a plain, already-localized validator string or an
  /// [AppFailure] to localize lazily -- see its own doc comment.
  String _errorText(AppLocalizations loc) {
    final Object error = _error!;
    return error is AppFailure ? error.localized(loc) : error as String;
  }
}
