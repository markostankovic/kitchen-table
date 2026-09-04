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
