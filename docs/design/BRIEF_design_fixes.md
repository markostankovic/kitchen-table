# Brief for Claude Design — design fixes (2026-09-28)

**Project:** Kitchen Table, a family recipe and meal-planning app (Flutter, Material 3, iOS and Android). It is Serbian-first and bilingual (sr/en), and every screen must fit both languages without changing the layout. The visual system is "Garden": green primary, mustard secondary, paprika tertiary, warm cream surfaces. Please update the existing design system and screens you made (design-system.pdf, key-screens.pdf and the screen references). Don't start from scratch.

Show every change in **light and dark**, and in **Serbian and English** where text length matters.

### 1. Ingredient list: amounts on the right, names on the left
Today a row reads `[qty, right-aligned in a narrow column] [unit + name]`, e.g. `½ | kg mlevenog mesa`.
Change it to: **name on the left, amount on the right**, e.g. `mleveno meso ........ ½ kg`.
- Keep the unit next to the number (`½ kg`, `2 kašike`), not next to the name.
- Right-align the amount column so numbers and fractions line up down the list.
- Leave clear space between the name and the amount. Long names wrap on the left side and never run into the amount.
- Lines with no amount ("so po ukusu" / "salt to taste") show only the name.
- Keep the existing states: **optional** (a muted "opciono/optional" suffix), **unmatched** (a small dashed ring, never red), and **flagged** (import review only, with a 3px left marker).
- The same row is used on recipe detail, import review and the shopping list. Show all three.

### 2. Steps: easier to read
Step text is currently Literata serif, 17/26, regular weight. On a phone it feels heavy.
- Switch step text to **sans-serif, regular weight (not bold)**. Tune size, line height and paragraph spacing for reading while cooking at arm's length.
- Keep the numbered disc, but check that its weight and size still sit well next to lighter text.

### 3. Serif vs sans-serif across the app
Please evaluate dropping the serif (Literata) and going **all sans-serif**.
- Show a side-by-side of the recipe detail and recipe list screens in both versions: (a) all sans, and (b) serif only for recipe titles and the wordmark.
- Recommend one, with a short reason. Right now the serif is the "handwritten recipe box" warmth of the brand, so if it goes, say what carries that warmth instead.
- Deliver the updated type scale table (role → size/line, weight, face).

### 4. Settings screen: full design
Today it is a plain list: profile (avatar, name, email), a language toggle (Srpski / English), Household →, and Sign out.
Design it properly:
- Group the rows into clear sections (for example: Profile, Appearance, Language, Household, Account).
- Include the new theme option from item 5.
- Make sign out visually separate from the other rows and not destructive-red.
- Language names stay untranslated ("Srpski", "English") in both locales.

### 5. Light/dark mode set inside the app
Add an **Appearance** setting that chooses the theme for this app only, independent of the phone's system setting.
- Options: **Light** and **Dark**. **Light is the default.** (A third "System" option can be shown as a variant if you think it's worth having.)
- Show the control (segmented button or similar) in both themes.

### 6. Clear filters on the recipe list
The recipe list has a horizontally scrolling filter row: a "Favorites" chip plus one tag chip (single-select), each shown as a selected chip with a check.
- Add a way to **clear all active filters** in one tap. It should appear only when a filter is active.
- The row must still scroll horizontally and never wrap.
- Also show the empty state when the filters return no recipes, with a clear-filters action in it.

### Deliverables
- Updated design-system pages: type scale, ingredient line, step row, filter row, settings components.
- Updated screens: Recipe detail, Recipe list (filters active + empty result), Import review, Shopping list, and a new Settings screen.
- Each in light and dark. At least recipe detail and settings in both sr and en.


