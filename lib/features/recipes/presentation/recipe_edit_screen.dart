import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/language_labels.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/kitchen_colors.dart';
import '../../../core/widgets/app_action_bar.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_field_label.dart';
import '../../../core/widgets/app_section_heading.dart';
import '../application/recipe_editor.dart';
import '../domain/recipe.dart';
import '../domain/recipe_draft.dart';
import '../domain/recipe_image_upload.dart';
import '../../../core/ingredients/widgets/ingredient_line_field.dart';

/// Create or edit one recipe.
///
/// The same screen for both: [recipeId] is null for a recipe that does not
/// exist yet, and that null is also the editor provider's family key.
///
/// Ingredient lines are raw-text-first. The field holds exactly what the cook
/// typed and that is what `raw_text` stores; quantity, unit and a matched
/// ingredient are worked out from it and are all allowed to come back empty
/// (rule 3). See [IngredientLineField] for how. Steps are plain text.
///
/// Text fields are seeded with `initialValue` and report through `onChanged`
/// rather than each owning a `TextEditingController`, which is a departure
/// from the household forms. Those have a fixed set of fields; this one has a
/// list the user adds to, removes from and reorders, and a controller per row
/// would need a lifecycle -- created on insert, disposed on delete, kept
/// straight across a drag -- for no gain. The draft is the single source of
/// truth either way.
class RecipeEditScreen extends ConsumerStatefulWidget {
  const RecipeEditScreen({this.recipeId, super.key});

  final String? recipeId;

  @override
  ConsumerState<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends ConsumerState<RecipeEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;
  bool _translating = false;

  /// Either an already-localized string -- image_picker's own platform
  /// exception, outside the [FailureCode] mechanism entirely -- or an
  /// [AppFailure], localized lazily in [_buildSaveBar].
  Object? _error;

  /// A photo picked but not yet uploaded. Held here, not on the draft (D48):
  /// nothing is written to Storage until `_submit()` calls `save(image: ...)`,
  /// so abandoning this screen after picking leaves no orphan object.
  RecipeImageUpload? _pickedImage;

  /// Sized for a photo that is only ever looked at, never read by a model --
  /// smaller than `ImportPhotoScreen`'s 1600/85, which was chosen for a vision
  /// model's recommended long edge.
  static const double _maxEdge = 1200;
  static const int _quality = 85;

  bool get _isNew => widget.recipeId == null;

  RecipeEditor get _editor =>
      ref.read(recipeEditorProvider(widget.recipeId).notifier);

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: _maxEdge,
        maxHeight: _maxEdge,
        imageQuality: _quality,
      );
      if (file == null || !mounted) return;

      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        // image_picker re-encodes to JPEG whenever it resizes, which it
        // always does here -- so the extension follows what was asked for
        // rather than what came off the camera. A HEIC from an iPhone
        // arrives as JPEG.
        _pickedImage = RecipeImageUpload(
          bytes: bytes,
          contentType: 'image/jpeg',
          extension: 'jpg',
        );
      });
    } on Exception catch (_) {
      if (!mounted) return;
      setState(
          () => _error = AppLocalizations.of(context).photoCouldNotBeOpened);
    }
  }

  /// Clears the photo. Immediate rather than deferred to save: it updates
  /// [RecipeDraft.imagePath] on the spot, so the preview and a save that
  /// happens without touching the photo again both agree there is none.
  void _removeImage() {
    setState(() => _pickedImage = null);
    _editor.setImagePath(null);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final String recipeId = await _editor.save(image: _pickedImage);
      if (!mounted) return;
      // A brand-new recipe has no page to go back to, so open the one that was
      // just written. An edit returns to the detail page it came from, which
      // re-reads because save() invalidated it.
      if (_isNew) {
        RecipeDetailRoute(recipeId).go(context);
      } else {
        context.pop();
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Saves the draft and translates it in one tap -- see
  /// `RecipeEditor.saveAndTranslate`'s own doc comment for why the save
  /// happens first rather than the action being disabled while dirty (D106).
  /// Errors land on the same `_error` surface `_submit()` uses; there is no
  /// second error UI for a failure that happened one step later.
  Future<void> _translate(AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _translating = true;
      _error = null;
    });

    try {
      final String target =
          await _editor.saveAndTranslate(image: _pickedImage);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.recipeTranslatedSnackbar(languageName(l10n, target))),
      ));
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<RecipeDraft> draft =
        ref.watch(recipeEditorProvider(widget.recipeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.newRecipeTitle : l10n.editRecipeTitle),
        actions: <Widget>[
          if (draft.value?.canTranslate ?? false)
            IconButton(
              icon: const Icon(Icons.translate),
              tooltip: l10n.translateAction(
                languageName(l10n, draft.value!.translationTargetLocale),
              ),
              onPressed:
                  _saving || _translating ? null : () => _translate(l10n),
            ),
        ],
      ),
      body: draft.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) =>
            AppErrorView(message: localizedErrorMessage(e, l10n)),
        data: (RecipeDraft d) => _buildForm(d, l10n),
      ),
      bottomNavigationBar: draft.hasValue ? _buildSaveBar(l10n) : null,
    );
  }

  Widget _buildForm(RecipeDraft draft, AppLocalizations l10n) {
    final TextStyle? fieldStyle = Theme.of(context).textTheme.bodyMedium;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: <Widget>[
          _PhotoField(
            pickedImage: _pickedImage,
            existingImageUrl:
                draft.imagePath == null ? null : draft.source?.imageUrl,
            onPick: _pickImage,
            onRemove: _removeImage,
            l10n: l10n,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppFieldLabel(text: l10n.titleLabel),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: draft.title,
            textCapitalization: TextCapitalization.sentences,
            style: fieldStyle,
            validator: (String? value) =>
                (value ?? '').trim().isEmpty ? l10n.titleRequiredError : null,
            onChanged: _editor.setTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppFieldLabel(text: l10n.descriptionLabel),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: draft.description ?? '',
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            style: fieldStyle,
            onChanged: _editor.setDescription,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Labels in a row of their own, bottom-aligned, above a row of the
          // fields: at 360dp each column is about 101dp and `Priprema (min)`
          // in titleSmall can wrap. A wrapped label then pushes all three
          // fields down together, so they always share one line.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: AppFieldLabel(text: l10n.servingsFieldLabel)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: AppFieldLabel(text: l10n.prepMinutesFieldLabel)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: AppFieldLabel(text: l10n.cookMinutesFieldLabel)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _NumberField(
                  value: draft.servings,
                  // The table's check is `servings > 0`; a recipe for nobody
                  // is not a thing.
                  minimum: 1,
                  onChanged: _editor.setServings,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumberField(
                  value: draft.prepMinutes,
                  minimum: 0,
                  onChanged: _editor.setPrepMinutes,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumberField(
                  value: draft.cookMinutes,
                  minimum: 0,
                  onChanged: _editor.setCookMinutes,
                  l10n: l10n,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // 'sr' and 'en' are the only values the column allows, so this is a
          // closed choice rather than a text field.
          AppFieldLabel(text: l10n.writtenInFieldLabel),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'sr', label: Text('Srpski')),
              ButtonSegment<String>(value: 'en', label: Text('English')),
            ],
            selected: <String>{draft.originalLocale},
            onSelectionChanged: (Set<String> selection) =>
                _editor.setLocale(selection.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppFieldLabel(text: l10n.statusFieldLabel),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<RecipeStatus>(
            segments: <ButtonSegment<RecipeStatus>>[
              ButtonSegment<RecipeStatus>(
                  value: RecipeStatus.draft, label: Text(l10n.draftChipLabel)),
              ButtonSegment<RecipeStatus>(
                  value: RecipeStatus.tested,
                  label: Text(l10n.testedStatusLabel)),
            ],
            selected: <RecipeStatus>{draft.status},
            onSelectionChanged: (Set<RecipeStatus> selection) =>
                _editor.setStatus(selection.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppFieldLabel(text: l10n.tagsFieldLabel),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: draft.tags.join(', '),
            style: fieldStyle,
            decoration: InputDecoration(helperText: l10n.tagsHelperText),
            onChanged: (String value) => _editor.setTags(_parseTags(value)),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeading(text: l10n.ingredientsHeading),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: _editor.reorderLines,
            children: <Widget>[
              for (final (int index, RecipeDraftLine line)
                  in draft.lines.indexed)
                IngredientLineField(
                  key: ValueKey<int>(line.localId),
                  index: index,
                  line: line,
                  locale: draft.originalLocale,
                  onChanged: _editor.replaceLine,
                  onRemove: () => _editor.removeLine(line.localId),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _editor.addLine,
              icon: const Icon(Icons.add),
              label: Text(l10n.addIngredientButton),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeading(text: l10n.stepsHeading),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: _editor.reorderSteps,
            children: <Widget>[
              for (final (int index, RecipeDraftStep step)
                  in draft.steps.indexed)
                _EditableRow(
                  key: ValueKey<int>(step.localId),
                  index: index,
                  initialValue: step.text,
                  label: l10n.stepLabel(index + 1),
                  maxLines: 3,
                  onChanged: (String value) =>
                      _editor.setStepText(step.localId, value),
                  onRemove: () => _editor.removeStep(step.localId),
                  removeTooltip: l10n.removeTooltip,
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _editor.addStep,
              icon: const Icon(Icons.add),
              label: Text(l10n.addStepButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(AppLocalizations l10n) {
    return AppActionBar(
      error: _error == null ? null : _errorText(l10n),
      child: FilledButton(
        onPressed: _saving ? null : _submit,
        child: _saving
            ? const SizedBox.square(
                dimension: AppSizes.iconInMeta,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.saveButton),
      ),
    );
  }

  /// Blank entries are dropped rather than saved, so a trailing comma while
  /// typing does not become a tag.
  static List<String> _parseTags(String value) => value
      .split(',')
      .map((String tag) => tag.trim())
      .where((String tag) => tag.isNotEmpty)
      .toList(growable: false);

  /// [_error] is either a plain, already-localized string or an [AppFailure]
  /// to localize lazily -- see its own doc comment.
  String _errorText(AppLocalizations l10n) {
    final Object error = _error!;
    return error is AppFailure ? error.localized(l10n) : error as String;
  }
}

/// The recipe's photo: pick from camera or gallery, preview, remove.
///
/// [pickedImage] takes priority over [existingImageUrl] -- a photo just
/// picked has not reached the server yet, so there is no signed URL for it,
/// and showing the in-memory bytes is the only way to preview it at all.
class _PhotoField extends StatelessWidget {
  const _PhotoField({
    required this.pickedImage,
    required this.existingImageUrl,
    required this.onPick,
    required this.onRemove,
    required this.l10n,
  });

  final RecipeImageUpload? pickedImage;
  final String? existingImageUrl;
  final ValueChanged<ImageSource> onPick;
  final VoidCallback onRemove;
  final AppLocalizations l10n;

  /// The empty well's `image` icon. The frame's value, and the editor is its
  /// only user, so no token.
  static const double _wellIcon = 32;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Uint8List? bytes = pickedImage?.bytes;
    final bool hasPhoto = bytes != null || existingImageUrl != null;

    final Widget cameraButton = FilledButton.tonalIcon(
      onPressed: () => onPick(ImageSource.camera),
      icon: const Icon(Icons.camera_alt_outlined),
      label: Text(l10n.cameraButton),
    );
    final Widget galleryButton = FilledButton.tonalIcon(
      onPressed: () => onPick(ImageSource.gallery),
      icon: const Icon(Icons.photo_library_outlined),
      label: Text(l10n.galleryButton),
    );

    // One 16:9 shape whether empty or filled, so picking a photo does not
    // move the form below it.
    if (!hasPhoto) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.image_outlined,
                  size: _wellIcon,
                  color: scheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                // A Wrap, not a Row: side by side at any phone width in
                // either language, but stacked rather than overflowing at a
                // large text scale.
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[cameraButton, galleryButton],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : Image.network(
                    existingImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? progress) =>
                        progress == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator()),
                    errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined)),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(child: cameraButton),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: galleryButton),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: l10n.removePhotoTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
          ],
        ),
      ],
    );
  }
}

/// One labelled, draggable, removable step row.
class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.index,
    required this.initialValue,
    required this.label,
    required this.onChanged,
    required this.onRemove,
    required this.removeTooltip,
    this.maxLines = 1,
    super.key,
  });

  final int index;
  final String initialValue;
  final String label;
  final int maxLines;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;
  final String removeTooltip;

  @override
  Widget build(BuildContext context) {
    final KitchenColors kitchen =
        Theme.of(context).extension<KitchenColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            // Indented past the grip, so the label sits over the field.
            padding: const EdgeInsets.only(
              left: AppSizes.grip + AppSpacing.xs,
            ),
            child: AppFieldLabel(text: label),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(
                    Icons.drag_indicator,
                    size: AppSizes.grip,
                    color: kitchen.dragHandle,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: initialValue,
                  maxLines: maxLines,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context).textTheme.bodyMedium,
                  onChanged: onChanged,
                ),
              ),
              IconButton(
                tooltip: removeTooltip,
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A whole-number field that reports null for "not given".
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.value,
    required this.minimum,
    required this.onChanged,
    required this.l10n,
  });

  final int? value;
  final int minimum;
  final ValueChanged<int?> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      keyboardType: TextInputType.number,
      style: Theme.of(context).textTheme.bodyMedium,
      // Every one of these columns is nullable, so blank is valid. Anything
      // else has to survive the table's check constraint.
      validator: (String? raw) {
        final String text = (raw ?? '').trim();
        if (text.isEmpty) return null;
        final int? parsed = int.tryParse(text);
        if (parsed == null) return l10n.wholeNumberError;
        if (parsed < minimum) return l10n.atLeastError(minimum);
        return null;
      },
      onChanged: (String raw) {
        final String text = raw.trim();
        if (text.isEmpty) {
          onChanged(null);
          return;
        }
        final int? parsed = int.tryParse(text);
        // An unparseable value is left alone rather than written as null: the
        // validator will stop the save, and clobbering the draft mid-keystroke
        // would lose what was there.
        if (parsed != null && parsed >= minimum) onChanged(parsed);
      },
    );
  }
}
