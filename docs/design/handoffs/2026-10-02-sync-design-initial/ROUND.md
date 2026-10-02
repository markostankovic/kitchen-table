# Design round: sync-design-initial

Source: Claude Design handoff, 2026-10-02. Prompt: `PROMPT.md`. Bundle: `bundle/`.

The bundle is a **recreation of the app as it is on `main`** ("every screen
in the app, recreated from markostankovic/kitchen-table (main) with the
Garden design system", synced 2026-10-02T09:32Z — see `bundle/github.md`).
It is not a new direction. Expect each screen slice to find a small delta
or none: its job is to compare the frame with the shipped screen and close
the gaps. A slice that finds nothing worth changing closes as a no-op.

Fetched into `bundle/`: the canvas (`Kitchen Table App.dc.html`, 22 frames
in 6 sections, light + dark rows), the DS `readme.md`, `_ds_bundle.js`
(component JSX), `styles.css` and every `tokens/*.css` except `fonts.css`,
and `github.md` (the designer's screen → repo-file map). Not fetched: the
woff2 fonts, `tokens/fonts.css`, `support.js` (the canvas runtime),
`assets/*.svg` and `assets/recipe-card.png`. Fetch them with the
claude_design MCP (project `4c9b3914-ad35-43f6-affc-e61d488c0fe5`) if
a slice needs them.

## Token delta

Compared against `lib/core/theme/` and `docs/DESIGN_SYSTEM.md` § Colour,
§ Type, § Spacing and layout, § Shape, § Size and motion.

| Token | Flutter symbol | Old | New | Status |
|---|---|---|---|---|
| `--tracking-display-small` | `textTheme.displaySmall.letterSpacing` | −0.5 | +0.5 | changed (sign; see note) |
| `--tracking-headline-small` | `textTheme.headlineSmall.letterSpacing`, `KitchenType.recipeTitleLarge.letterSpacing` | −0.3 | +0.3 | changed (sign; see note) |
| `--tracking-recipe-title` | `KitchenType.recipeTitle.letterSpacing` | −0.1 | +0.1 | changed (sign; see note) |

**Note.** All three differ only in sign, and all three were negative in the
repo and in `DESIGN_SYSTEM.md` § Type. This round first guessed the export
had dropped the minus. **The user confirmed on 2026-10-02 that positive is
right.** `phase7-sync-tokens` flipped all three (D136).

**Unchanged: everything else, about 100 values.** All 31 M3 colour roles in
light and all 31 in dark, plus the two scrims (onSurface at 32% light,
black at 50% dark). All 17 of the bundle's semantic tokens, including
`card` = `surfaceContainer` / `surfaceContainerHigh`. The bundle's
`--doc-language-ring` is already documented as `docLanguage`'s
`outlineVariant` ring. The 10 type roles' size, line height and weight,
plus `KitchenType.monogram`. The 6 spacing steps, with gutter 16, sections
24 and cards 12. The 5 radii, and `full`, which is `StadiumBorder` by
design and not a member of `AppRadii`. The 13 sizes; tag 32 is documented
under `chip`. The 2 durations. The easing: the bundle's
`cubic-bezier(0.2,0,0,1)` is M3's CSS fallback for the emphasized curve,
which is `Curves.easeInOutCubicEmphasized` on our side. Elevation 0 / 2 / 3
with a transparent `surfaceTint`.

## Token map additions

`DESIGN_SYSTEM.md` has no § Token map yet. The tokens slice adds one, so
that later rounds can diff by name:

| Bundle token | Flutter symbol |
|---|---|
| `--primary` … `--inverse-primary` (M3 roles, kebab-case) | `ColorScheme.<role>` (camelCase), `AppTheme._lightScheme` / `_darkScheme` |
| `--scrim` | `AppTheme` scrim (`onSurface` @ 0.32 light, black @ 0.5 dark) |
| `--today`, `--today-container`, `--review-marker`, `--favorite`, `--rating`, `--stat-value`, `--leftover`, `--unmatched`, `--offline`, `--on-offline`, `--doc-language`, `--destructive`, `--card`, `--step-connector`, `--drag-handle` | `KitchenColors.<camelCase>` |
| `--doc-language-ring` | `ColorScheme.outlineVariant` (no own field) |
| `--meal-entry` | `ColorScheme.surface` (no own field) |
| — (repo only) | `KitchenColors.dividerDash`, `KitchenColors.dropTarget` |
| `--type-display-small` … `--type-label-medium` | `TextTheme.<role>` |
| `--type-recipe-title`, `--type-headline-small` (as recipe title), `--type-monogram` | `KitchenType.recipeTitle`, `.recipeTitleLarge`, `.monogram` |
| `--space-xs/s/m/l/xl/xxl` | `AppSpacing.xs/sm/md/lg/xl/xxl` |
| `--gutter`, `--section-gap`, `--card-gap` | `AppSpacing.lg`, `.xl`, `.md` |
| `--radius-xs/sm/md/lg/xl` | `AppRadii.xs/sm/md/lg/xl` |
| `--radius-full` | `StadiumBorder()` |
| `--size-target`, `-button`, `-button-signin`, `-field`, `-chip`, `-app-bar`, `-nav-bar`, `-thumb`, `-step-disc` | `AppSizes.target`, `.button`, `.signInButton`, `.field`, `.chip`, `.appBar`, `.nav`, `.thumb`, `.stepDisc` |
| `--size-tag` | none — 32 is written in the chip theme. The slice decides whether it earns `AppSizes.tag` |
| `--icon-action`, `--icon-button`, `--icon-meta` | `AppSizes.icon`, `.iconInButton`, `.iconInMeta` |
| `--duration-short`, `--duration-medium`, `--ease-emphasized` | `AppDurations.short`, `.medium`, `.emphasized` |
| `--elevation-2`, `--elevation-3` | M3 elevation 2 / 3 with `shadowColor: scheme.shadow` |

## Slices, in order

Canvas sections are anchored by `data-screen-label` in
`bundle/Kitchen Table App.dc.html`, and frames are numbered `01 · …` to
`22 · …`. The components are in `bundle/_ds/…/_ds_bundle.js`, and the
house rules are in `bundle/_ds/…/readme.md` (§ VISUAL FOUNDATIONS and
§ CONTENT FUNDAMENTALS).

- [x] `phase7-sync-tokens`: the theme. Files: `lib/core/theme/app_theme.dart`,
      `lib/core/theme/kitchen_type.dart`, possibly `app_sizes.dart`;
      `docs/DESIGN_SYSTEM.md` § Type and a new § Token map. Bundle:
      `tokens/typography.css`, `tokens/spacing.css`, `tokens/colors.css`.
      Settle the tracking sign with the user, add § Token map, and decide
      on `AppSizes.tag`.
- [x] `phase7-sync-onboarding`: sign-in, create and join household. Files:
      `lib/features/auth/presentation/sign_in_screen.dart`,
      `lib/features/households/presentation/create_household_screen.dart`,
      `lib/features/households/presentation/join_household_screen.dart`.
      Bundle: section `Onboarding`, frames 01–03. Diff against the shipped
      screens. The sign-in illustration (`assets/recipe-card.png`) and the
      mark (`assets/mark-master.svg`) are not fetched yet. Done as
      part 15 (`04b56d0`, D137). `bundle/assets/recipe-card-reference.png`
      was added during planning, cropped from `docs/design/key-screens.pdf`.
- [ ] `phase7-sync-recipe-list`: recipe list, no-results state, add menu.
      Files: `lib/features/recipes/presentation/recipe_list_screen.dart`
      (with its widgets). Bundle: section `Recipes`, frames 04–06;
      components `RecipeCard`, `FilterRow`, `SearchField`, `EmptyState`,
      `Menu`. Diff the filters-active list, the empty filter and the menu.
- [ ] `phase7-sync-recipe-detail`: recipe detail. Files:
      `lib/features/recipes/presentation/recipe_detail_screen.dart`.
      Bundle: section `Recipes`, frame 07; `IngredientRow`, `StepList`,
      `StatRow`. Diff against part 13's photo-header layout (D135). The
      bundle was synced after it shipped.
- [ ] `phase7-sync-recipe-edit`: edit recipe, review translation. Files:
      `lib/features/recipes/presentation/recipe_edit_screen.dart`,
      `lib/features/recipes/presentation/translation_review_screen.dart`.
      Bundle: section `Recipes`, frames 08–09; `TextField`, `Tag`. Diff the
      form fields and the machine-translation review.
- [ ] `phase7-sync-import-capture`: link, paste, photo, reading. Files:
      `lib/features/import/presentation/import_url_screen.dart`,
      `import_paste_screen.dart`, `import_photo_screen.dart`, and the
      reading/progress state. Bundle: section `Import`, frames 10–13. Diff
      the three entry screens and the reading state.
- [ ] `phase7-sync-import-review`: review import. Files:
      `lib/features/import/presentation/import_review_screen.dart`.
      Bundle: section `Import`, frame 14; `IngredientRow` (unmatched ring,
      review marker). Diff the pinned action bar and the unmatched lines.
- [ ] `phase7-sync-meal-plan`: week, today, add-meal sheet. Files:
      `lib/features/meal_plan/presentation/meal_plan_screen.dart`,
      `lib/core/meal_plan/widgets/meal_slot_picker_sheet.dart`,
      `lib/core/recipes/widgets/recipe_picker_sheet.dart`. Bundle: section
      `Plan`, frames 15–17; `DayCard`, `MealEntry`, `SegmentedButton`.
      Diff against parts 12–13 (grip, drag rules). The readme says the
      4-slot add-meal sheet exists only as a spec.
- [ ] `phase7-sync-shopping-list`: list, offline and in Serbian, and the
      no-list state. Files:
      `lib/features/shopping_list/presentation/shopping_list_screen.dart`.
      Bundle: section `List`, frames 18–19; `Banner`, `Card`, `EmptyState`.
      Diff the offline banner, the language tag and the empty state.
- [ ] `phase7-sync-settings`: settings. Files:
      `lib/features/auth/presentation/settings_screen.dart`. Bundle: section
      `Settings`, frame 20; `ProfileCard`, `SettingsGroup`, `NavRow`,
      `ListRow`. Diff the groups and rows.
- [ ] `phase7-sync-household`: household and the leave dialog. Files:
      `lib/features/households/presentation/household_screen.dart`. Bundle:
      section `Settings`, frames 21–22; `Monogram`, `Dialog`. Diff the
      members, the invite code card and the destructive dialog.

## Out of scope

- **Material Symbols Rounded.** The bundle uses the Rounded set, and the
  readme itself flags it as a substitution ("the PDFs don't name the icon
  set"). The app uses built-in `Icons.*`, of which 34 of 90 are
  `_outlined` and none `_rounded`. Switching the set means picking a
  variant across ~90 call sites, and the Symbols font would be a new
  package (Hard rule 8). That needs its own decision; it does not belong
  in a sync round.
- **Logo and app-icon SVGs** (`mark-master.svg`, lockups). The repo has no
  SVG package, so drawing them in-app needs a new package (rule 8) or a
  raster export. They are also English-only lockups set in a serif, which
  the readme says is logo artwork, never UI type. Only an onboarding slice
  that wants the mark should raise this.
- **Web-only mechanics.** The `.kt-state` hover layer (Flutter's M3 ink
  already does this), the `.kt-dash` CSS gradient (the app has its own
  dashed divider, `dividerDash`), the Google Fonts CDN `@import`, the
  self-hosted Roboto woff2 files (the app uses the platform sans), the
  canvas page background `#E9E4DB`, and `support.js`.
- **The Google "G" on sign-in.** The readme says it is a placeholder.
  Production uses the official asset.
