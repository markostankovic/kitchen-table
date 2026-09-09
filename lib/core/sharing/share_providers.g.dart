// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(incomingShares)
final incomingSharesProvider = IncomingSharesProvider._();

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

final class IncomingSharesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedImport>,
          SharedImport,
          Stream<SharedImport>
        >
    with $FutureModifier<SharedImport>, $StreamProvider<SharedImport> {
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
  IncomingSharesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incomingSharesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incomingSharesHash();

  @$internal
  @override
  $StreamProviderElement<SharedImport> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SharedImport> create(Ref ref) {
    return incomingShares(ref);
  }
}

String _$incomingSharesHash() => r'bd7fec47ff0470d7f855000b9f85de2eaf3ac638';

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

@ProviderFor(PendingShare)
final pendingShareProvider = PendingShareProvider._();

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
final class PendingShareProvider
    extends $NotifierProvider<PendingShare, SharedImport?> {
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
  PendingShareProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingShareProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingShareHash();

  @$internal
  @override
  PendingShare create() => PendingShare();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedImport? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedImport?>(value),
    );
  }
}

String _$pendingShareHash() => r'2db359f7cc6b5575e8875e4b68823457ed56cf36';

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

abstract class _$PendingShare extends $Notifier<SharedImport?> {
  SharedImport? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SharedImport?, SharedImport?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SharedImport?, SharedImport?>,
              SharedImport?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
