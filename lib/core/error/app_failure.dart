/// Typed failures (docs/ARCHITECTURE.md, "State management").
///
/// Repositories throw these. `PostgrestException` and `AuthException` are
/// caught and translated inside `data/` and never cross the boundary
/// (CLAUDE.md rule 1) -- `tool/check_layers.dart` enforces that.
///
/// A plain sealed class rather than `freezed`: CLAUDE.md mandates freezed for
/// *models*, and this is a control-flow type that is never serialized. Sealed
/// gives exhaustive `switch` in the UI, which is the property that matters.
///
/// Every constructor takes named arguments only. Mixing positional and named
/// is not expressible in Dart once defaults are involved, and a uniform shape
/// means a new variant can never be constructed the wrong way round.
///
/// Pure Dart. No Flutter imports.
library;

sealed class AppFailure implements Exception {
  const AppFailure({required this.message, this.cause});

  /// Safe to show to a user. Never contains a raw driver message.
  final String message;

  /// The originating exception, for logging only.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Offline, DNS failure, timeout.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'No connection.',
    super.cause,
  });
}

/// Not signed in, or an expired session.
///
/// Note that an RLS policy denying a *read* is indistinguishable from the row
/// not existing, by design, so that surfaces as [NotFoundFailure] instead.
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({
    super.message = 'Please sign in again.',
    super.cause,
  });
}

/// The row is absent, or RLS makes it invisible.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.message = 'Not found.',
    super.cause,
  });
}

/// Unique violation or a failed precondition.
final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    super.message = 'That already exists.',
    super.cause,
  });
}

/// The server rejected the input (check constraint, bad argument).
final class ValidationFailure extends AppFailure {
  const ValidationFailure({required super.message, super.cause});
}

/// Anything not otherwise classified. Always log [cause].
final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'Something went wrong.',
    super.cause,
  });
}
