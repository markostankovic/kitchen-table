// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Supabase client, for injection into repositories under `data/`.
///
/// `keepAlive` is justified: the client owns the auth session and its
/// websocket-capable connection; recreating it per-listener would drop both
/// (docs/ARCHITECTURE.md, "keepAlive only where justified").

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

/// The Supabase client, for injection into repositories under `data/`.
///
/// `keepAlive` is justified: the client owns the auth session and its
/// websocket-capable connection; recreating it per-listener would drop both
/// (docs/ARCHITECTURE.md, "keepAlive only where justified").

final class SupabaseClientProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  /// The Supabase client, for injection into repositories under `data/`.
  ///
  /// `keepAlive` is justified: the client owns the auth session and its
  /// websocket-capable connection; recreating it per-listener would drop both
  /// (docs/ARCHITECTURE.md, "keepAlive only where justified").
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseClientHash() => r'3db2a4c212c7f24cea9810e376225aa1a6cab012';

/// The signed-in user's id, or null.
///
/// Lives in `core/` rather than in `features/auth/` because more than one
/// feature needs to rebuild when the session changes, and a feature reaching
/// into another feature's `application/` layer is exactly what CLAUDE.md
/// forbids. The Supabase client owns the session and lives here, so the
/// session key does too.
///
/// `features/auth/` still owns the rich [AppUser] model and every auth
/// *action*; this is only the cross-cutting "who is signed in" signal.
///
/// The leading `yield` replays the restored session, which `onAuthStateChange`
/// alone does not do.

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

/// The signed-in user's id, or null.
///
/// Lives in `core/` rather than in `features/auth/` because more than one
/// feature needs to rebuild when the session changes, and a feature reaching
/// into another feature's `application/` layer is exactly what CLAUDE.md
/// forbids. The Supabase client owns the session and lives here, so the
/// session key does too.
///
/// `features/auth/` still owns the rich [AppUser] model and every auth
/// *action*; this is only the cross-cutting "who is signed in" signal.
///
/// The leading `yield` replays the restored session, which `onAuthStateChange`
/// alone does not do.

final class CurrentUserIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// The signed-in user's id, or null.
  ///
  /// Lives in `core/` rather than in `features/auth/` because more than one
  /// feature needs to rebuild when the session changes, and a feature reaching
  /// into another feature's `application/` layer is exactly what CLAUDE.md
  /// forbids. The Supabase client owns the session and lives here, so the
  /// session key does too.
  ///
  /// `features/auth/` still owns the rich [AppUser] model and every auth
  /// *action*; this is only the cross-cutting "who is signed in" signal.
  ///
  /// The leading `yield` replays the restored session, which `onAuthStateChange`
  /// alone does not do.
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return currentUserId(ref);
  }
}

String _$currentUserIdHash() => r'4beb8b5b143fb4e7957623969955e883926b6d51';
