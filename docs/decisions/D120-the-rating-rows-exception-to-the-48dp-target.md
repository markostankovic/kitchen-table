# D120 — The rating row's exception to the 48dp target is enforced locally, in the widget, not in the theme
**Status:** active
**Touches:** lib/features/recipes/presentation/recipe_detail_screen.dart, lib/core/widgets/app_stat_strip.dart, lib/core/theme/app_theme.dart, test/features/recipes/recipe_screens_test.dart

**Decided.** `_RatingStars` — five `IconButton`s in the stat strip's fourth
column — overrides the app's 48dp minimum hit area **in its own `style:`**:

```dart
style: IconButton.styleFrom(
  minimumSize: Size.zero,
  padding: EdgeInsets.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
```

Each button is then exactly its 16dp icon (`AppSizes.iconInMeta`) and five of
them are 80dp. A `FittedBox(fit: BoxFit.scaleDown)` wraps the row as a
backstop below roughly 340dp of screen width. `app_theme.dart`'s
`iconButtonTheme` keeps `minimumSize: Size(AppSizes.target, AppSizes.target)`
unchanged.

Alongside it, `AppStatStrip` centres every column's value in a box one
`bodyLarge` line tall — a *minimum* height, so a value needing two lines grows
rather than clips.

**Why.** Phase 7 Part 3's device walk found stars three, four and five off the
right edge of a real phone, untappable: nobody could rate a recipe above 2.
The cause is that an M3 `IconButton` sizes itself from its **style**, and the
widget-level `padding: EdgeInsets.zero` and `constraints: const BoxConstraints()`
those buttons already carried do *not* override a style's `minimumSize`. Each
star therefore claimed ~44dp (48 less `VisualDensity.compact`), and five
wanted ~220dp inside an ~86dp quarter-width column. The stars had always been
that wide — before this slice they sat in a full-width row of their own, so
the theme minimum never mattered. Putting them in a quarter column is what
exposed it.

The override is local because the 48dp minimum is right everywhere else in the
app; this is one control that physically cannot hold it. Five stars cannot each
be 48dp inside a quarter of a phone's width, and widening the column would cost
the equal-columns property — which is what stops the strip reflowing in
Serbian, since a quarter is a quarter in both languages where a sentence is
not.

The alignment box exists because each column's value used to hang from its own
top edge, so a 16dp star row sat visibly lower than a 26dp line of text and the
strip read as four things at four heights.

**Rejected.** Changing `iconButtonTheme`'s minimum globally — rejected; it
would shrink every icon button in the app to fix one row. Keeping
`VisualDensity.compact` with zero constraints, as the slice plan instructed —
rejected because that *is* the broken state; the plan assumed those buttons
were already tight and they never were. Widening the rating column, or giving
it more than a quarter — rejected, see above. Moving the rating out of the
strip and back to a full-width row — rejected; the strip is where § Steps and
stats puts it, and the walk confirmed four columns fit in Serbian. Making the
stars display-only and moving rating to a dialog — rejected; re-tap-to-clear
(decision 6) and the local echo both depend on the row staying interactive in
place.

**Consequences.** The rating stars are a **known, deliberate exception** to
`AppSizes.target`: ~16dp tap targets, five of them adjacent. Do not "fix" this
by widening them or by editing the theme — a future slice that sees small tap
targets here should read this file first. Any other control that ends up in a
stat-strip column inherits the same constraint. Three tests guard it, two
pumping a 360×780 surface (every prior screen test pumped 800×600, where a
220dp row simply lays out, which is why none of them caught the defect): one
asserts every star's rect is on screen, one hit-tests the fifth star's centre
and asserts the hit reaches it, and one asserts the strip's values share an
optical line. The hit-test is deliberate rather than a `tap()` — a real tap
runs `_setRating` into a repository the widget suite does not stub.
