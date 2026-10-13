# Brief for Claude Design: belonging to more than one household (2026-10-12)

**Project:** Kitchen Table is a family recipe and meal-planning app (Flutter, Material 3, iOS and Android). It is Serbian-first and bilingual (sr/en). All data (recipes, meal plan, shopping list) belongs to a **household**, not to a person. The visual system is "Garden": green primary `#366A35`, mustard secondary, paprika tertiary, warm cream surfaces (`#FFF7EC` light / `#16160F` dark), and Literata for display type. Please **update the existing design system and screens you made**. Don't start from scratch. Keep every current token unless a change below needs a new one, and name any new token you add.

Show every change in **light and dark**. Show Serbian and English wherever text length matters. Serbian household names can be long, e.g. "Porodica Stanković – vikendica".

### Why
Today an account belongs to exactly one household. People want more than one, for example their own family plus their parents' house, or a home plus a shared weekend house. Each household keeps its own recipes, plan and shopping list, completely separate. You are always "in" one household at a time, and you switch between them.

**Constraint:** most people will only ever have one household. With a single household, the app must look exactly as it does today, or as close to it as possible. No empty switcher, and no extra tap to reach anything.

### 1. Where the switcher lives: propose 2 directions
Today the household is reached from **Settings → Household** (a card row showing the name and "N members"), which opens the **Household** screen: name with a rename icon, Members, Invite someone (code), and a bottom-left destructive Leave/Delete text button under a hairline.
Propose **two directions** for where you see and change the current household, with a one-line rationale for each, then recommend one. For example:
- (a) Settings only: the Household row opens a list of your households when you have more than one.
- (b) A quiet household label or chip in the tab headers (Recipes / Plan / List) that opens a bottom sheet to switch.
Weigh how often people really switch (rarely, probably a few times a week at most) against the risk of adding a recipe or shopping item to the wrong household without noticing.

### 2. List of your households
- Each row: household name, member count, your role (owner / member), and a clear mark on the current one.
- Two actions at the end: **Create a new household** and **Join with a code**.
- How do you get from here to managing one household (the existing Household screen)? Tapping a row could switch, or open management, but not both. Make the difference obvious.
- Show it with 2 households and with 5, including one long Serbian name.

### 3. Switching
- What the user sees when they switch: a confirmation such as a snackbar "Now in …", and a loading state while the tabs reload their data.
- Switching always lands on the root of the current tab.

### 4. Create / join from inside the app
The existing **Create household** and **Join household** screens are first-run onboarding: a 56dp mark, a `headlineSmall` title, buttons pinned to the bottom, and no back affordance. Show how the same screens look when you reach them from inside the app: a back button or close, a title that fits ("Create another household"?), and where you land afterwards (in the new household).

### 5. Leaving or deleting when you have others
- The confirm dialog copy changes. It should say which household you'll switch to, e.g. "You'll switch to Porodica Stanković."
- After leaving or deleting your **last** household, you go back to first-run onboarding, as today.
- Joining with a code for a household you're already in shows an "already a member" state.

### 6. Knowing where you are
Propose whether any screen needs a reminder of the current household when you have more than one, for example the import review screen before saving, or the shopping list header. Keep it minimal, and none at all with one household.

**Deliverables:** updated `design-system.pdf` (any new token or component, such as the switcher sheet or chip), updated Settings and Household screens, the new household-list screen, in-app Create/Join variants, the switch confirmation, and the leave/delete confirm copy, all in light and dark, sr and en.
