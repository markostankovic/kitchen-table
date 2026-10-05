import 'dart:io' as io;

import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for `recipeImageCacheManagerProvider`'s cache, for any widget
/// test that pumps a recipe with a photo.
///
/// [files] maps a cache key (an object path) to what `getFileFromCache`
/// finds; anything else is a miss. A network fetch fails at once, the way a
/// test's `Image.network` always did (HTTP 400), so a loading spinner does
/// not keep `pumpAndSettle` from settling and no test makes a real request.
class FakeImageCache extends Fake implements BaseCacheManager {
  FakeImageCache([this.files = const <String, FileInfo>{}]);

  final Map<String, FileInfo> files;

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async => files[key];

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream<FileResponse>.error(
    const io.SocketException('no network in tests'),
  );
}

/// A cache entry over a real file on disk, for the offline-hit case.
///
/// `FileInfo` wants a `package:file` `File`, and that package is only a
/// transitive dependency here, so the file is made the way the cache itself
/// makes one -- through `IOFileSystem` -- with `path_provider`'s temporary
/// directory pointed at a real temp dir. Call it outside the fake-async zone
/// (`setUpAll`, or `tester.runAsync`): it does real IO.
Future<FileInfo> fakeCachedFile(String key) async {
  final io.Directory tmp = await io.Directory.systemTemp.createTemp('recipe');
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall call) async => tmp.path,
      );
  final file = await IOFileSystem('recipeImagesTest').createFile('photo.png');
  await file.writeAsBytes(_onePixelPng);
  return FileInfo(file, FileSource.Cache, DateTime(2100), key);
}

/// A 1x1 transparent PNG, so `Image.file` has something real to decode.
const List<int> _onePixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
