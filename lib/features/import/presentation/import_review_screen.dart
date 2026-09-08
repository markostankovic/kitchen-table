import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/ingredients/widgets/ingredient_line_field.dart';
import '../../../core/router/routes.dart';
import '../../recipes/domain/recipe_draft.dart';
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
/// One screen serves three states, because the job it is watching moves
/// through them: waiting, failed, and ready to review.
class ImportReviewScreen extends ConsumerWidget {
  const ImportReviewScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ImportJob> job = ref.watch(importJobProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Review import')),
      body: job.when(
        loading: () => const _Waiting(status: null),
        error: (Object e, _) => _Failed(
          jobId: jobId,
          message: e is AppFailure ? e.message : 'Could not load that import.',
        ),
        data: (ImportJob value) => switch (value.status) {
          ImportJobStatus.failed => _Failed(
              jobId: jobId,
              message: value.errorMessage ?? 'That import could not be read.',
            ),
          // A job already saved. Reachable by pressing Back onto a finished
          // review, and better answered than crashed on.
          ImportJobStatus.done => _AlreadySaved(recipeId: value.recipeId),
          _ when !value.isReviewable => _Waiting(status: value.status),
          _ => _ReviewBody(jobId: jobId),
        },
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.status});

  final ImportJobStatus? status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            status == ImportJobStatus.processing
                ? 'Reading the recipe…'
                : 'Queued…',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This takes a few seconds. You can leave and come back.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _dismissing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline,
                size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            // The server's own sentence. import_jobs stores the {error, message}
            // pair so a job can still say why days later.
            Text(widget.message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _dismissing ? null : _dismiss,
              child: const Text('Discard this import'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadySaved extends StatelessWidget {
  const _AlreadySaved({required this.recipeId});

  final String? recipeId;

  @override
  Widget build(BuildContext context) {
    final String? id = recipeId;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('This import has already been saved.'),
            if (id != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => RecipeDetailRoute(id).go(context),
                child: const Text('Open the recipe'),
              ),
            ],
          ],
        ),
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
  String? _error;

  ImportConfirm get _confirm =>
      ref.read(importConfirmProvider(widget.jobId).notifier);

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final String recipeId = await _confirm.save();
      if (!mounted) return;
      RecipeDetailRoute(recipeId).go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ImportReview> review =
        ref.watch(importConfirmProvider(widget.jobId));

    return review.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            e is AppFailure ? e.message : 'Could not read that import.\n\n$e',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (ImportReview value) => Column(
        children: <Widget>[
          Expanded(child: _buildForm(value.draft, value.needsAttention)),
          _buildSaveBar(context),
        ],
      ),
    );
  }

  Widget _buildForm(RecipeDraft draft, Set<int> attention) {
    final int matched =
        draft.lines.where((RecipeDraftLine l) => l.isMatched).length;
    final int total =
        draft.lines.where((RecipeDraftLine l) => l.rawText.trim().isNotEmpty)
            .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: <Widget>[
        _Summary(matched: matched, total: total, attention: attention.length),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: draft.title,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Title',
          ),
          onChanged: _confirm.setTitle,
        ),
        const SizedBox(height: 24),
        Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // The same scaffolding as the recipe editor, and it has to stay the
        // same: IngredientLineField emits a ReorderableDragStartListener, so
        // it asserts outside a ReorderableListView, and it supplies its own
        // handle, so the default ones are off.
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: _confirm.reorderLines,
          children: <Widget>[
            for (final (int index, RecipeDraftLine line) in draft.lines.indexed)
              Container(
                key: ValueKey<int>(line.localId),
                decoration: attention.contains(line.localId)
                    ? BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 3,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      )
                    : null,
                child: IngredientLineField(
                  index: index,
                  line: line,
                  locale: draft.originalLocale,
                  onChanged: _confirm.replaceLine,
                  onRemove: () => _confirm.removeLine(line.localId),
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _confirm.addLine,
            icon: const Icon(Icons.add),
            label: const Text('Add ingredient'),
          ),
        ),
        const SizedBox(height: 16),
        Text('Method', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final RecipeDraftStep step in draft.steps)
          Padding(
            key: ValueKey<int>(step.localId),
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              initialValue: step.text,
              maxLines: null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (String v) => _confirm.setStepText(step.localId, v),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _confirm.addStep,
            icon: const Icon(Icons.add),
            label: const Text('Add step'),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveBar(BuildContext context) {
    return SafeArea(
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
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save recipe'),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the machine managed, in one line, so the cook knows how much to read.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.matched,
    required this.total,
    required this.attention,
  });

  final int matched;
  final int total;
  final int attention;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            const Icon(Icons.auto_awesome_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('$matched of $total ingredients matched'),
                  if (attention > 0)
                    Text(
                      '$attention worth a look before saving',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
