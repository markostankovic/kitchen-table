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
