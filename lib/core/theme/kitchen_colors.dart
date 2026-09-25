import 'package:flutter/material.dart';

/// The semantic colour layer: names for what a colour *means* in this app
/// (`docs/DESIGN_SYSTEM.md` § The semantic layer, D118).
///
/// Read as `Theme.of(context).extension<KitchenColors>()!`.
///
/// **Every member is an alias of a `ColorScheme` role.** There is no second
/// palette here and there must never be one: light and dark follow the scheme
/// automatically, and a palette change stays an edit to the two `ColorScheme`
/// values in `app_theme.dart`. What this class adds is not colour, it is
/// vocabulary -- a screen drawing "the thing that means today" reads [today]
/// rather than `primary`, so that the day the two stop being the same colour,
/// one line changes instead of eleven call sites.
///
/// Two members are load-bearing rules rather than preferences:
///
/// - **[unmatched] is not an error.** An ingredient line the catalog did not
///   recognise still renders exactly what the cook typed, and that is a fine
///   outcome, not a failure (CLAUDE.md rule 3: `raw_text` is NOT NULL and
///   always rendered). A quiet dashed ring in `outline`, never red.
/// - **[offline] is not an error.** Offline is a frequent, ordinary state in
///   this app, not a fault. The banner informs; it does not alarm. That is
///   why it is a neutral container tone and not `errorContainer`.
@immutable
class KitchenColors extends ThemeExtension<KitchenColors> {
  const KitchenColors({
    required this.today,
    required this.todayContainer,
    required this.reviewMarker,
    required this.favorite,
    required this.rating,
    required this.statValue,
    required this.leftover,
    required this.unmatched,
    required this.offline,
    required this.onOffline,
    required this.docLanguage,
    required this.destructive,
  });

  /// Builds the extension from a scheme. The aliasing lives here and only
  /// here -- adding a member means adding one line to this factory, not
  /// picking a colour.
  factory KitchenColors.of(ColorScheme scheme) => KitchenColors(
    today: scheme.primary,
    todayContainer: scheme.primaryContainer,
    reviewMarker: scheme.tertiary,
    favorite: scheme.tertiary,
    rating: scheme.tertiary,
    statValue: scheme.tertiary,
    leftover: scheme.secondary,
    unmatched: scheme.outline,
    offline: scheme.surfaceContainerHighest,
    onOffline: scheme.onSurface,
    docLanguage: scheme.surfaceContainerLow,
    destructive: scheme.error,
  );

  /// The "Danas"/"Today" pill and its day header. Alias of `primary`.
  final Color today;

  /// Today's day card, and the step-number disc. Alias of `primaryContainer`.
  final Color todayContainer;

  /// The 3px left edge on a flagged import line. Alias of `tertiary`, which
  /// is why that role has to stay legible at 3px (D117's constraint, carried
  /// forward by D118's value).
  final Color reviewMarker;

  /// A filled heart -- only ever a heart. Alias of `tertiary`.
  final Color favorite;

  /// Filled stars. An empty star is `outline`. Alias of `tertiary`.
  final Color rating;

  /// The values in the servings / prep / cook / rating strip. Alias of
  /// `tertiary`.
  final Color statValue;

  /// The return icon on a leftover meal entry. Alias of `secondary`.
  final Color leftover;

  /// The dashed ring on an unmatched ingredient. **Not an error** -- see the
  /// class doc. Alias of `outline`.
  final Color unmatched;

  /// The offline banner's fill. **Not an error** -- see the class doc. Alias
  /// of `surfaceContainerHighest`.
  final Color offline;

  /// The offline banner's text. Alias of `onSurface`.
  final Color onOffline;

  /// The "SR"/"EN" document tag's fill; its ring is `outlineVariant`. Alias
  /// of `surfaceContainerLow`.
  final Color docLanguage;

  /// Destructive actions, as **text only** -- never a fill. Alias of `error`.
  final Color destructive;

  @override
  KitchenColors copyWith({
    Color? today,
    Color? todayContainer,
    Color? reviewMarker,
    Color? favorite,
    Color? rating,
    Color? statValue,
    Color? leftover,
    Color? unmatched,
    Color? offline,
    Color? onOffline,
    Color? docLanguage,
    Color? destructive,
  }) => KitchenColors(
    today: today ?? this.today,
    todayContainer: todayContainer ?? this.todayContainer,
    reviewMarker: reviewMarker ?? this.reviewMarker,
    favorite: favorite ?? this.favorite,
    rating: rating ?? this.rating,
    statValue: statValue ?? this.statValue,
    leftover: leftover ?? this.leftover,
    unmatched: unmatched ?? this.unmatched,
    offline: offline ?? this.offline,
    onOffline: onOffline ?? this.onOffline,
    docLanguage: docLanguage ?? this.docLanguage,
    destructive: destructive ?? this.destructive,
  );

  @override
  KitchenColors lerp(ThemeExtension<KitchenColors>? other, double t) {
    if (other is! KitchenColors) return this;
    return KitchenColors(
      today: Color.lerp(today, other.today, t)!,
      todayContainer: Color.lerp(todayContainer, other.todayContainer, t)!,
      reviewMarker: Color.lerp(reviewMarker, other.reviewMarker, t)!,
      favorite: Color.lerp(favorite, other.favorite, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
      statValue: Color.lerp(statValue, other.statValue, t)!,
      leftover: Color.lerp(leftover, other.leftover, t)!,
      unmatched: Color.lerp(unmatched, other.unmatched, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      onOffline: Color.lerp(onOffline, other.onOffline, t)!,
      docLanguage: Color.lerp(docLanguage, other.docLanguage, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
    );
  }
}
