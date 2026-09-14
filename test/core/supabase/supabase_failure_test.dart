// supabase_failure.dart translates Supabase driver exceptions -- including
// every Edge Function error slug -- into AppFailure. This file has two jobs:
//
//  1. A table test asserting the (runtimeType, FailureCode) pair for every
//     slug the switch handles, plus the negative half that protects D92's
//     deliberate carve-outs (code stays null, message stays server prose).
//  2. The slug-contract test the file's own header names but that nothing
//     had verified: every `HttpError(<status>, "<slug>"` thrown anywhere
//     under supabase/functions is parsed out of the .ts sources and checked
//     against the Dart switch, so a new server slug cannot silently degrade
//     to UnknownFailure with no message at all.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/supabase/supabase_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Builds the [FunctionException] `_fromFunction` actually switches on:
/// `runGuarded` catches it via the `FunctionException` supertype, so a plain
/// [FunctionsHttpException] with a decoded JSON body is the right double.
FunctionException _slugException(String slug, {String? message}) =>
    FunctionsHttpException(
      status: 400,
      details: <String, dynamic>{
        'error': slug,
        'message': ?message,
      },
    );

/// `runGuarded`'s body always throws, and every one of its `catch` clauses
/// rethrows an [AppFailure] -- so this always completes via the `on
/// AppFailure` clause below, never past it.
Future<AppFailure> _mapped(FunctionException e) async {
  try {
    await runGuarded(() async => throw e);
  } on AppFailure catch (f) {
    return f;
  }
}

void main() {
  group('Edge Function slugs -- positive table', () {
    final Map<String, (Type, FailureCode)> table = <String, (Type, FailureCode)>{
      'unauthenticated': (UnauthorizedFailure, FailureCode.signInAgain),
      'not_a_member': (UnauthorizedFailure, FailureCode.signInAgain),
      'no_household': (NotFoundFailure, FailureCode.noHousehold),
      'invite_not_found': (NotFoundFailure, FailureCode.inviteNotFound),
      'recipe_not_found': (NotFoundFailure, FailureCode.recipeNotFound),
      'invite_already_used': (ConflictFailure, FailureCode.inviteAlreadyUsed),
      'already_in_household': (ConflictFailure, FailureCode.inviteAlreadyUsed),
      'invite_expired': (ValidationFailure, FailureCode.inviteExpired),
      'invalid_code': (ValidationFailure, FailureCode.codeNotAccepted),
      'invalid_body': (ValidationFailure, FailureCode.codeNotAccepted),
      'method_not_allowed': (ValidationFailure, FailureCode.codeNotAccepted),
      'invalid_storage_path': (ValidationFailure, FailureCode.importPhotoFailed),
      'image_not_found': (ValidationFailure, FailureCode.importPhotoFailed),
      'not_an_image': (ValidationFailure, FailureCode.importPhotoFailed),
      'invalid_url': (ValidationFailure, FailureCode.invalidUrl),
      'fetch_failed': (ValidationFailure, FailureCode.siteUnreachable),
      'not_html': (ValidationFailure, FailureCode.notAWebPage),
      'page_too_large': (ValidationFailure, FailureCode.importTooLarge),
      'image_too_large': (ValidationFailure, FailureCode.importTooLarge),
      'no_recipe_found': (ValidationFailure, FailureCode.noRecipeOnPage),
      'job_not_found': (NotFoundFailure, FailureCode.importNotFound),
      'job_already_done': (ConflictFailure, FailureCode.importAlreadySaved),
      'job_not_parsed': (ValidationFailure, FailureCode.importNotReadyYet),
      'code_generation_failed': (UnknownFailure, FailureCode.couldNotMakeCode),
      'input_too_large': (ValidationFailure, FailureCode.importTextTooLong),
      'same_locale': (ValidationFailure, FailureCode.alreadyInThatLanguage),
      'quota_exceeded': (QuotaFailure, FailureCode.aiAllowanceUsedUp),
      'quota_unavailable': (QuotaFailure, FailureCode.unavailableTryLater),
      'ai_rate_limited': (QuotaFailure, FailureCode.unavailableTryLater),
      'ai_unavailable': (QuotaFailure, FailureCode.unavailableTryLater),
    };

    // `unauthenticated`/`not_a_member` never forward the server's message --
    // unchanged from before this part, and deliberate: the sentence a
    // signed-out or removed caller sees is fixed, never server-supplied.
    const Set<String> ignoresServerMessage = <String>{
      'unauthenticated',
      'not_a_member',
    };

    table.forEach((String slug, (Type, FailureCode) expected) {
      test('$slug -> ${expected.$1}/${expected.$2}', () async {
        final AppFailure f =
            await _mapped(_slugException(slug, message: 'server said so'));
        expect(f.runtimeType, expected.$1);
        expect(f.code, expected.$2);
        if (!ignoresServerMessage.contains(slug)) {
          expect(f.message, 'server said so');
        }
      });
    });
  });

  group('Edge Function slugs -- degenerate arms with no server message', () {
    test('empty_input codes only when the server sent nothing', () async {
      final AppFailure withMsg = await _mapped(_slugException('empty_input',
          message: 'nothing to import'));
      expect(withMsg.code, isNull);
      expect(withMsg.message, 'nothing to import');

      final AppFailure bare = await _mapped(_slugException('empty_input'));
      expect(bare.code, FailureCode.importUnreadable);
    });

    test('ai_failed codes only when the server sent nothing', () async {
      final AppFailure withMsg =
          await _mapped(_slugException('ai_failed', message: 'model refused'));
      expect(withMsg.code, isNull);
      expect(withMsg.message, 'model refused');

      final AppFailure bare = await _mapped(_slugException('ai_failed'));
      expect(bare.code, FailureCode.couldNotReadRecipe);
    });
  });

  group('the deliberate carve-out: url_not_allowed', () {
    test('always renders server prose, never a code', () async {
      // D92: one slug, several distinct sentences depending on which of
      // url_guard.ts's checks fired -- the client cannot pick between them.
      final AppFailure f = await _mapped(
          _slugException('url_not_allowed', message: 'Only web links can be imported.'));
      expect(f.code, isNull);
      expect(f.message, 'Only web links can be imported.');
    });
  });

  group('the deliberate carve-outs: unbounded server/GoTrue prose', () {
    test('a Postgres check-violation keeps its message and no code', () async {
      try {
        await runGuarded(() async => throw const PostgrestException(
              message: 'ingredients.qty_num must be positive',
              code: '23514',
            ));
      } on AppFailure catch (f) {
        expect(f, isA<ValidationFailure>());
        expect(f.code, isNull);
        expect(f.message, 'ingredients.qty_num must be positive');
      }
    });

    test('a GoTrue 422 keeps its message and no code', () async {
      try {
        await runGuarded(() async => throw AuthException(
              'Password should be at least 6 characters',
              statusCode: '422',
            ));
      } on AppFailure catch (f) {
        expect(f, isA<ValidationFailure>());
        expect(f.code, isNull);
        expect(f.message, 'Password should be at least 6 characters');
      }
    });
  });

  group('transport', () {
    test('FunctionsFetchException (status 0) is NetworkFailure/offline',
        () async {
      final AppFailure f =
          await _mapped(const FunctionsFetchException());
      expect(f, isA<NetworkFailure>());
      expect(f.code, FailureCode.offline);
    });
  });

  group('the slug contract (supabase/functions <-> supabase_failure.dart)', () {
    test('every HttpError slug thrown by an Edge Function has an arm here',
        () {
      final Directory dir = Directory('supabase/functions');
      expect(dir.existsSync(), isTrue,
          reason: 'run from the repo root, not test/core/supabase/');

      final RegExp thrown = RegExp(
        r'(?:new\s+HttpError|super)\s*\(\s*\d+\s*,\s*"([a-z_]+)"',
        dotAll: true,
      );
      final Set<String> serverSlugs = <String>{};
      for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.ts')) continue;
        // The `HttpError` class's own constructor definition isn't a throw
        // site, and `_test.ts` files construct fixtures, not the real API.
        if (entity.path.endsWith('http.ts')) continue;
        if (entity.path.endsWith('_test.ts')) continue;
        for (final RegExpMatch m in thrown.allMatches(entity.readAsStringSync())) {
          serverSlugs.add(m.group(1)!);
        }
      }
      expect(serverSlugs, isNotEmpty,
          reason: 'the regex matched nothing -- it likely drifted from '
              'http.ts\'s HttpError(status, code, message) shape');

      final String clientSource =
          File('lib/core/supabase/supabase_failure.dart').readAsStringSync();
      final RegExp handled = RegExp(r"case '([a-z_]+)':");
      final Set<String> clientSlugs = handled
          .allMatches(clientSource)
          .map((RegExpMatch m) => m.group(1)!)
          .toSet();

      final Set<String> missing = serverSlugs.difference(clientSlugs);
      expect(missing, isEmpty,
          reason: 'these Edge Function slugs have no arm in '
              '_fromFunction and silently degrade to UnknownFailure with no '
              'message: $missing');
    });
  });
}
