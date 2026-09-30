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
/// one line changes instead of eleven call sites. One member, [card], picks
/// a different role per brightness; it is still an alias, not a colour.
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
    required this.stepConnector,
    required this.dividerDash,
    required this.card,
    required this.dragHandle,
    required this.dropTarget,
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
    stepConnector: scheme.outlineVariant,
    dividerDash: scheme.outlineVariant,
    card: scheme.brightness == Brightness.light
        ? scheme.surfaceContainer
        : scheme.surfaceContainerHigh,
    dragHandle: scheme.outline,
    dropTarget: scheme.primaryContainer,
  );

  /// The "Danas"/"Today" pill and the 2dp outline of today's day card.
  /// Alias of `primary`.
  final Color today;

  /// The step-number disc. Today's day card is outlined in [today], not
  /// filled with this. Alias of `primaryContainer`.
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

  /// The 2dp line joining one step disc to the next. Alias of
  /// `outlineVariant`.
  final Color stepConnector;

  /// The dashed line under an ingredient row -- long, flat and lighter than
  /// the [unmatched] ring, so the two never read as one thing. Alias of
  /// `outlineVariant`.
  final Color dividerDash;

  /// The fill of every themed `Card` -- the one thing that separates a card
  /// from the cream ground now that cards have no hairline (D134). Alias of
  /// `surfaceContainer` in light and `surfaceContainerHigh` in dark: the dark
  /// `surfaceContainer` sits only +5 tone above the ground and fades out once
  /// there is no border, so dark reaches one step higher. Still an alias per
  /// brightness, not a second palette. In light it matches the nav bar on
  /// purpose.
  final Color card;

  /// The 6-dot grip on a meal-plan entry -- a hint that it can be dragged,
  /// and nothing else. Alias of `outline`.
  final Color dragHandle;

  /// The fill of the entries in a hovered meal-plan slot and of a hovered
  /// collapsed day. Alias of `primaryContainer`.
  final Color dropTarget;

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
    Color? stepConnector,
    Color? dividerDash,
    Color? card,
    Color? dragHandle,
    Color? dropTarget,
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
    stepConnector: stepConnector ?? this.stepConnector,
    dividerDash: dividerDash ?? this.dividerDash,
    card: card ?? this.card,
    dragHandle: dragHandle ?? this.dragHandle,
    dropTarget: dropTarget ?? this.dropTarget,
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
      stepConnector: Color.lerp(stepConnector, other.stepConnector, t)!,
      dividerDash: Color.lerp(dividerDash, other.dividerDash, t)!,
      card: Color.lerp(card, other.card, t)!,
      dragHandle: Color.lerp(dragHandle, other.dragHandle, t)!,
      dropTarget: Color.lerp(dropTarget, other.dropTarget, t)!,
    );
  }
}
