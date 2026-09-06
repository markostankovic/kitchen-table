// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'2f243b04dd88d4803e0fb0a51d03fefcc7e7d876';

/// The signed-in user, or null.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation, and letting it dispose between listeners would resubscribe to
/// the auth stream on each route change.

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// The signed-in user, or null.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation, and letting it dispose between listeners would resubscribe to
/// the auth stream on each route change.

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  /// The signed-in user, or null.
  ///
  /// `keepAlive` is justified: the router's redirect reads this on every
  /// navigation, and letting it dispose between listeners would resubscribe to
  /// the auth stream on each route change.
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'2a980e7da28d34f9856dee8aadae807a616abfdd';

/// The caller's own profile, refetched whenever the signed-in user changes.

@ProviderFor(ownProfile)
final ownProfileProvider = OwnProfileProvider._();

/// The caller's own profile, refetched whenever the signed-in user changes.

final class OwnProfileProvider
    extends
        $FunctionalProvider<AsyncValue<Profile?>, Profile?, FutureOr<Profile?>>
    with $FutureModifier<Profile?>, $FutureProvider<Profile?> {
  /// The caller's own profile, refetched whenever the signed-in user changes.
  OwnProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownProfileHash();

  @$internal
  @override
  $FutureProviderElement<Profile?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Profile?> create(Ref ref) {
    return ownProfile(ref);
  }
}

String _$ownProfileHash() => r'3cee8ec2382d457355bd68456c009561b1be06ba';
