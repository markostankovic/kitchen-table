/// What another app handed us, and which importer should receive it.
///
/// Pure: no plugin, no router, no Flutter. The classification is the whole of
/// the interesting logic here, and keeping it separable is what lets it be
/// tested against the shapes real apps actually send rather than the shape one
/// imagines they send.
library;

/// A share, once it has been understood.
sealed class SharedImport {
  const SharedImport();
}

/// A link to a page somebody wants read. Goes to the URL importer, where
/// JSON-LD may well answer it without a model call at all.
final class SharedUrl extends SharedImport {
  const SharedUrl(this.url);

  final String url;
}

/// Prose. Goes to the paste importer, carrying a URL as attribution if one
/// came along with it -- which is exactly the optional field that screen
/// already has.
final class SharedText extends SharedImport {
  const SharedText(this.text, {this.sourceUrl});

  final String text;
  final String? sourceUrl;
}

/// The first http(s) URL in a block of text.
///
/// Deliberately not a general URI matcher. `parseImportUrl` on the server
/// refuses everything but http and https anyway (D45), so recognising a
/// `mailto:` here would only produce a link screen that cannot succeed.
final RegExp _url = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);

/// Above this much prose alongside a link, the text is the point and the link
/// is a citation.
///
/// Chrome shares a page as `"Title\nhttps://…"` -- a handful of words and a
/// URL -- and that should open the link importer. Somebody sharing a whole
/// recipe out of a notes app may well have a URL in it somewhere, and sending
/// that to the link importer would throw away everything they actually
/// selected. The threshold is a judgement, not a law; it is here in one place
/// so it can be moved when a real share proves it wrong.
const int _proseThreshold = 200;

/// Reads a shared string, or null if there is nothing worth importing in it.
///
/// [isUrlHint] is what the platform said about the share -- Android
/// distinguishes a shared link from shared text, and when it does, that is
/// better evidence than anything this function can infer.
SharedImport? classifyShare(String raw, {bool isUrlHint = false}) {
  final String text = raw.trim();
  if (text.isEmpty) return null;

  final RegExpMatch? match = _url.firstMatch(text);
  if (match == null) {
    // No link in it at all. Whatever it is, the paste importer is the one that
    // can do something with it.
    return SharedText(text);
  }

  final String url = _trimTrailingPunctuation(match.group(0)!);

  // The platform already told us it is a link, or the text is a link and
  // little else.
  final String remainder = text.replaceFirst(match.group(0)!, '').trim();
  if (isUrlHint || remainder.length < _proseThreshold) {
    return SharedUrl(url);
  }

  return SharedText(text, sourceUrl: url);
}

/// Drops the punctuation a URL collects when it is written into a sentence.
///
/// `See https://example.com/recipe.` would otherwise import a link with a full
/// stop on the end, which is a 404 rather than a recipe. Parentheses are
/// balanced rather than stripped blindly, because a real URL can end in one.
String _trimTrailingPunctuation(String url) {
  String out = url;
  while (out.isNotEmpty) {
    final String last = out[out.length - 1];
    if (last == ')' &&
        '('.allMatches(out).length > ')'.allMatches(out).length - 1) {
      break;
    }
    if (!'.,;:!?)]}\'"'.contains(last)) break;
    out = out.substring(0, out.length - 1);
  }
  return out;
}
