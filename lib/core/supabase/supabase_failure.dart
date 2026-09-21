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
            message: 'The server took too long to respond.',
            code: FailureCode.serverTooSlow,
            cause: e),
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
    // No code (D92): `raise exception` prose from a migration is an
    // unbounded set of sentences no client vocabulary can cover.
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
/// that file and this one are the two ends of the same contract, and
/// `test/core/supabase/supabase_failure_test.dart` parses every
/// `HttpError(<status>, "<slug>"` out of `supabase/functions/**/*.ts` and
/// asserts each slug has an arm here.
///
/// Mapped on the machine-readable `error` rather than the HTTP status: it
/// keeps the coupling at exactly one point, and it is what lets D92 localize
/// by code with the server's text as the fallback.
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
      return UnauthorizedFailure(code: FailureCode.signInAgain, cause: e);
    case 'no_household':
      return NotFoundFailure(
          message: message ?? 'You are not in a household yet.',
          code: FailureCode.noHousehold,
          cause: e);
    case 'invite_not_found':
      return NotFoundFailure(
          message: message ?? 'That code is not valid.',
          code: FailureCode.inviteNotFound,
          cause: e);
    // Phase 3 part 2, translate-recipe. Not found also covers "not a
    // member" -- the caller-scoped select that produces this code cannot
    // tell the two apart, deliberately (D14's own reasoning for
    // loadJobForCaller's 404, applied here).
    case 'recipe_not_found':
      return NotFoundFailure(
          message: message ?? 'That recipe is not available.',
          code: FailureCode.recipeNotFound,
          cause: e);
    case 'invite_already_used':
    case 'already_in_household':
      return ConflictFailure(
          message: message ?? 'That code has already been used.',
          code: FailureCode.inviteAlreadyUsed,
          cause: e);
    // Split from the old shared "code was not accepted" sentence (D92):
    // an expired code and a malformed one call for different next steps.
    case 'invite_expired':
      return ValidationFailure(
          message: message ?? 'That code has expired.',
          code: FailureCode.inviteExpired,
          cause: e);
    // Genuinely reachable (phase6-part3b): a code can be revoked while
    // someone is reading it, so unlike the other new refusals this slice
    // adds, the UI cannot gate this one out.
    case 'invite_revoked':
      return ValidationFailure(
          message: message ?? 'That code was revoked.',
          code: FailureCode.inviteRevoked,
          cause: e);
    case 'invalid_code':
    case 'invalid_body':
    case 'method_not_allowed':
      return ValidationFailure(
          message: message ?? 'That code was not accepted.',
          code: FailureCode.codeNotAccepted,
          cause: e);
    // Phase 1d import-photo. `invalid_storage_path` means the client named a
    // path outside its own household -- a bug or an attempt, never something
    // the cook did.
    case 'invalid_storage_path':
    case 'image_not_found':
    case 'not_an_image':
      return ValidationFailure(
          message: message ?? 'That photo could not be imported.',
          code: FailureCode.importPhotoFailed,
          cause: e);
    case 'invalid_url':
      return ValidationFailure(
          message: message ?? 'That does not look like a link.',
          code: FailureCode.invalidUrl,
          cause: e);
    // No code (D92): one slug, several distinct sentences depending on
    // which of url_guard.ts's checks refused the link -- the client cannot
    // pick between "only web links can be imported" and "that link cannot
    // be opened" from the slug alone, and D45's guard deliberately says
    // nothing more specific than that.
    case 'url_not_allowed':
      return ValidationFailure(
          message: message ?? 'That link cannot be opened.', cause: e);
    // Phase 1d import-url. The SSRF-guarded fetch itself could not reach the
    // host at all (D45) -- distinct from `invalid_url`, which never got that
    // far, and from `url_not_allowed`, which refused the address on sight.
    case 'fetch_failed':
      return ValidationFailure(
          message: message ?? 'That site could not be reached.',
          code: FailureCode.siteUnreachable,
          cause: e);
    case 'not_html':
      return ValidationFailure(
          message: message ?? 'That link is not a web page.',
          code: FailureCode.notAWebPage,
          cause: e);
    // page_too_large (import-url) and image_too_large (import-photo) --
    // one sentence, since both mean "too big to read", not "too big to
    // upload" (Storage's own size limits are enforced client-side first).
    case 'page_too_large':
    case 'image_too_large':
      return ValidationFailure(
          message: message ?? 'That is too large to import.',
          code: FailureCode.importTooLarge,
          cause: e);
    case 'no_recipe_found':
      return ValidationFailure(
          message: message ?? 'No recipe was found on that page.',
          code: FailureCode.noRecipeOnPage,
          cause: e);
    case 'job_not_found':
      return NotFoundFailure(
          message: message ?? 'That import was not found.',
          code: FailureCode.importNotFound,
          cause: e);
    case 'job_already_done':
      return ConflictFailure(
          message: message ?? 'This import has already been saved.',
          code: FailureCode.importAlreadySaved,
          cause: e);
    case 'job_not_parsed':
      return ValidationFailure(
          message: message ?? 'This import is not ready yet.',
          code: FailureCode.importNotReadyYet,
          cause: e);
    case 'code_generation_failed':
      return UnknownFailure(
          message: message ?? 'Could not create a code.',
          code: FailureCode.couldNotMakeCode,
          cause: e);
    // Phase 1d import-text/photo/url. No code (D92): the sentence differs
    // per function ("nothing to import" / "no photo" / "no link"), and
    // runGuarded cannot tell which one ran -- except in the degenerate case
    // where the server sent no message of its own, which the client's own
    // generic sentence covers.
    case 'empty_input':
      return ValidationFailure(
          message: message ?? 'That text could not be imported.',
          code: message == null ? FailureCode.importUnreadable : null,
          cause: e);
    case 'input_too_large':
      return ValidationFailure(
          message: message ?? 'That text is too long to import.',
          code: FailureCode.importTextTooLong,
          cause: e);
    // Phase 3 part 2, translate-recipe: asking for a recipe's own
    // original_locale is refused before any model call runs.
    case 'same_locale':
      return ValidationFailure(
          message:
              message ?? 'This recipe is already written in that language.',
          code: FailureCode.alreadyInThatLanguage,
          cause: e);
    case 'quota_exceeded':
      return QuotaFailure(
          message: message ??
              'This household has used its AI allowance for the month.',
          code: FailureCode.aiAllowanceUsedUp,
          cause: e);
    case 'quota_unavailable':
    case 'ai_rate_limited':
    case 'ai_unavailable':
      return QuotaFailure(
          message: message ?? 'That is unavailable right now. Try again later.',
          cause: e);
    // The model answered, but not with a recipe. Nothing the cook sent is
    // wrong and retrying may well work, so this is not a ValidationFailure.
    // No code (D92) when the server spoke: the message is the model's own
    // refusal text, genuinely dynamic.
    case 'ai_failed':
      return UnknownFailure(
          message: message ?? 'Could not read that recipe.',
          code: message == null ? FailureCode.couldNotReadRecipe : null,
          cause: e);
    default:
      return UnknownFailure(cause: e);
  }
}

AppFailure _fromAuth(AuthException e) {
  final int? status = int.tryParse(e.statusCode ?? '');
  if (status == 401 || status == 403) {
    return UnauthorizedFailure(cause: e);
  }
  // No code (D92): GoTrue's own prose, an unbounded set.
  if (status == 422 || status == 400) {
    return ValidationFailure(message: e.message, cause: e);
  }
  if (status == 429) {
    return const ValidationFailure(
        message: 'Too many attempts. Wait a minute and try again.',
        code: FailureCode.tooManyAttempts);
  }
  return UnknownFailure(cause: e);
}
