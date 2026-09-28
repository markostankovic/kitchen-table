import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_action_bar.dart';
import '../application/import_providers.dart';

/// Photograph a cookbook page and let a vision model read it (D15).
///
/// Picking happens here and uploading happens in `data/`: the screen hands the
/// repository bytes and never lets `image_picker` past the presentation layer.
class ImportPhotoScreen extends ConsumerStatefulWidget {
  const ImportPhotoScreen({super.key});

  @override
  ConsumerState<ImportPhotoScreen> createState() => _ImportPhotoScreenState();
}

class _ImportPhotoScreenState extends ConsumerState<ImportPhotoScreen> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _bytes;
  String? _extension;
  String? _contentType;

  bool _busy = false;

  /// Either an already-localized string -- image_picker's own platform
  /// exception, outside the [FailureCode] mechanism entirely -- or an
  /// [AppFailure], localized lazily in [build].
  Object? _error;

  /// Downscaled at the picker, not after.
  ///
  /// 1600px is just above the vision model's recommended 1568px long edge, and
  /// far under its 5 MB ceiling once JPEG-encoded. A phone's 12-megapixel
  /// original is mostly detail the model cannot use, and every byte of it
  /// would be uploaded over somebody's mobile connection first.
  static const double _maxEdge = 1600;
  static const int _quality = 85;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });

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
        _bytes = bytes;
        // image_picker re-encodes to JPEG whenever it resizes, which it always
        // does here -- so the extension follows what we asked for rather than
        // what came off the camera. A HEIC from an iPhone arrives as JPEG.
        _extension = 'jpg';
        _contentType = 'image/jpeg';
      });
    } on Exception catch (_) {
      if (!mounted) return;
      setState(
          () => _error = AppLocalizations.of(context).photoCouldNotBeOpened);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final Uint8List? bytes = _bytes;
    if (bytes == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Two steps, and the first is the slow one: the upload happens under the
      // cook's finger, and only then does the job exist to be polled.
      final String path =
          await ref.read(importRepositoryProvider).uploadImportPhoto(
                bytes,
                contentType: _contentType ?? 'image/jpeg',
                extension: _extension ?? 'jpg',
              );
      final String jobId =
          await ref.read(importRepositoryProvider).createFromPhoto(path);
      if (!mounted) return;
      ImportReviewRoute(jobId).go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Uint8List? bytes = _bytes;
    // Horizontal lg rather than the theme's xl, as on the import review
    // (D123): each half is about 183dp on the Galaxy and 160dp at 360dp.
    // Part 7's walk found `Choose a photo` / `Izaberi fotografiju` wrapping
    // at the default; padding alone fixed the English but not the Serbian,
    // so the labels became `Camera` / `Gallery`, the editor's own photo
    // picker's words.
    final ButtonStyle pickerStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importPhotoTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Text(
            l10n.importPhotoBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  style: pickerStyle,
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.takePhotoButton),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  style: pickerStyle,
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.choosePhotoButton),
                ),
              ),
            ],
          ),
          if (bytes != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            // Shown so the cook can see the page is in frame and legible
            // before paying for a model call on a blurred corner.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ],
        ],
      ),
      bottomNavigationBar: AppActionBar(
        error: _error == null ? null : _errorText(l10n),
        child: FilledButton(
          onPressed: _busy || bytes == null ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: AppSizes.iconInMeta,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.readRecipeButton),
        ),
      ),
    );
  }

  /// [_error] is either a plain, already-localized string or an [AppFailure]
  /// to localize lazily -- see its own doc comment.
  String _errorText(AppLocalizations l10n) {
    final Object error = _error!;
    return error is AppFailure ? error.localized(l10n) : error as String;
  }
}
