# Kitchen Table — Design System ("Garden")

Kitchen Table is a **household recipe app**: the recipes a family already cooks, shared across everyone in the household, in **both Serbian and English**. Core jobs: keep a recipe box (with photo-less monogram tiles, favourites, ratings, tags like *Lenten* / *Feast days*), import recipes from a link with a review step, plan the week's meals (including leftovers), and generate a shopping list grouped by aisle. Sign-in is Google only. Households (e.g. *Kod Mire* — "At Mira's") have members and invite codes.

One product surface: a **Flutter / Material 3 mobile app** (Android + iOS; values map to `ThemeData` / `ThemeExtension<KitchenColors>`). The theme is called **Garden** ("Option B · Material 3 colour scheme"): leafy green primary, warm cream ground, mustard secondary, paprika used only for small signals.

## Sources
- `uploads/design-system.pdf` — 7 boards: Garden colour scheme (light/dark roles + contrast), Foundations (type, semantic colours, spacing, radii, elevation, sizes/motion), Components (light + dark), Patterns (IngredientRow, StepRow, FilterRow, Settings — light + dark), Step timeline.
- `uploads/key-screens.pdf` — 15 pages: sign-in, recipes, recipe detail, plan, list, review import, household, empty filter, settings; sr/en and light/dark variants; "before/after" studies (serif titles → sans; card hairline → borderless fill); and the **2026-09-30 handover table** (latest spec — wins over older boards).
- Logo + app-icon SVGs (uploaded separately) → `assets/logo/`, `assets/app-icon/`.
- No codebase or Figma was provided.

**Spec precedence:** the handover (key-screens p.15) supersedes the boards: Literata removed (sans only), cards are **borderless** `surfaceContainer` (light) / `surfaceContainerHigh` (dark), per-slot add buttons removed in favour of one "Add meal", drag-handle token added.

---

## CONTENT FUNDAMENTALS

- **Voice:** calm, warm, domestic, plain. Speaks to the user as **"you"** ("Try removing a filter to see more recipes.", "Applies to this app only, whatever your phone uses."). Never "we". Serbian uses the polite plural (*Napravite*, *Unesite*).
- **Casing:** Sentence case everywhere — titles, buttons, chips (`Save recipe`, `Make a list`, `Discard this import`, `Add meal`). Ingredient names are **lowercase** (`bell peppers`, `minced meat`) — they read like a handwritten list. Recipe names Title-ish only where proper (`Baked beans prebranac`, `Grandma Ljubica's gibanica`).
- **Punctuation:** full stops on sentences, even short empty-state titles ("No recipes match that.", "No list yet."). Middle dot `·` joins meta ("Lunch · 6 servings", "Member · you", "sweet paprika · optional"). En dash for ranges ("Sep 14 – 20"). Em dash with spaces for asides ("You're offline — showing saved copies.").
- **Reassuring, not alarming:** offline is *"You're offline — showing saved copies. Changes won't save."* on a neutral banner, never red. Unmatched import lines are "worth a look", "Not matched to an ingredient" — never "error". "Already planned recently" is a gentle hint.
- **Honest about machines:** "Machine translation" tag; "This list is in Serbian"; "Imported from a link · [SOURCE]"; 'unit "handful" not recognised'.
- **Destructive copy is explicit:** "Everyone in Kod Mire loses access to its recipes, meal plans and shopping lists. This can't be undone from the app."
- **Bilingual:** every string exists in sr + en. Language names are never translated ("Srpski", "English"). Units localise (`kašičica`, `glavice`, decimal comma `1,5 kg`). Fractions are real glyphs (½, ¼).
- **No emoji. No exclamation marks. No marketing.** The one tagline: *"The recipes your home already cooks — for the whole household, in both languages."*

## VISUAL FOUNDATIONS

- **Colour:** cream surfaces dominate (~2/3 of a screen), green ~¼ (actions, today, amounts, nav pill), mustard a small golden highlight (selected chips/segments, no-photo tile, secondary tonal buttons), paprika a sliver (favourite heart, stars, stat values, 3dp review marker). Error magenta is for validation text and destructive *text* only — never a fill. All colours are M3 roles + named semantic aliases (`--today`, `--favorite`, `--leftover`…); screens read semantic names, never hex.
- **Type:** one family — the platform sans (Roboto / SF). The serif (Literata) was tried and removed. Weight **700 marks a recipe name** (and the wordmark) — nothing else is 700. Section headings 600. Steps and ingredients are large (18/28) for reading at arm's length while cooking.
- **Spacing:** fixed 4-8-12-16-24-32 scale; 16 screen gutter, 24 between sections, 12 between cards.
- **Backgrounds:** flat warm cream. No gradients, no textures, no full-bleed imagery except the recipe photo well (a flat `surfaceContainerHighest` block with an image glyph when there is no photo). One flat illustration exists (sign-in).
- **Cards:** borderless tonal fill `--card`, radius 12, elevation 0, no shadow. Meal entries sit *inset* on the day card in `surface`; leftovers are transparent with a 1dp **dashed** outline (dashed = "derived"). Today's day card gets a 2dp primary edge.
- **Lines:** hairlines in `outlineVariant` for stat strips, list rows, settings dividers. Ingredient rows use a **dashed 6/4 divider**. The unmatched marker is a 14dp dashed ring in `outline` — deliberately different from the divider.
- **Corner radii:** 4 badges · 8 chips/fields/thumbs/snackbar/banner · 12 cards · 16 menus/FAB · 28 dialogs/sheet tops · full for buttons, search, segmented controls and nav indicator. "Rounded, not pillowy."
- **Elevation / shadows:** flat by default; `surfaceTintColor` transparent. Level 2 (menus, snackbar) and level 3 (dialogs, sheets, dragged meal) are the only shadows. Depth otherwise comes from tone steps.
- **Transparency / blur:** none, except the scrim behind dialogs (onSurface 32% light, black 50% dark). No blur.
- **Motion:** 150 ms / 250 ms with M3 emphasized easing; state changes only. **No decorative animation**, no bounces.
- **Hover / press:** M3 state layers — currentColor overlay at 8% hover, 12% press (`.kt-state`). No scale/shrink. Focus on fields is a 2dp primary edge.
- **Sizing:** 48dp minimum target everywhere; buttons 48 (sign-in 52), fields 52, chips 40 (tags 32), app bar 64, nav bar 80, thumb 72.
- **Layout:** single column phone layout; app bar on `surface` (no tint), bottom NavigationBar on `surfaceContainer` with a primary pill; review-import pins its two actions to the bottom over a hairline. Filter rows scroll horizontally and bleed off the right edge to signal more.
- **Imagery:** user recipe photos (warm, real kitchen photos expected); when absent, a mustard monogram tile with the recipe's first letter.
- **Dark theme:** olive-black `#16160F` ground, pastel roles; same structure. Card = `surfaceContainerHigh`.

## ICONOGRAPHY

- **Material Symbols Rounded**, weight 400, optical size matched, outlined by default; **filled** only for the selected nav tab, the favourite heart and filled rating stars. Sizes: 24 actions · 20 in buttons · 16 in meta lines · 48 empty states. Colour: `onSurface`/`onSurfaceVariant`, `outline` for muted/drag handles, semantic colours for heart/stars/leftover.
- Loaded from the Google Fonts CDN (`tokens/fonts.css`) and used via `<Icon name="…">` or `<span class="kt-icon">name</span>`. ⚠️ The PDFs don't name the icon set; glyph shapes match Material Symbols Rounded — **substitution flagged**, confirm with the team.
- Key glyphs: `menu_book` Recipes · `calendar_month` Plan · `list` List · `tune` Settings · `soup_kitchen` servings · `schedule` time · `star` rating · `drag_indicator` 6-dot grip · `undo` leftover · `history` recently planned · `language` machine translation · `cloud_off` offline · `login` sign out · `logout` leave household.
- No emoji, no unicode-as-icon (except ½/¼ fraction glyphs and the `→` in import mapping lines). The Google "G" on sign-in is a placeholder in the source — supply the official asset in production.

## Logo
Supplied as SVG (`assets/logo/`, `assets/app-icon/`):
- `mark-master.svg` — full-colour master mark (1080²).
- `glyph-one-colour-green.svg` — one-colour green glyph for small/single-ink use.
- `lockup-en-light.svg` / `lockup-en-dark.svg` — mark + "Kitchen Table" (760×160); light on cream `surface`, dark on `#16160F`.
- `launch-mark-on-green.svg` — splash/launch screen mark on primary green.
- App icons: `ios-appicon-1024.svg`; Android adaptive `android-adaptive-background.svg` + `android-adaptive-foreground.svg`; `android-monochrome.svg` (themed icons).
The mark is a steaming bowl on a small table, in cream/mustard/paprika on a green rounded tile. The lockup wordmark is set in a **serif**: logo artwork only, never UI type (the UI is sans only). Only English lockups were supplied. In-app, the type wordmark (displaySmall 700, `--primary`) remains for text contexts. Never redraw or recolour the mark.

---

## Index
- `styles.css` — entry point (imports only) → `tokens/fonts.css`, `colors.css` (light `:root`, dark `[data-theme="dark"]`), `typography.css`, `spacing.css`, `elevation.css`, `base.css` (body, links, `.kt-icon`, `.kt-state`, `.kt-dash`).
- `fonts/` — Roboto + Roboto Mono woff2 (latin, latin-ext).
- `assets/logo/`, `assets/app-icon/` — logo mark, lockups, launch mark, app icons (SVG).
- `assets/illustrations/recipe-card.png` — sign-in illustration (raster, extracted from key-screens PDF).
- `guidelines/` — foundation specimen cards (Colors, Type, Spacing, Brand).
- `components/` — React primitives (below), each with `.jsx`, `.d.ts`, `.prompt.md` and a group card.
- `ui_kits/app/` — click-through app recreation (`index.html`); see its README.
- `SKILL.md` — Agent Skill entry.

### Components
- **core/** — Icon, Card, Monogram
- **actions/** — Button, IconButton, SegmentedButton
- **inputs/** — TextField, SearchField
- **chips/** — Chip, Tag, FilterRow
- **recipe/** — RecipeCard, IngredientRow, StepList, StatRow
- **plan/** — DayCard, MealEntry (incl. leftover variant)
- **navigation/** — AppBar, NavigationBar
- **feedback/** — Dialog, Menu, Snackbar, Banner, EmptyState
- **settings/** — ProfileCard, SettingsGroup, NavRow, ListRow

### Intentional additions
- **Icon** — wrapper for the Material Symbols glyph set.
- **Card** — the handover asks every card (settings groups, list document, import summary, invite code) to read the same; one primitive enforces it.
- **Monogram** — shared by RecipeCard tiles and member avatars.

Not built (shown only as specs in the source): the 4-slot "Add meal" bottom sheet and the "Steps" board long-form examples beyond StepList.
