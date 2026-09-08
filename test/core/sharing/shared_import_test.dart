// What another app hands us, and which importer should get it.
//
// The cases are the shapes real apps actually send: Chrome shares a page as
// "Title\nURL", a notes app shares whatever was selected, and a messaging app
// shares a sentence with a link in the middle of it. Pure -- no plugin, no
// widgets, no network.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/sharing/shared_import.dart';

void main() {
  test('a bare link is a link', () {
    final SharedImport? got =
        classifyShare('https://www.bbcgoodfood.com/recipes/classic-lasagne');

    expect(got, isA<SharedUrl>());
    expect(
      (got! as SharedUrl).url,
      'https://www.bbcgoodfood.com/recipes/classic-lasagne',
    );
  });

  test("Chrome's title-then-link share is a link", () {
    // The single most important case, because it is what the roadmap's
    // done-when sentence actually describes.
    final SharedImport? got = classifyShare(
      'Easy classic lasagne recipe\n'
      'https://www.bbcgoodfood.com/recipes/classic-lasagne',
    );

    expect(got, isA<SharedUrl>());
    expect(
      (got! as SharedUrl).url,
      'https://www.bbcgoodfood.com/recipes/classic-lasagne',
    );
  });

  test('a whole recipe with a link in it is TEXT, with the link kept', () {
    // Sending this to the link importer would throw away everything the cook
    // actually selected and import the page instead.
    final String recipe = 'Šargarepa torta\n\n'
        '${'200 g šargarepe\n2 šolje glatkog brašna\n1/2 kašičice soli\n' * 8}'
        '\nOriginally from https://example.com/torta';

    final SharedImport? got = classifyShare(recipe);

    expect(got, isA<SharedText>());
    final SharedText text = got! as SharedText;
    expect(text.text, recipe);
    expect(text.sourceUrl, 'https://example.com/torta',
        reason: 'the link is attribution, and the paste screen has a field '
            'for exactly that');
  });

  test('prose with no link at all is text', () {
    final SharedImport? got =
        classifyShare('200 g šargarepe\n2 šolje glatkog brašna');

    expect(got, isA<SharedText>());
    expect((got! as SharedText).sourceUrl, isNull);
  });

  test('the platform hint wins over the length guess', () {
    // Android can say "this is a link". When it does, that beats anything the
    // threshold can infer.
    final String longish = '${'word ' * 60}https://example.com/recipe';

    expect(classifyShare(longish), isA<SharedText>());
    expect(classifyShare(longish, isUrlHint: true), isA<SharedUrl>());
  });

  test('a link written into a sentence loses its punctuation', () {
    // `https://example.com/recipe.` is a 404, not a recipe.
    final SharedImport? got =
        classifyShare('Try https://example.com/recipe. It is good.');

    expect(got, isA<SharedUrl>());
    expect((got! as SharedUrl).url, 'https://example.com/recipe');
  });

  test('a non-http scheme is text, not a link', () {
    // parseImportUrl refuses everything but http and https (D45), so calling
    // this a link would open an importer that cannot possibly succeed.
    final SharedImport? got = classifyShare('mailto:someone@example.com');

    expect(got, isA<SharedText>());
  });

  test('nothing shared is nothing to import', () {
    expect(classifyShare(''), isNull);
    expect(classifyShare('   \n  '), isNull);
  });
}
