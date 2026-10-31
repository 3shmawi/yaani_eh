# Feature: recipes

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
«طريقة التحضير»: how each drink is made, in plain words. A glass sheet shows
the cup drawn to scale, layer by layer (a flat white is mostly milk with a
thin foam on top; a macchiato is mostly coffee), with each layer's name and
ml next to it, hot or iced, how long it takes, and the numbered steps the
way a good café makes it, each with its amount. «خطوة بخطوة» then shows one
step at a time in big text on the header band, for making it at home.

Designed in https://claude.ai/artifact/5pzpJCAdghkuTqHCNBotax (screens 2–4).

## User flows
1. Long-press a card → «طريقة التحضير» (tagged «جديد») → the sheet; the cup
   fills in from the bottom, then the steps.
2. Drink page → the «طريقة التحضير» row (under the trait pills, with the
   cup's size) → the same sheet.
3. In the sheet → «خطوة بخطوة» → one step per page; swipe or «الخطوة
   الجاية»; the back chevron goes one step back; the last button is «خلصت،
   بالهنا» and closes it. The ✕ closes it any time.
4. A link `yaanieh://drink/flat_white/steps` opens step by step over the
   drink page.
5. A drink without a recipe has no row in the preview or on its page; a
   steps link to it (or to an unknown drink) says «لسه مكتبناش طريقة
   تحضيره» with a way back.
6. Offline: everything works (recipes come with the menu copy).

## Architecture
- Data: `items.recipe` (JSON, see [content.md → Recipes](../content.md#recipes)),
  synced with the rest of the drink by `catalog_sync`:
  - `domain/entities/recipe.dart` (in `catalog_sync`): `Recipe` (minutes,
    layers, steps, `totalMl`), `RecipeLayer`, `RecipeStep`, `RecipeTone`,
    `RecipeIcon` (unknown names → `other`). `CatalogItem.recipe`.
  - `CatalogRows.recipe` checks every field and returns null when anything
    is off, so a broken recipe hides only the recipe. Stored on the phone
    as JSON in `items.recipe` (drift schema 3; upgrading fetches every
    drink again).
- Presentation: `lib/features/recipes/presentation/`
  - `recipe_sheet.dart`: `showRecipeSheet(context, item, from:)` (analytics,
    `showAppSheet`), and «خطوة بخطوة» → `/drink/<slug>/steps`.
  - `recipe_view.dart`: `RecipeView` (header, cup + legend, facts, steps,
    button), `RecipeStepRow`, `AmountTag`.
  - `widgets/recipe_cup.dart`: `RecipeCup` + `CupPainter`, `CupShape`.
  - `recipe_look.dart`: tone → `AppColors.layer*`, step icon →
    `AppIcons.step*`.
  - `step_by_step_page.dart` → `step_by_step_view.dart`.
- Shared building blocks: `showAppSheet` / `AppSheet` and
  `AppButtonKind.band` (+ `expand`) in `app_ui.dart`.
- State: Riverpod (`drinkDetailsProvider` from `item_details`).
- Routes / deep links: `/drink/:slug/steps` (`AppRoutes.drinkSteps`), a
  child of the drink route, so the slug rule applies (docs/deep_links.md).

## Analytics events
| Event | When | Properties |
|---|---|---|
| `recipe_opened` | the sheet opens | `drink` (slug), `from` (`preview`, `drinkPage`) |
| `recipe_step_mode_started` | step by step opens | `drink` |
| `recipe_finished` | «خلصت، بالهنا» on the last step | `drink` |

## Feature flags
None.

## Tests
- Unit: `test/features/catalog_sync/data/models/catalog_rows_test.dart`
  (recipes are read, survive the trip to the phone and back, unknown tones
  and icons fall back, broken recipes — strings, lists, missing or empty
  parts, zero or absurd ml, too many steps, too-long or non-text titles —
  hide only the recipe, injection-like text stays text),
  `catalog_repository_impl_test.dart` (a recipe reaches the device),
  `catalog_database_test.dart` (upgrading from schema 1 and 2).
- Widget: `test/features/recipes/presentation/recipe_test.dart` — the sheet
  (cup, legend, facts, steps, amounts; the cup's spoken label; Arabic and
  dark; hours for cold brew; close; «خطوة بخطوة» opens the steps; a light
  haptic; no recipe, no sheet; small phone with 1.3× text;
  `expectAccessible`), the cup (shape by size; fills in, still with Reduce
  Motion), step by step (next / previous / swipe, a selection haptic per
  step, done and close, RTL swipe, small phone, `expectAccessible`), the
  page (found, no recipe, unknown drink). The preview row and the drink-page
  row: `favorites_test.dart`, `drink_page_test.dart`.
- Database: `supabase/tests/catalog_rls.test.sql` (every drink has a
  recipe; malformed ones are rejected; anon reads, can't change).
- Security: `test/security/deep_link_test.dart` — steps links open step by
  step (also with crafted queries), close goes back to the drink, a drink
  without a recipe or an unknown one says so, crafted paths
  (`/drink/../steps`, capitals, SQL, `/steps/1`, `//steps`) show not-found.
- Integration (demo): `integration_test/recipes_test.dart`.

## Decisions & edge cases
- **One JSON column, not a steps table.** The design proposed
  `item_steps`; a `recipe` column on `items` rides the existing delta sync
  (an edit bumps the drink's `updated_at`) with no new table, policy or
  tombstones. The database checks its shape; the app checks every field.
- **To scale, but readable.** Layer heights follow their ml, with a 3 px
  minimum so a spoon of foam still shows; the cup's shape comes from the
  drink's size.
- **Colours are the drink's own**, the same in light and dark, each with
  its name next to it in the legend (never colour alone).
- **No ranges in content.** `25–30` turns around in Arabic; recipes say
  «حوالي 30». Digits are Western, like the rest of the app.
- **Step by step is a page, not a sheet**, so it has a link, the system
  back gesture, and room for big text. Finishing goes back to where it was
  opened from.
- **Words to review:** «شوت» (a shot of coffee) and «سيروب» are used as
  everyday café words; the rest avoids menu words.

## Demo & post
**Hook (first 2 seconds):** «اعمله في البيت» / "Make it at home."

**Scenario (what the integration test shows, with beat() pauses):**
1. Long-press Flat White: the preview, with «طريقة التحضير» marked new.
2. Open it: the cup fills in layer by layer, to scale, then the steps.
3. Scroll to «خطوة بخطوة» and start.
4. Four steps, one at a time, big; «خلصت، بالهنا» closes it.

**Caption (English):** How is a flat white different from a cappuccino?
Look at the cup: every drink's layers drawn to scale, then the steps a good
café follows, one at a time, in plain words. Flutter, Liquid Glass, content
in Supabase.

**Caption (Egyptian Arabic):** الفلات وايت يعني إيه بالظبط؟ بص على الفنجان:
طبقات كل مشروب بالمقاس، وبعدين الخطوات زي ما الكافيهات الحلوة بتعمله،
خطوة بخطوة، بكلام بسيط.

**Hashtags:** #flutter #buildinpublic #liquidglass #supabase #yaanieh
