// The failure vocabulary (D92): every FailureCode renders in both locales,
// no two codes collapse to the same sentence, the null-code fallback shows
// server prose verbatim, a code always beats a stale message, and a
// non-AppFailure never leaks its own toString().
//
// No pump needed -- AppLocalizationsSr()/AppLocalizationsEn() construct
// directly, the same way test/core/router/app_shell_test.dart already reads
// them at module scope.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/error/failure_l10n.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_en.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';

final AppLocalizations sr = AppLocalizationsSr();
final AppLocalizations en = AppLocalizationsEn();

void main() {
  group('every FailureCode', () {
    test('renders a non-empty sentence in both locales', () {
      for (final FailureCode code in FailureCode.values) {
        final AppFailure f = UnknownFailure(code: code);
        expect(localizedFailureMessage(f, sr), isNotEmpty, reason: '$code/sr');
        expect(localizedFailureMessage(f, en), isNotEmpty, reason: '$code/en');
      }
    });

    test('renders a different sentence in sr and en', () {
      // None of the 33 sentences is a proper noun, so there is no legitimate
      // exemption -- a key added to app_sr.arb and forgotten in app_en.arb
      // would otherwise silently show Serbian text in the English app.
      for (final FailureCode code in FailureCode.values) {
        final AppFailure f = UnknownFailure(code: code);
        expect(
          localizedFailureMessage(f, sr),
          isNot(localizedFailureMessage(f, en)),
          reason: '$code',
        );
      }
    });

    test('no two codes render the same sr sentence', () {
      // The realistic regression: a new code wired to a neighbour's key by
      // copy-paste. FailureCode.noTranslationToReview legitimately reuses an
      // existing ARB key, but shares it with nothing else in this enum.
      final Map<String, FailureCode> seen = <String, FailureCode>{};
      for (final FailureCode code in FailureCode.values) {
        final String sentence =
            localizedFailureMessage(UnknownFailure(code: code), sr);
        final FailureCode? clash = seen[sentence];
        expect(clash, isNull, reason: '$code and $clash render "$sentence"');
        seen[sentence] = code;
      }
    });
  });

  group('the fallback rule', () {
    test('a null code shows message verbatim', () {
      const AppFailure f = ValidationFailure(message: "server's own prose");
      expect(localizedFailureMessage(f, sr), "server's own prose");
      expect(localizedFailureMessage(f, en), "server's own prose");
    });

    test('a code beats a stale custom message', () {
      // The known trap (D92): a call site can pass a custom message: and
      // forget code:, in which case the variant's DEFAULT code still wins.
      // Asserted here from the opposite direction -- given a code, the
      // message argument is never consulted.
      const AppFailure f = NetworkFailure(
        message: 'this sentence must never render',
        code: FailureCode.offlineNoSavedPlan,
      );
      expect(localizedFailureMessage(f, sr), sr.failureOfflineNoSavedPlan);
      expect(
        localizedFailureMessage(f, sr),
        isNot(contains('this sentence must never render')),
      );
    });
  });

  group('localizedErrorMessage', () {
    test('an AppFailure delegates to localizedFailureMessage', () {
      const AppFailure f = NotFoundFailure();
      expect(localizedErrorMessage(f, sr), sr.failureNotFound);
    });

    test('a non-AppFailure becomes failureUnknown, never its own toString()',
        () {
      final Object raw = StateError('boom: a raw driver detail');
      expect(localizedErrorMessage(raw, sr), sr.failureUnknown);
      expect(localizedErrorMessage(raw, sr), isNot(contains('boom')));
    });
  });

  group('AppFailureL10n.localized', () {
    test('is the same shorthand as localizedFailureMessage', () {
      const AppFailure f = ConflictFailure();
      expect(f.localized(sr), localizedFailureMessage(f, sr));
    });
  });
}
