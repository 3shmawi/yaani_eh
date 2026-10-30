# Feature: browse menu

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
Home is the café menu, made readable: the espresso header with category
chips, a "drink of the day" card with its explanation, then every
category's drinks as glass cards — photo, the name exactly as menus print
it, its Arabic spelling and the price range (or calories until prices are
checked). Tapping a chip shows just that category. Categories come from the
data, so new ones (and later whole sections like desserts) appear without an
app update.

## User flows
1. Open the app → Home with «الكل» selected, the drink of the day and all
   categories, each with «شوف الكل».
2. Tap a chip (or «شوف الكل») → only that category; tap «الكل» to go back.
3. Offline → same screen from the device, with the offline pill.

## Architecture
- Layers / main files: `lib/features/browse_menu/`
  - `domain/usecases/build_menu.dart` — `BuildMenu` (pure): chips (only
    categories with drinks, ordered by section then category), sections,
    the drink of the day (stable for a day, by date), and a fallback to
    «الكل» when the selected category disappears in a sync.
  - `presentation/menu_controller.dart` — `selectedCategoryProvider`,
    `menuProvider` (rebuilds when the catalog syncs), `todayProvider`.
  - `presentation/menu_page.dart` → `menu_view.dart` (Main artboard);
    widgets `DrinkCard`, `DrinkOfTheDay`.
  - Shared: `core/widgets/category_chips.dart`, `core/widgets/drink_photo.dart`
    (cached photo or brand gradient + initial), `core/backend/media.dart`
    (public Storage URLs), `AppGlass(minimal: true)` for many cards.
- State: Riverpod.
- Data sources: the device copy from `catalog_sync` (no network calls).
- Routes / deep links: `/` (inside `CatalogSyncPage`).

## Analytics events
| Event | When | Properties |
|---|---|---|
| `menu_category_selected` | a chip or «شوف الكل» is tapped | `category` (slug, or `all`) |

## Feature flags
None.

## Tests
- Unit: `test/features/browse_menu/domain/usecases/build_menu_test.dart`.
- Widget: `test/features/browse_menu/presentation/menu_page_test.dart` —
  states (loading, empty, all, one category), chips and «شوف الكل»,
  `DrinkCard` price/calories and its single screen-reader label, Arabic /
  dark / small phone with 1.3× text / tablet, `expectAccessible`.
- Integration (demo): `integration_test/browse_menu_test.dart`.

## Decisions & edge cases
- Photos: `image_path` in the `item-images` bucket, cached after the first
  view (`cached_network_image`); none yet → brand gradient + first letter.
- Grid labels use the cheapest glass (`minimal`) so 40+ cards scroll
  smoothly on mid-range Android; chips are clear glass on the header.
- Not here yet, each comes with its feature: the search field
  (`smart_search`), hearts (`favorites`), the play button
  (`pronunciation`), opening a drink (`item_details`) and the tab bar (once
  a second tab exists).
- Calories and prices are labelled approximate at the end of the list.

## Demo & post
**Hook (first 2 seconds):** «منيو الكافيه… بس مفهوم» / "A café menu… that finally makes sense."

**Scenario (what the integration test shows, with beat() pauses):**
1. Home opens: the drink of the day with its plain explanation.
2. Scroll through the glass cards: every name with its Arabic spelling.
3. Tap «قهوة ساقعة»: only iced coffee.
4. Tap «الكل»: everything again.

**Caption (English):** Every drink on a café menu, explained in plain
Egyptian Arabic — the name exactly as the menu prints it, how to read it,
calories and price. Categories are data in Supabase, so new ones show up
without an app update. Liquid Glass cards in Flutter.

**Caption (Egyptian Arabic):** كل مشروب في منيو الكافيه متشرح بالمصري: الاسم
زي ما هو مكتوب، بيتقري إزاي، سعراته وسعره. والأقسام بتتضاف من غير ما تحدّث
التطبيق.

**Hashtags:** #flutter #buildinpublic #liquidglass #supabase #yaanieh
