# Brief for Claude Design: step connector, dashed ingredient dividers, app logo (2026-09-28)

**Project:** Kitchen Table is a family recipe and meal-planning app (Flutter, Material 3, iOS and Android). It is Serbian-first and bilingual (sr/en). The visual system is "Garden": green primary `#366A35`, mustard secondary, paprika tertiary, and warm cream surfaces (`#FFF7EC` light / `#16160F` dark). Please **update the existing design system and screens you made**. Don't start from scratch. Keep all current tokens unless a change below needs a new one, and name any new token you add.

Show every change in **light and dark**. Show Serbian and English wherever text length matters.

### 1. Recipe steps: connect the numbers with a vertical line
Today each step is a 28dp disc (`primaryContainer` fill, number in `labelLarge` `onPrimaryContainer`), then 16dp, then the step text in sans `bodyLarge` 18/28 regular. Steps are 24dp apart.
Change it to a **timeline**: a thin vertical line joins each disc to the next one, so the steps read as a single sequence.
- The line runs from the bottom of one disc to the top of the next. It is centred on the disc, and it stretches when a step's text wraps to many lines.
- No line above step 1 and no line below the last step. A recipe with one step shows no line.
- Choose the stroke width, the colour (for example `outlineVariant` or `primaryContainer`), and whether the line touches the discs or stops a few dp short. Say why. It should guide the eye without competing with the text.
- Check that the disc still sits well on the line (fill, size, maybe a ring in the surface colour).
- Show a short recipe (3 steps, one line each) and a long one (6+ steps, some wrapping to 4–5 lines), in both themes.

### 2. Ingredient list: dashed horizontal dividers
Today ingredient rows (name left, amount right, `bodyLarge`, min height 48) are separated by a solid 1px hairline in `outlineVariant`. The last row in a card has no hairline, because the card edge does the separating.
Change the separator to a **dashed horizontal line**.
- Specify the dash length, gap, stroke width and colour. The line must stay quiet in both themes. It must not look like the dashed **unmatched ring** that follows an unknown ingredient's name (a 16dp dashed circle in `outline`), so make them read as clearly different things.
- Keep the rule that the last row in a card has no divider.
- This row is shared by recipe detail, the shopping list, and import review (where flagged rows have a 3px paprika left marker and a tint, and rows are inset 12dp). Show the dashed divider on all three, or tell me if it should stay solid on some of them and why.
- Show a list that includes optional, unmatched, and no-amount rows ("so po ukusu").

### 3. App logo
Design the app's logo and launcher icon. There isn't one yet: the launcher shows the Flutter default, and the Android launch screen is flat brand green `#366A35` with no icon.
- **Idea:** a family kitchen table, home cooking, recipes handed down. It should feel warm and domestic, not like a restaurant or a chef's hat. It uses the Garden palette. It must work with no text, because the name differs by language ("Kitchen Table" / Serbian name TBD. Propose one if a good one comes to mind).
- **Deliver:**
  - A mark (icon only) and a lockup of the mark with the wordmark. The wordmark is Literata 600 in `primary`, matching the app's existing `displaySmall` wordmark.
  - An **Android adaptive icon**: a separate foreground and background on a 108dp canvas, with everything that matters inside the 66dp safe zone. Show it under circle, squircle and rounded-square masks.
  - An **Android 13+ monochrome (themed) icon** layer.
  - An **iOS app icon**: 1024×1024, opaque, no transparency, and not pre-rounded.
  - The mark on flat `#366A35` green, so it can also appear on the launch screen.
  - Legibility at 48px and 24px, plus the mark on light and dark backgrounds.
  - A master SVG, in vector form throughout.
- Please give 2–3 directions first with a one-line rationale for each, then refine the one you recommend.

**Deliverables overall:** updated `design-system.pdf` (new values for the step connector and the dashed divider), updated Recipe detail / Shopping list / Review import screen references, and a logo sheet with the exported assets.

