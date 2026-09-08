import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/router/routes.dart';
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
  String? _error;

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
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _error = 'That photo could not be opened. ($e)');
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
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _bytes;

    return Scaffold(
      appBar: AppBar(title: const Text('Photograph a page')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Fill the frame with the recipe. A whole page is fine -- two '
            'columns, a sidebar of ingredients, a photo of the dish. Anything '
            'it credits is saved with the recipe.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take a photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose a photo'),
                ),
              ),
            ],
          ),
          if (bytes != null) ...<Widget>[
            const SizedBox(height: 16),
            // Shown so the cook can see the page is in frame and legible
            // before paying for a model call on a blurred corner.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ],
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
                onPressed: _busy || bytes == null ? null : _submit,
                child: _busy
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
