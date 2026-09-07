// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The application router.
///
/// `keepAlive` is justified: disposing the router would discard the entire
/// navigation stack, and it is watched by the root widget for the whole life
/// of the app (docs/ARCHITECTURE.md, "keepAlive only where justified").

@ProviderFor(goRouter)
final goRouterProvider = GoRouterProvider._();

/// The application router.
///
/// `keepAlive` is justified: disposing the router would discard the entire
/// navigation stack, and it is watched by the root widget for the whole life
/// of the app (docs/ARCHITECTURE.md, "keepAlive only where justified").

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The application router.
  ///
  /// `keepAlive` is justified: disposing the router would discard the entire
  /// navigation stack, and it is watched by the root widget for the whole life
  /// of the app (docs/ARCHITECTURE.md, "keepAlive only where justified").
  GoRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return goRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$goRouterHash() => r'5f643a86aaae0cd62ae0eb6d2fe0ed355ed05206';
