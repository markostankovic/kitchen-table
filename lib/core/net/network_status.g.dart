// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive`: outlives every screen that watches it, the same
/// justification `data_revision.dart`'s counters give.

@ProviderFor(NetworkStatus)
final networkStatusProvider = NetworkStatusProvider._();

/// `keepAlive`: outlives every screen that watches it, the same
/// justification `data_revision.dart`'s counters give.
final class NetworkStatusProvider
    extends $NotifierProvider<NetworkStatus, Reachability> {
  /// `keepAlive`: outlives every screen that watches it, the same
  /// justification `data_revision.dart`'s counters give.
  NetworkStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkStatusHash();

  @$internal
  @override
  NetworkStatus create() => NetworkStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Reachability value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Reachability>(value),
    );
  }
}

String _$networkStatusHash() => r'edf0fd8e2ae91c163a8fcde8db8daaf7d897e031';

/// `keepAlive`: outlives every screen that watches it, the same
/// justification `data_revision.dart`'s counters give.

abstract class _$NetworkStatus extends $Notifier<Reachability> {
  Reachability build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Reachability, Reachability>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Reachability, Reachability>,
              Reachability,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
