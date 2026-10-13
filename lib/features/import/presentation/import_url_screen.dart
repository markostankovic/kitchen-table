import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/household/current_household.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_field_label.dart';
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
      final String? householdId =
          await ref.read(currentHouseholdIdProvider.future);
      if (householdId == null) {
        throw const NotFoundFailure(
            message: 'You are not in a household yet.',
            code: FailureCode.noHousehold);
      }
      final String jobId = await ref
          .read(importRepositoryProvider)
          .createFromUrl(_url.text, householdId: householdId);
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
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importUrlTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Text(
            l10n.importUrlBody,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppFieldLabel(text: l10n.linkFieldLabel),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            // Not autofocused when a share prefilled it: the cook should see
            // the link that arrived and the button to read it, not a keyboard.
            autofocus: widget.initialUrl == null,
            onSubmitted: (_) => _submitting ? null : _submit(),
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(hintText: 'https://…'),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_failure != null) ...<Widget>[
            Text(
              _failure!.localized(l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          // Inline under the field rather than on a pinned bar, which would
          // sit under the keyboard (D137's onboarding shape).
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox.square(
                    dimension: AppSizes.iconInMeta,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.readRecipeButton),
          ),
        ],
      ),
    );
  }
}
