import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../images/recipe_image_cache.dart';

/// A recipe's photo, through the disk cache in `recipe_image_cache.dart`.
///
/// Every recipe photo goes through here -- the card's thumbnail, the detail
/// screen's well, the editor's preview of the photo already saved -- so all
/// three share one cache and one key: the Storage object [path], not the
/// signed [url]. A re-signed URL is the same key, so a pull to refresh or a
/// relaunch is a hit rather than a download, and the in-memory image cache
/// agrees (`CachedNetworkImageProvider` compares by key).
///
/// No eviction: a replaced photo is always a new path (`uploadImage` never
/// upserts), so it is always a new key. The one rare case that cannot be
/// told apart is a row whose object was deleted out from under it -- that
/// may keep showing its last cached copy, which is acceptable.
///
/// A [url] that goes away while the [path] stays -- a pull to refresh emits
/// the cached list, unsigned (D131), before the signed one -- keeps the last
/// URL this widget had for that path. The provider is keyed by path, so that
/// URL is a memory or disk hit and never a download, even once it has
/// expired; dropping it would flash every thumbnail to its placeholder for
/// the length of the refresh.
///
/// With no [url] and none remembered -- a cold start offline, or a signing
/// that failed (D131) -- the cache is still asked for the [path], and only a
/// miss falls back to [placeholder]. A bare path is never fetched from the
/// network: it is not a URL, and the bucket is private (D48).
///
/// [decodeWidth] decodes the image at that many physical pixels wide, aspect
/// ratio kept; the caller picks it, since only the caller knows how big the
/// photo is drawn. Null decodes at full size.
class RecipePhoto extends ConsumerStatefulWidget {
  const RecipePhoto({
    required this.path,
    required this.placeholder,
    this.url,
    this.fit = BoxFit.cover,
    this.decodeWidth,
    this.loading,
    super.key,
  });

  final String path;
  final String? url;
  final BoxFit fit;
  final int? decodeWidth;

  /// Shown on a miss, on an error, and while loading when [loading] is null.
  final WidgetBuilder placeholder;
  final WidgetBuilder? loading;

  @override
  ConsumerState<RecipePhoto> createState() => _RecipePhotoState();
}

class _RecipePhotoState extends ConsumerState<RecipePhoto> {
  /// The offline lookup, held so a rebuild does not query the cache again.
  /// Only made when there is no URL, and remade when the path changes.
  Future<FileInfo?>? _cached;
  String? _cachedPath;

  /// The last signed URL seen, and the path it was signed for.
  String? _lastUrl;
  String? _lastUrlPath;

  @override
  Widget build(BuildContext context) {
    final BaseCacheManager cache = ref.watch(recipeImageCacheManagerProvider);
    if (widget.url != null) {
      _lastUrl = widget.url;
      _lastUrlPath = widget.path;
    }
    final String? url =
        widget.url ?? (_lastUrlPath == widget.path ? _lastUrl : null);
    final WidgetBuilder loading = widget.loading ?? widget.placeholder;

    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        cacheKey: widget.path,
        cacheManager: cache,
        memCacheWidth: widget.decodeWidth,
        fit: widget.fit,
        // A new signed URL for the same path keeps the old frame up rather
        // than blanking while the provider resolves.
        useOldImageOnUrlChange: true,
        placeholder: (BuildContext context, _) => loading(context),
        errorWidget: (BuildContext context, _, _) =>
            widget.placeholder(context),
      );
    }

    if (_cached == null || _cachedPath != widget.path) {
      _cachedPath = widget.path;
      _cached = cache.getFileFromCache(widget.path);
    }
    return FutureBuilder<FileInfo?>(
      future: _cached,
      builder: (BuildContext context, AsyncSnapshot<FileInfo?> snapshot) {
        final FileInfo? info = snapshot.data;
        if (info == null) return widget.placeholder(context);
        return Image.file(
          info.file,
          fit: widget.fit,
          cacheWidth: widget.decodeWidth,
          errorBuilder: (BuildContext context, _, _) =>
              widget.placeholder(context),
        );
      },
    );
  }
}
