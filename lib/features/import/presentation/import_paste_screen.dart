import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/router/routes.dart';
import '../application/import_providers.dart';

/// Paste a recipe and hand it to the server.
///
/// The whole of 1d's entry point for now. `import-url` and `import-photo` will
/// hang beside it (D14 gives all three the same queue), which is why this
/// screen does one thing and navigates away rather than owning the flow.
class ImportPasteScreen extends ConsumerStatefulWidget {
  const ImportPasteScreen({this.initialText, this.initialSourceUrl, super.key});

  /// Set when another app shared prose into the importer. `initialSourceUrl`
  /// is the link that came with it, if any -- attribution rather than
  /// something to fetch.
  final String? initialText;
  final String? initialSourceUrl;

  @override
  ConsumerState<ImportPasteScreen> createState() => _ImportPasteScreenState();
}

class _ImportPasteScreenState extends ConsumerState<ImportPasteScreen> {
  // A controller here, unlike the recipe editor's rows: this is one field with
  // a fixed lifetime, which is the case the editor's doc comment says a
  // controller is right for.
  late final TextEditingController _text =
      TextEditingController(text: widget.initialText ?? '');
  late final TextEditingController _sourceUrl =
      TextEditingController(text: widget.initialSourceUrl ?? '');

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    _sourceUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final String jobId = await ref
          .read(importRepositoryProvider)
          .createFromText(_text.text, sourceUrl: _sourceUrl.text);
      if (!mounted) return;
      // Replaces rather than pushes: coming back to a paste box that already
      // started a job would invite starting a second one.
      ImportReviewRoute(jobId).go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paste a recipe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Paste the whole thing -- ingredients, method, whatever else came '
            'with it. Extra text around the recipe is fine.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            maxLines: 14,
            minLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Šargarepa torta\n\n200 g šargarepe\n2 šolje brašna…',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sourceUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Where it came from (optional)',
              helperText: 'Stored and shown with the recipe.',
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
              if (_error != null) ...<Widget>[
                Text(
                  _error!,
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
                    : const Text('Read this recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
