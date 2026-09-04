/// Compile-time configuration (docs/ARCHITECTURE.md: `core/env/`).
///
/// Values arrive via `--dart-define`, normally in bulk:
///
///     flutter run --dart-define-from-file=env/local.json
///
/// `env/local.json` is gitignored; `env/local.example.json` is committed and
/// shows the shape. Nothing secret belongs here regardless -- the anon key is
/// public by design and protected by RLS, and no AI provider key ever reaches
/// the client (CLAUDE.md rule 2).
library;

abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether both required values were supplied at build time.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Fails loudly and early rather than surfacing as a confusing network error
  /// on the first query.
  static void assertConfigured() {
    if (isConfigured) return;
    throw StateError(
      'Missing Supabase configuration.\n'
      'SUPABASE_URL is ${supabaseUrl.isEmpty ? "empty" : "set"}, '
      'SUPABASE_ANON_KEY is ${supabaseAnonKey.isEmpty ? "empty" : "set"}.\n'
      'Run with: flutter run --dart-define-from-file=env/local.json\n'
      'Copy env/local.example.json and fill it from `supabase status`.',
    );
  }
}
