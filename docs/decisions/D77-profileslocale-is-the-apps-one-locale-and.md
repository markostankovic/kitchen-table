## D77 — `profiles.locale` is the app's one locale, and the pre-auth default is Serbian

**Decided.** `flutter_localizations` + ARB files (`lib/core/l10n/arb/`,
Serbian the `template-arb-file`), generated to a committed
`lib/core/l10n/generated/` (`output-dir`, on the same convention CLAUDE.md
states for `*.g.dart` / `*.freezed.dart`). `core/l10n/app_locale.dart`
exposes `appLocaleProvider`, a `Locale` derived from
`ownProfileProvider.value?.locale`, falling back to `AppLocale.sr` whenever
there is no profile to read — signed out, or still loading.
`AuthRepository.updateLocale` writes `profiles.locale` directly; no migration
was needed, since the column, its check constraint and `profiles_update_own`
have existed since migration 2 and nothing had ever written to them.

Scope for this part is the app chrome only: the bottom nav, each tab's own
AppBar title (sharing the nav label's ARB key, so a tab and its header never
disagree about language), the Settings screen, and the sign-in / verify-OTP
screens. Every other screen's body stays English until the part that owns it
is localized in turn — visible, deliberate, temporary.

**Why `profiles.locale`, not a device setting.** It is already there, already
portable to a second device, and it is the field a later Phase 3 part will
read to decide which `recipe_translations` row to show. A second, local-only
notion of "what language" would be exactly the split D1 exists to prevent,
one phase before the question gets harder.

**Why Serbian is the pre-auth default.** A signed-out user has no profile to
read a locale from. CLAUDE.md says Serbian-first, and the alternative —
resolving the device locale before auth, then switching once the profile
loads — makes the very first screen flicker between languages to honour a
setting the app does not otherwise consult anywhere.

**Why language names are never translated.** The toggle reads *Srpski* /
*English* in both locales, the same choice `recipe_edit_screen.dart`'s
"Written in" segmented button already made — a language's own name is not
chrome to translate.

**Consequence, found while executing rather than while planning.** Three
screens outside the auth/settings boundary (`recipe_list_screen.dart`,
`meal_plan_screen.dart`, `shopping_list_screen.dart`) each have their own
`AppBar` title that now reads `AppLocalizations`, and each already has its
own widget-test file that pumps a bare `MaterialApp` rather than the real app
root — `test/core/router/app_shell_test.dart` was not, as first assumed, the
only test file this part would touch. Each of those three needed
`localizationsDelegates` / `supportedLocales` added to its own `MaterialApp`
wrapper, the same two lines `main.dart` gives the real app root. The lesson
worth keeping: a screen and its widget test are two separate places a
`Localizations` ancestor has to come from, and the second one is easy to
forget precisely because the first one just works.

**Rejected.**
- A local, on-device locale preference (`shared_preferences` or similar) —
  a second source of truth for the same question, and the wrong one to be
  asking again once `recipe_translations` needs the same answer.
- Resolving the device locale before authentication — flickers between
  languages for a value the app does not use anywhere else, on an app that
  states its own default in CLAUDE.md.
- Translating every screen in this one part, to match the roadmap's bullet
  literally in one commit — a much larger, harder-to-review diff and far
  more test churn than the chrome alone, for no gain the "Done when" needed.
