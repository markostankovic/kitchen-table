## D91 — Serbian is `srLatn`, everywhere the app resolves a `Locale`, because `Locale('sr')` alone is Cyrillic

**Decided.** `appLocaleProvider` (`core/l10n/app_locale.dart`) returns
`srLatn` — `Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn')` —
for `AppLocale.sr`, never a bare `Locale('sr')`. A new `appSupportedLocales`
constant (`<Locale>[Locale('en'), srLatn]`) replaces the generated
`AppLocalizations.supportedLocales` everywhere a `MaterialApp` is built:
`lib/main.dart` and every widget test that pumps one directly rather than
the real app root.

**Why this needed a decision and not just a bug fix.** Verified directly
against the pinned SDK
(`packages/flutter_localizations/lib/src/l10n/generated_material_localizations.dart`):
the `'sr'` case of `getMaterialTranslation` picks `MaterialLocalizationSrLatn`
*only* when `locale.scriptCode == 'Latn'`, and otherwise falls through to
`MaterialLocalizationSr`, whose ARB is Cyrillic verbatim
(`"cancelButtonLabel": "Откажи"`). CLAUDE.md is explicit — "Latin script
only for display" — and every string this app supplies itself (the 48 ARB
entries D77 through D86 built) was always correct, which is exactly why
nobody noticed: the text-selection toolbar, the back-button tooltip, a
date-range picker's own chrome are supplied by Flutter, not by this app,
and had been Cyrillic since Phase 3 part 1.

**Why the fix lives in `appLocaleProvider` and nowhere else.** D77 already
put "what language does this reader see" in exactly one place for exactly
this reason — a second notion of the current locale is the split D1 exists
to prevent, one screen before the question gets harder. `profiles.locale`
keeps storing the bare code `'sr'` / `'en'`; CLAUDE.md's "Locale codes are
`sr` and `en`. Nothing else." is a statement about that column, not about
the `Locale` object a reader of it is turned into, and every consumer of
`appLocaleProvider` reads `.languageCode`, which `srLatn` leaves unchanged.
No ARB regeneration was needed for the same reason: the generated delegate
resolves `AppLocalizations` on `languageCode` alone
(`isSupported`/`lookupAppLocalizations` in the generated file both switch
on it), so `srLatn` still returns `AppLocalizationsSr` — only Flutter's own
delegates (`GlobalMaterialLocalizations` and friends) care about the script
subtag, which is the whole point.

**Why `appSupportedLocales` has to exist alongside `srLatn`, not just the
provider.** The generated `AppLocalizations.supportedLocales` list still
carries a scriptless `Locale('sr')`. Flutter's locale resolution
(`basicLocaleListResolution`) matches the *device's requested* locale
against whatever `supportedLocales` offers, and a caller asking for
`sr_Latn` against a supported-locales list that only offers bare `sr`
would resolve to the bare entry — silently dropping the script tag back
off. Listing `srLatn` itself in `supportedLocales` is what keeps it through
resolution; `main.dart`'s own `locale:` argument then always requests it
directly, so this matters most for platform-level locale negotiation
outside the app's control, but it is the same class of quiet regression as
the enum default trap D92 names — a fix that reads correct at the one call
site that always runs and wrong at the one that runs later.

**Verified live, not only in the widget test that models it.** Long-pressing
a word in a text field on the Android emulator, before this fix existed in
that build, opened the Android text-selection toolbar in Cyrillic
(*Исеци / Копирај / Подели*). After the fix, the same gesture on the same
field reads *Iseci / Kopiraj / Deli / Izaberi sve*. `test/core/l10n/
app_locale_test.dart` is the repeatable form of exactly this assertion
(`MaterialLocalizations.of(context).pasteButtonLabel == 'Nalepi'`, pumped
against `srLatn` directly), and it is the one test in this project's whole
l10n surface that would have caught this bug on its own.

**Rejected.**
- Renaming the ARB template locale itself to `sr_Latn` — would introduce a
  third locale code into a project whose CLAUDE.md says there are exactly
  two, rename every generated class, and buys nothing D91's actual fix
  does not already buy for free (the generated delegate never needed to
  know about the script tag).
- Fixing this only in `main.dart` and leaving every widget test's bare
  `MaterialApp` pump on the old `AppLocalizations.supportedLocales` — the
  chrome would then be correct in the real app and unverifiable in the
  seven test files that pump their own `MaterialApp`, which is the same
  "two separate places a `Localizations` ancestor has to come from" lesson
  D77 already wrote down for delegates.
