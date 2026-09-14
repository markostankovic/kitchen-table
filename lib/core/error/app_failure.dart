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
/// Pure Dart. No Flutter imports -- `lib/core/error/failure_l10n.dart` is the
/// sibling file that renders [code] in the reader's language, and it is the
/// one allowed to import Flutter (D92; verified against `tool/check_layers.dart`,
/// which derives a layer only from `lib/features/<name>/<layer>/` and so
/// leaves everything under `lib/core/` outside rule 7's reach). Nothing here
/// enforces that split but this comment -- do not "tidy" the import upward.
library;

/// What sentence a failure *is*, independent of the language it is read in.
///
/// Null on an [AppFailure] means the sentence in [AppFailure.message] came
/// from somewhere that knows more than this client does -- a Postgres
/// `raise exception`, GoTrue, a model's own refusal, an `import_jobs
/// .error_message` written days ago -- and must be shown verbatim. That is
/// the whole fallback rule; see `failure_l10n.dart`.
///
/// Grouped below in the order `supabase_failure.dart`'s switch reads them.
enum FailureCode {
  // --- Transport -----------------------------------------------------------
  /// [NetworkFailure]'s default: offline, DNS failure, `FunctionException`
  /// with `status == 0`.
  offline,

  /// A `TimeoutException` reached the driver -- the server is slow, not gone.
  serverTooSlow,

  /// The three cold-cache reads, one per cached entity: nothing local, and
  /// the network attempt that would have filled it also failed. Kept as
  /// three codes rather than one -- each sentence already names a different
  /// noun, and a reader would notice a generic one.
  offlineNoSavedRecipes,
  offlineNoSavedPlan,
  offlineNoSavedList,

  // --- Session & membership --------------------------------------------------
  /// [UnauthorizedFailure]'s default: an RLS `42501`, an expired session, or
  /// an Edge Function's `unauthenticated` / `not_a_member` slug. Also covers
  /// the two "you are not signed in any more" throw sites, which said the
  /// same thing in different words.
  signInAgain,

  /// Every "you are not in a household yet" throw site, plus the `no_household`
  /// slug.
  noHousehold,

  /// GoTrue 429.
  tooManyAttempts,

  // --- Not found -------------------------------------------------------------
  /// [NotFoundFailure]'s default: `PGRST116`.
  notFound,

  /// The `recipe_not_found` slug -- also covers "not a member", which the
  /// caller-scoped select cannot distinguish from an absent row (D14).
  recipeNotFound,

  /// `translation_reviewer.dart`'s own throw when there is nothing to review.
  /// Reuses the existing ARB key `noTranslationToReview` rather than adding a
  /// new one -- the sentence already exists and already says this.
  noTranslationToReview,

  // --- Invites ---------------------------------------------------------------
  inviteNotFound,

  /// `invite_already_used` and `already_in_household` -- one sentence for
  /// both, as the switch already grouped them.
  inviteAlreadyUsed,

  /// Split out from the old shared "code was not accepted" sentence: an
  /// expired code and a malformed one call for different next steps.
  inviteExpired,

  /// `invalid_code`, `invalid_body`, `method_not_allowed`, and the client-side
  /// "verifyOTP returned no user" case.
  codeNotAccepted,

  // --- Conflict & allowance ----------------------------------------------------
  /// [ConflictFailure]'s default: `23505`.
  alreadyExists,

  /// `quota_exceeded`. Fully localizable -- `_shared/usage.ts` deliberately
  /// keeps the numbers in a `console.error` and sends one fixed sentence
  /// naming which household ran out, precisely so the client can render it
  /// in any language.
  aiAllowanceUsedUp,

  /// [QuotaFailure]'s default: `quota_unavailable`, `ai_rate_limited`,
  /// `ai_unavailable` -- "not now", not "not ever" (rule from D17).
  unavailableTryLater,

  // --- Import & AI -------------------------------------------------------------
  /// `invalid_storage_path`, `image_not_found`, `not_an_image`.
  importPhotoFailed,

  /// `invalid_url`.
  invalidUrl,

  /// `input_too_large`, and the degenerate (no server message) arm of
  /// `empty_input` for `import-text` specifically is [importUnreadable]
  /// below, not this one -- this is the "too much text", not "no text" case.
  importTextTooLong,

  /// The degenerate arm of `empty_input` when the server sent no message of
  /// its own, and `import_confirm.dart`'s "that import could not be read"
  /// throw.
  importUnreadable,

  /// The degenerate arm of `ai_failed` when the model's own refusal text is
  /// unavailable.
  couldNotReadRecipe,

  /// `same_locale` -- translating a recipe into the language it is already
  /// written in.
  alreadyInThatLanguage,

  /// `fetch_failed` -- the SSRF-guarded fetch could not reach the host at
  /// all (D45). Distinct from [invalidUrl] and from `url_not_allowed`, which
  /// stays uncoded (see `supabase_failure.dart`).
  siteUnreachable,

  /// `not_html` -- the URL resolved, but to something that is not a web page.
  notAWebPage,

  /// `page_too_large` (import-url) and `image_too_large` (import-photo) --
  /// one sentence, since both mean "too big to read", not "too big to
  /// upload" (Storage's own 10 MB / 5 MB limits are enforced client-side
  /// before either request is even sent).
  importTooLarge,

  /// `job_not_found` -- the import job named in the route no longer exists
  /// or is not this caller's.
  importNotFound,

  /// `job_already_done` -- re-confirming an import that already produced a
  /// recipe (D44's retry guard doing its job).
  importAlreadySaved,

  /// `job_not_parsed` -- polling a job that has not finished reading yet.
  importNotReadyYet,

  /// `no_recipe_found` -- the model or the JSON-LD parse ran, but found
  /// nothing resembling a recipe on the page.
  noRecipeOnPage,

  /// `code_generation_failed` -- `create-invite` could not mint a code.
  couldNotMakeCode,

  // --- Generic -------------------------------------------------------------
  /// The four "server sent an unexpected reply" throw sites, and the same
  /// sentence in `ingredient_repository.dart`'s numeric decoder.
  unexpectedServerReply,

  /// [UnknownFailure]'s default, and what a non-[AppFailure] error renders as
  /// in the UI (`failure_l10n.dart`'s `localizedErrorMessage`) -- never that
  /// error's own `toString()`, which would leak a raw driver message.
  unknown,
}

sealed class AppFailure implements Exception {
  const AppFailure({required this.message, this.code, this.cause});

  /// Safe to show to a user when [code] is null; otherwise the log line only.
  /// Never a raw driver message.
  final String message;

  /// Set when this client, not the server, owns the wording -- see
  /// [FailureCode]'s own doc comment for the fallback rule. Left null only
  /// where the specific sentence is server prose this client's vocabulary
  /// cannot cover (an unbounded Postgres or GoTrue message, or one of the
  /// handful of Edge Function slugs named in `supabase_failure.dart`).
  final FailureCode? code;

  /// The originating exception, for logging only.
  final Object? cause;

  /// Includes [code] on purpose: once [message] and [code] can disagree (a
  /// call site can pass a custom `message:` and forget `code:`, keeping a
  /// variant's default), `message` alone no longer says which branch fired.
  @override
  String toString() => '$runtimeType(${code?.name ?? '-'}): $message';
}

/// Offline, DNS failure, timeout.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'No connection.',
    super.code = FailureCode.offline,
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
    super.code = FailureCode.signInAgain,
    super.cause,
  });
}

/// The row is absent, or RLS makes it invisible.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.message = 'Not found.',
    super.code = FailureCode.notFound,
    super.cause,
  });
}

/// Unique violation or a failed precondition.
final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    super.message = 'That already exists.',
    super.code = FailureCode.alreadyExists,
    super.cause,
  });
}

/// The server rejected the input (check constraint, bad argument).
///
/// No default [code] -- unlike every other variant, this one is routinely
/// constructed both ways: a handful of Edge Function slugs pass one, and raw
/// Postgres/GoTrue prose deliberately does not (D92's carve-out list, in
/// `supabase_failure.dart`).
final class ValidationFailure extends AppFailure {
  const ValidationFailure({required super.message, super.code, super.cause});
}

/// The request was refused for now, not for good: an exhausted AI allowance
/// (D17), or an upstream rate limit.
///
/// A seventh variant rather than a [ValidationFailure] with a nicer message,
/// because the two call for opposite things from a screen. Validation means
/// "change what you sent"; this means "send exactly this again later", and a
/// retry affordance is only correct for one of them.
final class QuotaFailure extends AppFailure {
  const QuotaFailure({
    super.message = 'That is unavailable right now. Try again later.',
    super.code = FailureCode.unavailableTryLater,
    super.cause,
  });
}

/// Anything not otherwise classified. Always log [cause].
final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'Something went wrong.',
    super.code = FailureCode.unknown,
    super.cause,
  });
}
