// The kind -> source_type mapping, which is load-bearing for D16.
//
// `recipes.source_type` decides whether a recipe is treated as reproduction of
// somebody else's copyrighted prose. An import that records the wrong value
// does not fail, does not look wrong on screen, and is wrong forever -- which
// is why the mapping lives in the domain with a test rather than inside a
// repository method that only runs against a network.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/import/domain/import_job.dart';

void main() {
  test('a photographed page is ocr, never manual', () {
    // The bug this test exists for. Until Phase 1d part 5 the value came from
    // whether a source URL was present, and a photograph has none -- so a
    // cookbook page would have been recorded as a recipe somebody typed out.
    expect(ImportKind.photo.sourceTypeFor(null), 'ocr');
    expect(ImportKind.photo.sourceTypeFor(''), 'ocr');
  });

  test('a link is url_import', () {
    expect(
      ImportKind.url.sourceTypeFor('https://example.com/recipe'),
      'url_import',
    );
  });

  test('a paste is manual, or url_import when it carried a link', () {
    expect(ImportKind.text.sourceTypeFor(null), 'manual');
    expect(ImportKind.text.sourceTypeFor('   '), 'manual');
    expect(
      ImportKind.text.sourceTypeFor('https://example.com/recipe'),
      'url_import',
    );
  });

  test('every kind maps to a value recipes.source_type allows', () {
    // The check constraint is ('manual','url_import','ocr','ai_generated'). A
    // kind mapping to anything else is a failed insert at save time, which is
    // the one moment a cook would least like to find out.
    const Set<String> allowed = <String>{
      'manual',
      'url_import',
      'ocr',
      'ai_generated',
    };
    for (final ImportKind kind in ImportKind.values) {
      expect(allowed, contains(kind.sourceTypeFor(null)));
      expect(allowed, contains(kind.sourceTypeFor('https://example.com')));
    }
  });

  test('wire values round-trip', () {
    for (final ImportKind kind in ImportKind.values) {
      expect(ImportKind.fromWire(kind.wireValue), kind);
    }
    for (final ImportJobStatus s in ImportJobStatus.values) {
      expect(ImportJobStatus.fromWire(s.wireValue), s);
    }
  });

  test('only queued and processing keep the poller running', () {
    // The loop in importJobProvider stops on anything else. A terminal status
    // that reported isPending would poll a finished job forever.
    expect(ImportJobStatus.queued.isPending, isTrue);
    expect(ImportJobStatus.processing.isPending, isTrue);
    expect(ImportJobStatus.needsReview.isPending, isFalse);
    expect(ImportJobStatus.failed.isPending, isFalse);
    expect(ImportJobStatus.done.isPending, isFalse);
  });
}
