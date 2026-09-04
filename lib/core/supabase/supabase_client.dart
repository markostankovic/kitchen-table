/// Supabase client initialization and access.
///
/// This file and `data/` are the only places `supabase_flutter` may be
/// imported (CLAUDE.md rule 1), enforced by `tool/check_layers.dart`.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/env.dart';

part 'supabase_client.g.dart';

/// Initializes Supabase. Call once, before `runApp`.
Future<void> initSupabase() async {
  Env.assertConfigured();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    // Supabase renamed this parameter: `anonKey` is deprecated in favour of
    // `publishableKey`, and they are the same value -- initialize() just does
    // `publishableKey ?? anonKey`. The env var keeps the name `ANON_KEY`
    // because that is what `supabase status` prints, so the value can be
    // copied across without translation.
    publishableKey: Env.supabaseAnonKey,
  );
}

/// The Supabase client, for injection into repositories under `data/`.
///
/// `keepAlive` is justified: the client owns the auth session and its
/// websocket-capable connection; recreating it per-listener would drop both
/// (docs/ARCHITECTURE.md, "keepAlive only where justified").
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;
