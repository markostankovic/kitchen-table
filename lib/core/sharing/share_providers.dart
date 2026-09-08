/// Receiving a share, and holding it until the app can act on it.
///
/// The plugin sits behind a provider rather than being called from a widget,
/// for the reason everything else in this codebase does: a test overrides the
/// provider and pushes a share, and no mocking package is needed (rule 8).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'shared_import.dart';

part 'share_providers.g.dart';

/// Shares arriving from other apps, cold start first.
///
/// `getInitialMedia()` answers the share that LAUNCHED the app and
/// `getMediaStream()` the ones that arrive while it is running -- Android
/// delivers the second kind to the existing activity because MainActivity is
/// `singleTop`. Both are needed; either alone misses half the cases.
///
/// `reset()` after reading the initial share, or the plugin hands it over
/// again on the next cold start and the cook imports the same page twice.
///
/// Every plugin call is guarded. On iOS there is no share extension yet, and
/// in a widget test there is no platform at all -- both surface as a
/// `MissingPluginException`, and neither is a reason to take the app down.
@Riverpod(keepAlive: true)
Stream<SharedImport> incomingShares(Ref ref) async* {
  SharedImport? read(List<SharedMediaFile> files) {
    for (final SharedMediaFile file in files) {
      if (file.type != SharedMediaType.text &&
          file.type != SharedMediaType.url) {
        // An image share would be a photo import, which needs the upload path
        // and its own decision. Text and links are what 1d's done-when asks
        // for; anything else is ignored rather than half-handled.
        continue;
      }
      // `path` carries the text or the link for these two types, whatever its
      // name suggests -- the plugin uses one field for every kind of share.
      final SharedImport? share = classifyShare(
        file.path,
        isUrlHint: file.type == SharedMediaType.url,
      );
      if (share != null) return share;
    }
    return null;
  }

  // Yielded straight out of the generator rather than pushed through a
  // controller. An earlier version used a broadcast StreamController and added
  // the cold-start share to it before `yield*` had attached a listener -- and a
  // broadcast controller drops what nobody is listening for yet. The share
  // launched the app and then vanished, which is the one case this whole file
  // exists to serve. An `async*` generator does not start until it is listened
  // to, so a plain `yield` cannot lose it.
  try {
    final List<SharedMediaFile> initial =
        await ReceiveSharingIntent.instance.getInitialMedia();
    final SharedImport? first = read(initial);

    // Awaited before the stream is subscribed, or the same share can arrive
    // twice -- once from the initial read and once from the stream.
    await ReceiveSharingIntent.instance.reset();

    if (first != null) yield first;
  } on MissingPluginException {
    // No share extension on iOS, and no platform in a widget test. Neither is
    // an error; there simply are no shares on this build.
    return;
  } on Object catch (e, stack) {
    // Seen once on a real device: the plugin's own `SharedMediaFile.fromMap`
    // threw `Null is not a subtype of String` on a payload with no `path`.
    // Whatever produced it, a malformed share is not a reason to give up on
    // every share that follows -- so this falls through to the stream below
    // rather than returning.
    _report(e, stack, 'reading the share that launched the app');
  }

  // Shares arriving while the app is already running. Android delivers these
  // to the existing activity because MainActivity is `singleTop`.
  // `handleError` rather than letting it propagate: an error escaping a
  // `yield*` ends the generator, and with it every share for the rest of the
  // session. Swallowing one bad event keeps the next good one working.
  yield* ReceiveSharingIntent.instance
      .getMediaStream()
      .handleError((Object e, StackTrace stack) =>
          _report(e, stack, 'reading an incoming share'))
      .map(read)
      .where((SharedImport? share) => share != null)
      .cast<SharedImport>();
}

/// Surfaced in a debug console and swallowed everywhere else. A share that
/// could not be read is a share that did not happen, not a crash.
void _report(Object error, StackTrace stack, String what) {
  FlutterError.reportError(FlutterErrorDetails(
    exception: error,
    stack: stack,
    library: 'kitchen_table/sharing',
    context: ErrorDescription(what),
  ));
}

/// The share waiting to be acted on, if any.
///
/// It has to be held rather than acted on immediately, because a share can
/// arrive before the app is able to receive it. `app_router.dart`'s redirect
/// sends every location to `/sign-in` while nobody is signed in and to
/// `/create-household` while there is no household -- so navigating straight
/// to an import screen at cold start loses the URL with no way back. Keeping
/// it here means the listener can wait for those two gates and then deliver.
///
/// `keepAlive`, because outliving the screens is the entire point.
@Riverpod(keepAlive: true)
class PendingShare extends _$PendingShare {
  @override
  SharedImport? build() => null;

  void receive(SharedImport share) => state = share;

  /// Cleared as it is consumed, so one share opens one screen.
  void clear() => state = null;
}
