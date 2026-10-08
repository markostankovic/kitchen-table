import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/ingredients/ingredient_catalog_providers.dart';
import '../../../core/ingredients/widgets/ingredient_lines_editor.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/kitchen_colors.dart';
import '../../../core/widgets/app_action_bar.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_field_label.dart';
import '../../../core/widgets/app_section_heading.dart';
import '../../ingredients/domain/ingredient_line_parser.dart';
import '../../ingredients/domain/unit_catalog.dart';
import '../../recipes/domain/recipe_draft.dart';
import '../../recipes/domain/recipe_step.dart';
import '../application/import_confirm.dart';
import '../domain/parsed_recipe_draft.dart';
import '../application/import_providers.dart';
import '../domain/import_job.dart';

/// The confirm screen. D8 calls this "the quality mechanism for the whole
/// catalog", and since D42 took alias write-back away from the machine tiers
/// it is also the only thing that grows the catalog at all.
///
/// So it is built for speed, exactly as D8 asks: everything the server matched
/// is already applied, the lines worth a second look are marked, and Save is
/// one tap away. Editing the odd line out is the exception, not the workflow.
///
/// So the lines are read-only rows, and tapping one opens it into the editor
/// in place -- one at a time (D123). The list is the shared
/// [IngredientLinesEditor] in its review style, the same one the recipe
/// editor uses; there is no Done button any more (D159) -- a line closes when
/// another opens, on the keyboard's Next, or on ✕.
///
/// One screen serves three states, because the job it is watching moves
/// through them: waiting, failed, and ready to review.
class ImportReviewScreen extends ConsumerWidget {
  const ImportReviewScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<ImportJob> job = ref.watch(importJobProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewImportTitle)),
      body: job.when(
        loading: () => _Waiting(jobId: jobId, status: null),
        error: (Object e, _) =>
            _Failed(jobId: jobId, message: localizedErrorMessage(e, l10n)),
        data: (ImportJob value) => switch (value.status) {
          ImportJobStatus.failed => _Failed(
            jobId: jobId,
            // The server's own sentence, persisted in import_jobs so a job
            // can still say why days later -- l10n.failureImportUnreadable
            // reads the same ARB key the degenerate path of this job's own
            // throw site (import_confirm.dart) falls back to.
            message: value.errorMessage ?? l10n.failureImportUnreadable,
          ),
          // A job already saved. Reachable by pressing Back onto a finished
          // review, and better answered than crashed on.
          ImportJobStatus.done => _AlreadySaved(recipeId: value.recipeId),
          _ when !value.isReviewable =>
            _Waiting(jobId: jobId, status: value.status),
          _ => _ReviewBody(jobId: jobId),
        },
      ),
    );
  }
}

/// The review marker's width, named in DESIGN_SYSTEM. Private on purpose, as
/// in `ingredient_line_row.dart`: one number is not worth a shared constant.
const double _markerWidth = 3;

class _Waiting extends ConsumerStatefulWidget {
  const _Waiting({required this.jobId, required this.status});

  final String jobId;
  final ImportJobStatus? status;

  @override
  ConsumerState<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends ConsumerState<_Waiting> {
  bool _dismissing = false;

  /// No confirm, as in `_FailedState._dismiss`: nothing has been parsed yet,
  /// so nothing is lost. The model call already under way still runs and
  /// still counts against quota; the soft-deleted job is simply never shown.
  Future<void> _dismiss() async {
    setState(() => _dismissing = true);
    try {
      await ref.read(importRepositoryProvider).dismiss(widget.jobId);
      if (!mounted) return;
      const RecipesRoute().go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
      setState(() => _dismissing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    // AppEmptyState's rhythm, with a spinner where its icon would be.
    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.status == ImportJobStatus.processing
                        ? l10n.readingRecipeEllipsis
                        : l10n.queuedEllipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.importWaitingHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AppActionBar(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _dismissing ? null : _dismiss,
              child: Text(l10n.discardImportButton),
            ),
          ),
        ),
      ],
    );
  }
}

class _Failed extends ConsumerStatefulWidget {
  const _Failed({required this.jobId, required this.message});

  final String jobId;
  final String message;

  @override
  ConsumerState<_Failed> createState() => _FailedState();
}

class _FailedState extends ConsumerState<_Failed> {
  bool _dismissing = false;

  Future<void> _dismiss() async {
    setState(() => _dismissing = true);
    try {
      await ref.read(importRepositoryProvider).dismiss(widget.jobId);
      if (!mounted) return;
      const RecipesRoute().go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
      setState(() => _dismissing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // The server's own sentence. import_jobs stores the {error, message} pair
    // so a job can still say why days later. The icon is `outline`, not
    // `error`: a failed import is not validation. No confirm on the discard
    // either -- a failed parse has nothing left to lose.
    return AppEmptyState(
      icon: Icons.error_outline,
      title: widget.message,
      action: OutlinedButton(
        onPressed: _dismissing ? null : _dismiss,
        child: Text(l10n.discardImportButton),
      ),
    );
  }
}

class _AlreadySaved extends StatelessWidget {
  const _AlreadySaved({required this.recipeId});

  final String? recipeId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? id = recipeId;
    return AppEmptyState(
      icon: Icons.check_circle_outline,
      // Same key as this job's own throw-site fallback (D92) -- the sentence
      // is the same whether it comes from the failure vocabulary or from
      // reaching this screen after the fact.
      title: l10n.failureImportAlreadySaved,
      action: id == null
          ? null
          : FilledButton.tonal(
              onPressed: () => RecipeDetailRoute(id).go(context),
              child: Text(l10n.openRecipeButton),
            ),
    );
  }
}

class _ReviewBody extends ConsumerStatefulWidget {
  const _ReviewBody({required this.jobId});

  final String jobId;

  @override
  ConsumerState<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends ConsumerState<_ReviewBody> {
  bool _saving = false;
  bool _discarding = false;
  AppFailure? _failure;

  ImportConfirm get _confirm =>
      ref.read(importConfirmProvider(widget.jobId).notifier);

  bool get _busy => _saving || _discarding;

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _failure = null;
    });

    try {
      final String recipeId = await _confirm.save();
      if (!mounted) return;
      RecipeDetailRoute(recipeId).go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// The new line's id, read back from the draft for the list to open.
  int _insertLineAfter(int localId) {
    _confirm.insertLineAfter(localId);
    final List<RecipeDraftLine> lines =
        ref.read(importConfirmProvider(widget.jobId)).value?.draft.lines ??
        const <RecipeDraftLine>[];
    final int at =
        lines.indexWhere((RecipeDraftLine l) => l.localId == localId);
    return at < 0 || at + 1 >= lines.length
        ? lines.last.localId
        : lines[at + 1].localId;
  }

  int _addLine() {
    _confirm.addLine();
    return ref
        .read(importConfirmProvider(widget.jobId))
        .value!
        .draft
        .lines
        .last
        .localId;
  }

  /// `_FailedState._dismiss`, behind a confirm: a successful review has a
  /// whole recipe to lose.
  Future<void> _discard() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final KitchenColors kitchen = Theme.of(context).extension<KitchenColors>()!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.discardImportDialogTitle),
        content: Text(l10n.discardImportConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kitchen.destructive),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.discardButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _discarding = true);
    try {
      await ref.read(importRepositoryProvider).dismiss(widget.jobId);
      if (!mounted) return;
      const RecipesRoute().go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
      setState(() => _discarding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<ImportReview> review = ref.watch(
      importConfirmProvider(widget.jobId),
    );
    final IngredientLineParser? parser = ref.watch(lineParserProvider).value;
    final UnitCatalog? units = ref.watch(unitCatalogProvider).value;

    return review.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) =>
          AppErrorView(message: localizedErrorMessage(e, l10n)),
      data: (ImportReview value) => Column(
        children: <Widget>[
          Expanded(
            child: _buildForm(
              value.draft,
              value.needsAttention,
              parser,
              units,
              l10n,
            ),
          ),
          _buildActionBar(l10n),
        ],
      ),
    );
  }

  Widget _buildForm(
    RecipeDraft draft,
    Set<int> attention,
    IngredientLineParser? parser,
    UnitCatalog? units,
    AppLocalizations l10n,
  ) {
    final ThemeData theme = Theme.of(context);
    final int matched = draft.lines
        .where((RecipeDraftLine l) => l.isMatched)
        .length;
    final int total = draft.lines
        .where((RecipeDraftLine l) => l.rawText.trim().isNotEmpty)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: <Widget>[
        _Summary(
          matched: matched,
          total: total,
          attention: attention.length,
          l10n: l10n,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppFieldLabel(text: l10n.titleLabel),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: draft.title,
          style: theme.textTheme.bodyMedium,
          onChanged: _confirm.setTitle,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeading(text: l10n.ingredientsHeading),
        IngredientLinesEditor(
          lines: draft.lines,
          locale: draft.originalLocale,
          units: units,
          parser: parser,
          onReplace: _confirm.replaceLine,
          onRemove: _confirm.removeLine,
          onMoveLine: _confirm.moveLine,
          onMoveRun: _confirm.moveLines,
          onSetSections: _confirm.setSections,
          onInsertAfter: _insertLineAfter,
          onAdd: _addLine,
          review: true,
          flagged: attention,
        ),
        const SizedBox(height: AppSpacing.xl),
        _MethodCard(
          steps: draft.steps,
          l10n: l10n,
          onStepChanged: _confirm.setStepText,
          onAddStep: _confirm.addStep,
        ),
        const SizedBox(height: AppSpacing.md),
        _NotesCard(
          notes: draft.notes,
          l10n: l10n,
          onChanged: _confirm.setNotes,
        ),
      ],
    );
  }

  /// The bar itself is [AppActionBar]; only its two buttons are this
  /// screen's.
  Widget _buildActionBar(AppLocalizations l10n) {
    // Horizontal lg rather than the theme's xl: at 360dp each half is about
    // 158dp, and `Odbaci ovaj uvoz` would wrap at the default.
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
    );

    return AppActionBar(
      error: _failure?.localized(l10n),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: buttonPadding),
              onPressed: _busy ? null : _discard,
              child: Text(l10n.discardImportButton),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(padding: buttonPadding),
              onPressed: _busy ? null : _submit,
              child: _saving
                  ? const SizedBox.square(
                      dimension: AppSizes.iconInMeta,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveRecipeButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the machine managed, so the cook knows how much to read.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.matched,
    required this.total,
    required this.attention,
    required this.l10n,
  });

  final int matched;
  final int total;
  final int attention;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.importMatchedOfTotal(
                matched,
                l10n.ingredientsMatchedCount(total),
              ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: total == 0 ? 0 : matched / total,
              minHeight: AppSpacing.xs,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            if (attention > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  // The same 3px paprika signal the flagged rows carry --
                  // a signal, not a text colour, so the words stay neutral.
                  SizedBox(
                    width: _markerWidth,
                    height: AppSizes.iconInMeta,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: kitchen.reviewMarker),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.importWorthALook(attention),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Method, collapsed on open and expanded in place. The steps are rarely
/// what an import gets wrong, so they wait behind a tap -- and there is no
/// route, which is why the trailing icon is `expand_more` and not a chevron.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.steps,
    required this.l10n,
    required this.onStepChanged,
    required this.onAddStep,
  });

  final List<RecipeDraftStep> steps;
  final AppLocalizations l10n;
  final void Function(int localId, String text) onStepChanged;
  final VoidCallback onAddStep;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        initiallyExpanded: false,
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        iconColor: theme.colorScheme.outline,
        collapsedIconColor: theme.colorScheme.outline,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Text(l10n.methodHeading, style: theme.textTheme.titleMedium),
        subtitle: Text(
          // Headings and notes are not steps (D153).
          l10n.importStepsCount(
            steps
                .where((RecipeDraftStep s) => s.kind == RecipeStepKind.step)
                .length,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: <Widget>[
          for (final (int index, RecipeDraftStep step) in steps.indexed)
            Padding(
              key: ValueKey<int>(step.localId),
              padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.sm),
              child: TextFormField(
                initialValue: step.text,
                maxLines: null,
                style: theme.textTheme.bodyMedium,
                // A kind icon, so an imported heading or note doesn't read
                // as one more step. A step's field stays bare.
                decoration: switch (step.kind) {
                  RecipeStepKind.step => const InputDecoration(),
                  RecipeStepKind.heading => InputDecoration(
                    prefixIcon: Icon(
                      Icons.title,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  RecipeStepKind.note => InputDecoration(
                    prefixIcon: Icon(
                      Icons.sticky_note_2_outlined,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                },
                onChanged: (String v) => onStepChanged(step.localId, v),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddStep,
              icon: const Icon(Icons.add),
              label: Text(l10n.addStepButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// The recipe's end note (D153), the same collapsed card as Method and for
/// the same reason: it expands in place, so `expand_more`, no chevron, no
/// route. The subline is the note's first words, rebuilt from the draft as
/// the cook types.
class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.notes,
    required this.l10n,
    required this.onChanged,
  });

  final String? notes;
  final AppLocalizations l10n;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String summary =
        (notes ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        initiallyExpanded: false,
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        iconColor: theme.colorScheme.outline,
        collapsedIconColor: theme.colorScheme.outline,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Text(
          l10n.recipeNotesHeading,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          summary.isEmpty ? l10n.importNotesNoneFound : summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: <Widget>[
          TextFormField(
            initialValue: notes ?? '',
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: null,
            style: theme.textTheme.bodyMedium,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
