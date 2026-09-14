import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../application/import_providers.dart';

/// Paste a link and let the server read the page behind it.
///
/// One field, because that is the whole input. The interesting half is on the
/// server: the URL is vetted before anything is fetched (D45), and a page that
/// publishes schema.org JSON-LD is read without a model call at all.
class ImportUrlScreen extends ConsumerStatefulWidget {
  const ImportUrlScreen({this.initialUrl, super.key});

  /// Set when another app shared a link into the importer. The cook still
  /// presses the button -- prefilled, not auto-submitted.
  final String? initialUrl;

  @override
  ConsumerState<ImportUrlScreen> createState() => _ImportUrlScreenState();
}

class _ImportUrlScreenState extends ConsumerState<ImportUrlScreen> {
  late final TextEditingController _url =
      TextEditingController(text: widget.initialUrl ?? '');

  bool _submitting = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final String jobId =
          await ref.read(importRepositoryProvider).createFromUrl(_url.text);
      if (!mounted) return;
      ImportReviewRoute(jobId).go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importUrlTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.importUrlBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            // Not autofocused when a share prefilled it: the keyboard would
            // cover the button the cook is being asked to press.
            autofocus: widget.initialUrl == null,
            onSubmitted: (_) => _submitting ? null : _submit(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.linkFieldLabel,
              hintText: 'https://…',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_failure != null) ...<Widget>[
                Text(
                  _failure!.localized(l10n),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.readRecipeButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
