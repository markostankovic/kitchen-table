import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/app_error_view.dart';
import '../application/translation_reviewer.dart';
import '../domain/recipe_step.dart';
import '../domain/translation_review_draft.dart';

/// Edit and approve a machine translation (Phase 3, part 3).
///
/// Every field pairs the recipe's own original text, read-only, with the
/// editable translation directly beneath it -- stacked rather than side by
/// side, because two columns of prose at phone width is unreadable, and the
/// reviewer's own eye movement is "read the line above, fix the line below
/// it".
///
/// Steps are a FIXED-length list: one editable field per source step, in
/// source order, keyed by [RecipeStep.position]. There is deliberately no
/// drag handle, no remove button and no "Add step" here -- unlike
/// [RecipeEditScreen]'s step section, which this screen otherwise resembles.
/// A reviewer may correct what a step says; they may not add, drop or
/// reorder one, because `review_recipe_translation` refuses a step count or
/// position that does not already match the row (D80), and this screen's
/// job is to make that the only thing that can happen, not merely the only
/// thing the server allows.
///
/// No ingredient editor anywhere on this screen. Ingredient lines are never
/// translated per recipe (D1, D80) -- they render from the bilingual
/// catalog at read time, so there is nothing here for them to be.
///
/// This feature's second localized screen (D77's one-screen-at-a-time
/// rhythm) -- the first being the recipe detail screen this one is reached
/// from.
class TranslationReviewScreen extends ConsumerStatefulWidget {
  const TranslationReviewScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  ConsumerState<TranslationReviewScreen> createState() =>
      _TranslationReviewScreenState();
}

class _TranslationReviewScreenState
    extends ConsumerState<TranslationReviewScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;
  AppFailure? _failure;

  late final String _locale = ref.read(appLocaleProvider).languageCode;

  TranslationReviewer get _reviewer => ref.read(
        translationReviewerProvider(widget.recipeId, locale: _locale)
            .notifier,
      );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _failure = null;
    });

    try {
      await _reviewer.save();
      if (!mounted) return;
      Navigator.of(context).pop();
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
    final AsyncValue<TranslationReviewDraft> draft = ref.watch(
      translationReviewerProvider(widget.recipeId, locale: _locale),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTranslationTitle)),
      body: draft.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) =>
            AppErrorView(message: localizedErrorMessage(e, l10n)),
        data: (TranslationReviewDraft d) => _buildForm(d, l10n),
      ),
      bottomNavigationBar: draft.hasValue ? _buildSaveBar(context) : null,
    );
  }

  Widget _buildForm(TranslationReviewDraft draft, AppLocalizations l10n) {
    final String sourceLanguageName = draft.sourceLocale == 'sr'
        ? l10n.languageSerbian
        : l10n.languageEnglish;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          _OriginalText(
            label: l10n.originalTextLabel(sourceLanguageName),
            text: draft.sourceTitle,
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: draft.title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.titleLabel,
              border: const OutlineInputBorder(),
            ),
            validator: (String? value) =>
                (value ?? '').trim().isEmpty ? l10n.titleRequiredError : null,
            onChanged: _reviewer.setTitle,
          ),
          if (draft.sourceDescription != null) ...<Widget>[
            const SizedBox(height: 16),
            _OriginalText(
              label: l10n.originalTextLabel(sourceLanguageName),
              text: draft.sourceDescription!,
            ),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: draft.description ?? '',
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: _reviewer.setDescription,
            ),
          ],
          for (final (RecipeStep source, RecipeStep translated)
              in draft.pairedSteps) ...<Widget>[
            const SizedBox(height: 16),
            _OriginalText(
              label: l10n.originalTextLabel(sourceLanguageName),
              text: source.text,
            ),
            const SizedBox(height: 4),
            TextFormField(
              key: ValueKey<int>(translated.position),
              initialValue: translated.text,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.stepLabel(translated.position + 1),
                border: const OutlineInputBorder(),
              ),
              onChanged: (String value) =>
                  _reviewer.setStepText(translated.position, value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveBar(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SafeArea(
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
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.saveReviewButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// The recipe's own text for one field, read-only -- reference, not
/// something to be typed over.
class _OriginalText extends StatelessWidget {
  const _OriginalText({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
