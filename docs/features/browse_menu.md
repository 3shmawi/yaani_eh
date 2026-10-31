# Feature: browse menu

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
Home is the café menu, made readable: the espresso header with category
chips, a "drink of the day" card with its explanation, then every
category's drinks as cards. Each card answers «يعني إيه؟» at a glance:

1. the photo (recognise it),
2. the name exactly as menus print it (find it),
3. its Arabic spelling (say it),
4. the «يعني» line, what it is in everyday words, e.g. «فرابيه يعني ميلك
   شيك بالقهوة» (understand it).

No price on the card: the drink page has it. Tapping a chip shows just that
category. Categories come from the
data, so new ones (and later whole sections like desserts) appear without an
app update.

## User flows
1. Open the app → Home on «مشروبات»: the drink of the day, then every
   category's drinks, one after another.
2. Tap a chip → the list scrolls to that category. Scrolling on, the
   highlighted chip follows; once the header has scrolled away, the chips
   stay pinned at the top.
3. Tap «حلويات» in the switch → «حلويات جاية قريب» (no desserts yet), with
   «شوف المتاح دلوقتي» back to the drinks.
4. Offline → same screen from the device, with the offline pill.

## Architecture
- Layers / main files: `lib/features/browse_menu/`
  - `domain/usecases/build_menu.dart` — `BuildMenu` (pure): the tabs
    (every section, in order; one without drinks is coming soon), the open
    tab (the first with drinks when none is chosen or it vanished in a
    sync), its chips (only categories with drinks) and sections, and the
    drink of the day from the open tab (stable for a day, by date).
  - `presentation/menu_controller.dart` — `selectedTabProvider`,
    `menuProvider` (rebuilds when the catalog syncs), `todayProvider`.
  - `presentation/menu_page.dart` → `menu_view.dart` (Main artboard);
    widgets `DrinkCard` (`core/widgets/drink_card.dart`), `DrinkOfTheDay`.
  - The «يعني» line: `CatalogItem.gist(arabic:)` — `gist_ar` / `gist_en`
    from `catalog_sync`, or the explanation's first sentence until a drink
    has one.
  - Shared: `core/widgets/category_chips.dart`, `core/widgets/drink_photo.dart`
    (cached photo or brand gradient + initial), `core/backend/media.dart`
    (public Storage URLs), `AppGlass(minimal: true)` for many cards.
- State: Riverpod.
- Data sources: the device copy from `catalog_sync` (no network calls).
- Routes / deep links: `/` (inside `CatalogSyncPage`).

## Analytics events
| Event | When | Properties |
|---|---|---|
| `menu_section_selected` | a section is opened in the switch | `section` (slug), `coming_soon` (bool: it has no items yet; tells us how many people look for desserts) |
| `menu_category_selected` | a chip is tapped (the list scrolls to it) | `category` (slug) |

## Feature flags
None.

## Tests
- Unit: `test/features/browse_menu/domain/usecases/build_menu_test.dart` —
  the first section with drinks opens, a section without drinks is coming
  soon, a vanished section falls back, desserts go live with their first
  item, empty categories get no chip.
- Widget: `test/features/browse_menu/presentation/menu_page_test.dart` —
  states (loading, empty, coming soon), the switch, a chip scrolling to its
  category and lighting up in the pinned row, the pinned row hiding again,
  one section without a switch,
  `DrinkCard` (name, spelling, «يعني» line and its fallback, no price,
  cards in a row line up, press feedback and Reduce Motion, one
  screen-reader label), the entry stagger, Arabic / dark / small phone
  with 1.3× text / tablet, `expectAccessible`.
- Integration (demo): `integration_test/browse_menu_test.dart`.

## Decisions & edge cases
- Photos: cards and the drink of the day load the **thumbnail**
  (`DrinkPhoto(size: PhotoSize.thumbnail)` → `<name>.thumb.webp`, ~35 KB),
  falling back to the full photo when it's missing (docs/content.md →
  Photos and thumbnails). Decoded at the card's size on screen
  (`memCacheWidth`), cached on the phone after the first view
  (`MediaCache`), so seen photos work offline; none yet → brand gradient +
  first letter.
- Card layout: the name and its spelling sit at the bottom of the photo
  over a soft espresso shadow (`AppColors.photoScrim`, a gradient, no box;
  darker with Reduce Transparency / Increase Contrast), and the «يعني» line
  sits under the photo on the solid surface. Glass only on the controls
  (play, later the heart), so there's no blur per card and 40+ cards scroll
  smoothly on mid-range Android.
- The «يعني» line is never cut: no line limit, because the database caps
  it at 60 characters and the content guide aims for ~30 (two lines). It
  always takes at least two lines, so the cards in a row line up.
- Card type: `TextRole.cardTitle` (15) for the name, `TextRole.cardBody`
  (13) for the spelling and the «يعني» line.
- Motion (`AppMotion`, all off with Reduce Motion): the first 8 cards rise
  in one after another (`AppReveal`, 280 ms, 45 ms apart, once); a card
  shrinks to 0.97 while pressed (`AppPressable`; a scroll cancels it); its
  photo flies into the drink page (`Hero`, `DrinkCard.heroTag`, Home grid
  only so a tag is never on screen twice).
- The search field in the header opens `smart_search`.
- The speaker button (`pronunciation`, through `MenuView.cardAction`) sits
  in the drink of the day's top-end corner and each card's top-start
  corner, for drinks that have a clip; it plays without opening the drink.
- Header: the app's own name («يعني إيه؟») instead of «المنيو», so the
  same band works for any section; behind it the mashrabiya pattern
  (`HeaderPattern`, drawn, faint `AppColors.headerPattern`, left out in the
  flat Reduce Transparency / Increase Contrast band). Sections switch:
  `AppSegmentedControl`, shown when there are two or more sections. No
  «الكل» chip: the whole section is one list and chips jump within it.
- The list is built at once (not lazily), so a chip can scroll to any
  category and the highlight can follow them all; a section is ~40 cards.
  Positions come from the viewport (`getOffsetToReveal`), so they're right
  even for off-screen categories.
- Selected chips and the switch's selected option are warm milk
  (`AppColors.selected`) in both themes: pure white looked pasted on the
  espresso band and glared in dark mode; the page colour fails in dark
  (1.3:1 against the band).
- From `favorites`: the heart in each card's top-end corner, the long-press
  preview (`MenuView.onPreviewItem`) and the floating tab bar, which Home
  sits under (its list ends `AppDimens.tabBarHeight` higher). Cards and the
  drink of the day open the drink (`item_details`). The grid is the shared
  `DrinkGrid` (`core/widgets/drink_grid.dart`), the same as Favorites.
- Calories and prices are labelled approximate at the end of the list.

## Demo & post
**Hook (first 2 seconds):** «منيو الكافيه… بس مفهوم» / "A café menu… that finally makes sense."

**Scenario (what the integration test shows, with beat() pauses):**
1. Home opens: the cards rise in after the drink of the day.
2. Scroll through the cards: every name with its Arabic spelling.
3. Flat White: «يعني قهوة باللبن تقيلة في فنجان صغير». Tap it, the photo flies
   into its page; back.
4. Tap «قهوة ساقعة»: the list scrolls there; the chips stay pinned on top.
5. Back up, tap «حلويات»: «جاية قريب»; «شوف المتاح دلوقتي» brings the
   drinks back.

**Caption (English):** Every drink on a café menu, explained in words you
already know: a frappé is coffee and milk blended with ice, a flat white is strong milky
coffee in a small cup. The name exactly as the menu prints it, how to say it, and
what it is. Flutter, Liquid Glass controls, content in Supabase.

**Caption (Egyptian Arabic):** كل مشروب في منيو الكافيه بكلام إنت عارفه:
الفرابيه يعني قهوة باللبن والتلج في الخلاط، والفلات وايت يعني قهوة باللبن تقيلة في فنجان
صغير.
الاسم زي ما هو مكتوب، بيتقال إزاي، ويعني إيه.

**Hashtags:** #flutter #buildinpublic #liquidglass #supabase #yaanieh
