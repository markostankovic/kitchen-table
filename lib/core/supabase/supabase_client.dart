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
@Riverpod(keepAlive: true)
Stream<String?> currentUserId(Ref ref) async* {
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  yield client.auth.currentUser?.id;
  yield* client.auth.onAuthStateChange
      .map((AuthState event) => event.session?.user.id);
}
