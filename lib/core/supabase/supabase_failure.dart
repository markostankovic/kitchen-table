/// Translation of Supabase driver exceptions into [AppFailure].
///
/// Lives in `core/supabase/` rather than in one feature's `data/` because
/// every repository needs the same mapping, and duplicating it per feature is
/// how the translations drift apart. This file and `data/` are the only places
/// `supabase_flutter` may be imported (CLAUDE.md rule 1).
///
/// Repositories call [runGuarded]; nothing below this line escapes into
/// `application/`.
library;

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_failure.dart';

/// Runs [body], translating any Supabase or transport exception into an
/// [AppFailure].
Future<T> runGuarded<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on AppFailure {
    rethrow;
  } on PostgrestException catch (e, s) {
    Error.throwWithStackTrace(_fromPostgrest(e), s);
  } on AuthException catch (e, s) {
    Error.throwWithStackTrace(_fromAuth(e), s);
  } on FunctionException catch (e, s) {
    // Also catches FunctionsHttpException / FunctionsFetchException /
    // FunctionsRelayException -- `on` matches subtypes.
    Error.throwWithStackTrace(_fromFunction(e), s);
  } on SocketException catch (e, s) {
    Error.throwWithStackTrace(NetworkFailure(cause: e), s);
  } on TimeoutException catch (e, s) {
    Error.throwWithStackTrace(
        NetworkFailure(
            message: 'The server took too long to respond.', cause: e),
        s);
  } catch (e, s) {
    Error.throwWithStackTrace(UnknownFailure(cause: e), s);
  }
}

AppFailure _fromPostgrest(PostgrestException e) {
  // Postgres SQLSTATEs. PGRST116 is PostgREST's "no rows for .single()".
  switch (e.code) {
    case 'PGRST116':
      return NotFoundFailure(cause: e);
    case '23505': // unique_violation
      return ConflictFailure(cause: e);
    case '23503': // foreign_key_violation
    case '23514': // check_violation
    case '22023': // invalid_parameter_value -- create_household raises this
      return ValidationFailure(message: e.message, cause: e);
    case '42501': // insufficient_privilege -- an RLS policy said no
      return UnauthorizedFailure(cause: e);
    default:
      return UnknownFailure(cause: e);
  }
}

/// Edge Function errors.
///
/// `create-invite` and `redeem-invite` answer every failure with
/// `{"error": "<code>", "message": "..."}` and `Content-Type:
/// application/json`, which `functions_client` decodes into
/// [FunctionException.details]. See `supabase/functions/_shared/http.ts` --
/// that file and this one are the two ends of the same contract.
///
/// Mapped on the machine-readable `error` rather than the HTTP status: it
/// keeps the coupling at exactly one point, and it lets Phase 3 localize by
/// code with the server's text as the fallback.
AppFailure _fromFunction(FunctionException e) {
  // status 0 is FunctionsFetchException: the request never reached the server.
  if (e.status == 0) return NetworkFailure(cause: e);

  final Object? details = e.details;
  final String? code =
      details is Map<String, dynamic> ? details['error'] as String? : null;
  final String? message =
      details is Map<String, dynamic> ? details['message'] as String? : null;

  switch (code) {
    case 'unauthenticated':
    case 'not_a_member':
      return UnauthorizedFailure(cause: e);
    case 'no_household':
    case 'invite_not_found':
      return NotFoundFailure(
          message: message ?? 'That code is not valid.', cause: e);
    case 'invite_already_used':
    case 'already_in_household':
      return ConflictFailure(
          message: message ?? 'That code has already been used.', cause: e);
    case 'invalid_code':
    case 'invalid_body':
    case 'invite_expired':
    case 'method_not_allowed':
      return ValidationFailure(
          message: message ?? 'That code was not accepted.', cause: e);
    // Phase 1d. All three mean "not now" rather than "not ever", so they carry
    // the server's own sentence: `quota_exceeded` has to say whose allowance
    // ran out, and no default here can.
    // Phase 1d import-text. Without these the server's own sentence -- which
    // says WHAT was wrong with the paste -- is lost to UnknownFailure.
    case 'empty_input':
    case 'input_too_large':
      return ValidationFailure(
          message: message ?? 'That text could not be imported.', cause: e);
    case 'quota_exceeded':
    case 'quota_unavailable':
    case 'ai_rate_limited':
      return QuotaFailure(
          message: message ?? 'That is unavailable right now. Try again later.',
          cause: e);
    // The model answered, but not with a recipe. Nothing the cook sent is
    // wrong and retrying may well work, so this is not a ValidationFailure.
    case 'ai_failed':
      return UnknownFailure(
          message: message ?? 'Could not read that recipe.', cause: e);
    default:
      return UnknownFailure(cause: e);
  }
}

AppFailure _fromAuth(AuthException e) {
  final int? status = int.tryParse(e.statusCode ?? '');
  if (status == 401 || status == 403) {
    return UnauthorizedFailure(cause: e);
  }
  if (status == 422 || status == 400) {
    return ValidationFailure(message: e.message, cause: e);
  }
  if (status == 429) {
    return const ValidationFailure(
        message: 'Too many attempts. Wait a minute and try again.');
  }
  return UnknownFailure(cause: e);
}
