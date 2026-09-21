/// A target language's own name, in the reader's language.
///
/// [locale] is already the resolved target -- `'en'` or `'sr'`, D91 -- not an
/// original locale to flip; callers resolve that themselves
/// (`RecipeDetail.readingLocale`, `RecipeDraft.translationTargetLocale`).
/// Lifted out of `recipe_detail_screen.dart`'s private `_targetLanguageName`
/// once the editor needed the same mapping (D93's precedent for a label
/// layer in `core/l10n/`, beside `meal_slot_labels.dart` and
/// `date_labels.dart`).
library;

import 'generated/app_localizations.dart';

String languageName(AppLocalizations l10n, String locale) =>
    locale == 'en' ? l10n.languageEnglish : l10n.languageSerbian;
