import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/router/routes.dart';
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
  String? _error;

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
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _error = 'That photo could not be opened. ($e)');
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
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<RecipeDraft> draft =
        ref.watch(recipeEditorProvider(widget.recipeId));

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New recipe' : 'Edit recipe')),
      body: draft.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not open this recipe.\n\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: _buildForm,
      ),
      bottomNavigationBar: draft.hasValue ? _buildSaveBar(context) : null,
    );
  }

  Widget _buildForm(RecipeDraft draft) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          _PhotoField(
            pickedImage: _pickedImage,
            existingImageUrl:
                draft.imagePath == null ? null : draft.source?.imageUrl,
            onPick: _pickImage,
            onRemove: _removeImage,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: draft.title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            validator: (String? value) =>
                (value ?? '').trim().isEmpty ? 'Enter a title.' : null,
            onChanged: _editor.setTitle,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: draft.description ?? '',
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            onChanged: _editor.setDescription,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _NumberField(
                  label: 'Servings',
                  value: draft.servings,
                  // The table's check is `servings > 0`; a recipe for nobody
                  // is not a thing.
                  minimum: 1,
                  onChanged: _editor.setServings,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  label: 'Prep (min)',
                  value: draft.prepMinutes,
                  minimum: 0,
                  onChanged: _editor.setPrepMinutes,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  label: 'Cook (min)',
                  value: draft.cookMinutes,
                  minimum: 0,
                  onChanged: _editor.setCookMinutes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 'sr' and 'en' are the only values the column allows, so this is a
          // closed choice rather than a text field.
          _FieldLabel(text: 'Written in'),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'sr', label: Text('Srpski')),
              ButtonSegment<String>(value: 'en', label: Text('English')),
            ],
            selected: <String>{draft.originalLocale},
            onSelectionChanged: (Set<String> selection) =>
                _editor.setLocale(selection.first),
          ),
          const SizedBox(height: 16),
          _FieldLabel(text: 'Status'),
          const SizedBox(height: 6),
          SegmentedButton<RecipeStatus>(
            segments: const <ButtonSegment<RecipeStatus>>[
              ButtonSegment<RecipeStatus>(
                  value: RecipeStatus.draft, label: Text('Draft')),
              ButtonSegment<RecipeStatus>(
                  value: RecipeStatus.tested, label: Text('Tested')),
            ],
            selected: <RecipeStatus>{draft.status},
            onSelectionChanged: (Set<RecipeStatus> selection) =>
                _editor.setStatus(selection.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: draft.tags.join(', '),
            decoration: const InputDecoration(
              labelText: 'Tags',
              helperText: 'Separated by commas',
              border: OutlineInputBorder(),
            ),
            onChanged: (String value) => _editor.setTags(_parseTags(value)),
          ),
          const SizedBox(height: 24),
          _SectionHeading(text: 'Ingredients'),
          const SizedBox(height: 8),
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
              label: const Text('Add ingredient'),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeading(text: 'Steps'),
          const SizedBox(height: 8),
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
                  hintText: 'Step ${index + 1}',
                  maxLines: 3,
                  onChanged: (String value) =>
                      _editor.setStepText(step.localId, value),
                  onRemove: () => _editor.removeStep(step.localId),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _editor.addStep,
              icon: const Icon(Icons.add),
              label: const Text('Add step'),
            ),
          ),
        ],
      ),
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
                  : const Text('Save'),
            ),
          ],
        ),
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
  });

  final RecipeImageUpload? pickedImage;
  final String? existingImageUrl;
  final ValueChanged<ImageSource> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = pickedImage?.bytes;
    final bool hasPhoto = bytes != null || existingImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (hasPhoto)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
        if (hasPhoto) const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
            if (hasPhoto) ...<Widget>[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove photo',
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// One draggable, removable row of the ingredient or step list.
class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.index,
    required this.initialValue,
    required this.hintText,
    required this.onChanged,
    required this.onRemove,
    this.maxLines = 1,
    super.key,
  });

  final int index;
  final String initialValue;
  final String hintText;
  final int maxLines;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.drag_handle),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: initialValue,
              maxLines: maxLines,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: hintText,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// A whole-number field that reports null for "not given".
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.minimum,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final int minimum;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      // Every one of these columns is nullable, so blank is valid. Anything
      // else has to survive the table's check constraint.
      validator: (String? raw) {
        final String text = (raw ?? '').trim();
        if (text.isEmpty) return null;
        final int? parsed = int.tryParse(text);
        if (parsed == null) return 'Whole number.';
        if (parsed < minimum) return 'At least $minimum.';
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelLarge);
}
