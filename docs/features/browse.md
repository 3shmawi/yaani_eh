# Feature: browse (Home)

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
Home opens on the items (docs/decisions/0006-home-section-tabs.md): the
espresso band with the app's name, search and the **section tabs**
(«مشروبات»، «حلويات»، later «مصطلحات»، «تاريخ»…) in a row that scrolls
sideways, with a grid button before them that lists every section; under
the band, on the page, the open section's **category chips** («الكل» first,
which goes back to the top); then its
item of the day (its name and «يعني» line in a small label at the bottom
edge of the photo) and its items as cards. The first section with items is
open at launch, so there's no tap before the first drink. Sections come
from the backend, so a new one is a new tab with no app update; one
without items yet says «جاي قريب».

`/section/<slug>` is the same body on its own page, with a back button
(deep links, the old address). Each card answers «يعني إيه؟» at a glance:

1. the photo (recognise it),
2. the name exactly as menus print it (find it),
3. its Arabic spelling (say it),
4. the «يعني» line, what it is in everyday words, e.g. «فرابيه يعني ميلك
   شيك بالقهوة» (understand it).

No price anywhere: the app explains what a thing is, not its cost.

## User flows
1. Open the app → Home: search, the section tabs, the open section's chips,
   its item of the day and its first cards. Scroll on: the next page of
   cards is added before you reach the end.
2. Tap the grid button → a sheet with every section; tap a chip → the list scrolls to that category (a category past the
   cards built so far is built first). Scrolling on, the highlighted chip
   follows; once the band has scrolled away, the chips and search stay
   pinned at the top. Tap the pinned search button: it grows into a
   full-width field like iOS (the chips fade away), then the search
   screen opens (`ExpandingSearchBar`, `core/widgets/`; with Reduce Motion
   it just opens).
3. Tap the «حلويات» tab (no desserts yet) → «حلويات: جاي قريب», the tabs
   stay so «مشروبات» is one tap away. Picking a tab starts that section
   at the top.
4. Scroll Home → the chips and search stay pinned at the top.
5. Offline → same screens from the device, with the offline pill.

## Architecture
- Layers / main files: `lib/features/browse/`
  - `domain/usecases/build_browse.dart` (pure):
    - `BuildHub` → `HubModel`: every section in order as a `HubSection`
      (its count of items; 0 = coming soon): Home's tabs.
    - `BuildBrowse` → `BrowseModel?` for one section by slug (null if no
      section has it): its chips (only categories with items), their
      items, and the section's item of the day. Pages:
      `BrowseModel.firstItems(limit)` (the first `limit` items across the
      categories, `pageSize` = 24 a page) and `limitFor(categoryId)` (how
      many to build so a chip's category is on the list).
  - `presentation/browse_controller.dart` — `hubProvider` (the tabs),
    `homePickedSectionProvider` (the tab picked, lasts while the app runs),
    `homeSectionSlugProvider` (the picked one, else the first section with
    items, else the first), `sectionProvider(slug)` (`SectionLoading` /
    `SectionMissing` / `SectionNone` / `SectionReady`), `todayProvider`,
    analytics helpers.
  - `presentation/browse_page.dart` (Home) → `section_view.dart` with
    `home: true` and `widgets/section_tabs.dart` in the band;
    `widgets/item_of_the_day.dart`.
  - `presentation/section_page.dart` → `section_view.dart` (one section,
    with back); `ItemCard` (`core/widgets/item_card.dart`).
  - The «يعني» line: `CatalogItem.gist(arabic:)` — `gist_ar` / `gist_en`
    from `catalog_sync`, or the explanation's first sentence until an item
    has one.
  - Shared: `core/widgets/category_chips.dart`, `core/widgets/item_photo.dart`
    (cached photo or brand gradient + initial), `core/backend/media.dart`
    (public Storage URLs), `HeaderBand` / `PinnedBar`
    (`core/widgets/header_band.dart`), `AppGlass(minimal: true)` for many
    cards.
- State: Riverpod.
- Data sources: the device copy from `catalog_sync` (no network calls).
- Routes / deep links: `/` (Home) and `/section/:slug`, both in the Home
  tab's branch and inside `CatalogSyncPage`. The slug must match
  `AppRoutes.slugPattern`, or it's not-found.

## Analytics events
| Event | When | Properties |
|---|---|---|
| `browse_section_opened` | a section tab is tapped on Home (was a section card; same name and properties, so dashboards keep working) | `section` (slug), `coming_soon` (bool: it has no items yet; tells us which coming sections people want) |
| `browse_category_selected` | a chip is tapped (the list scrolls to it) | `category` (slug) |

## Feature flags
None.

## Tests
- Unit: `test/features/browse/domain/usecases/build_browse_test.dart` —
  hub: a tab per section in order with its count, an empty section is
  coming soon, a new section appears with no code change, nothing on the
  device, items outside every section left out; section: by slug, coming
  soon, desserts go live with their first item, an unknown or category
  slug is no section, empty categories get no chip, the item of the day
  stable for a day; pages: the first page is cut at 24 in menu order, a
  page crossing a category continues in the next, a limit past the end
  shows everything once, zero shows nothing, a chip past the built items
  gets a limit that reaches it.
- Widget: `test/features/browse/presentation/browse_page_test.dart` (tabs:
  one per section with the picked one selected, a tap reports its
  section, eight sections scroll sideways and the last is reachable,
  Arabic; Home: loading, the band + tabs + chips + the section's items
  with no back, a coming-soon tab and back to drinks, another section
  starts at the top, a chip still scrolls, nothing published yet, Arabic /
  dark, 320 pt with 1.6× text, iPad both ways, `expectAccessible`) and
  `section_page_test.dart` (section: header with back, count and search,
  a chip scrolling to its category and lighting up in the pinned bar,
  coming soon and unknown sections, `ItemCard`, the entry stagger, Arabic
  / dark / small phone / tablet; pages: only the first page is built, the
  next is added near the end, a tall screen fills up, a chip past the
  built items builds up to it and jumps, the last chip lights at the very
  end, `resetKey` starts again at the top, Home mode without back, no
  sections, coming soon without an action) and
  `test/core/ui/app_tap_haptics_test.dart` (a tap ticks once; scrolls and
  long presses don't).
- Security: `test/security/deep_link_test.dart` — `/section/...` hostile
  paths are not-found; real, empty and unknown sections; the tab bar and
  the Settings tab.
- Integration (demo): `integration_test/browse_test.dart`.

## Decisions & edge cases
- Photos: cards and the drink of the day load the **thumbnail**
  (`ItemPhoto(size: PhotoSize.thumbnail)` → `<name>.thumb.webp`, ~35 KB),
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
  photo flies into the drink page (`Hero`, `ItemCard.heroTag`, Home grid
  only so a tag is never on screen twice).
- The search field on Home's band (and the search button on a section's)
  opens `smart_search`. It's the band's only action: settings is a tab.
- The speaker button (`pronunciation`, through `BrowseView.cardAction`) sits
  in the drink of the day's top-end corner and each card's top-start
  corner, for drinks that have a clip; it plays without opening the drink.
- Home's band: the app's own name («يعني إيه؟»), the tagline and search;
  behind it the mashrabiya pattern (`HeaderPattern`, drawn, faint
  `AppColors.headerPattern`, left out in the flat Reduce Transparency /
  Increase Contrast band). Pulled down past the top, the band stretches
  (`HeaderOverscroll`) instead of showing the page. The old sections switch
  (`AppSegmentedControl`) is gone: it couldn't hold more than two or three
  sections (0004). No «الكل» chip: the whole section is one list and chips
  jump within it.
- Section cards: one column on a phone; on a tablet as many as fit at
  `AppDimens.sectionCardMinWidth` (2 in portrait, 3 in landscape), cards in
  a row sharing their height, the grid at most `AppDimens.hubMaxWidth`.
  The band's content (title, tagline, search) has the same width and
  edges as the hub below it, so everything starts on one line; search
  keeps a readable width (`AppDimens.readableWidth`) at the start edge,
  and so does the pinned search.
- A section link opened from outside the app has nothing under it: back
  goes Home (`context.go`).
- Items are built a page at a time (24, `BrowseModel.pageSize`): the next
  page is added when the list is within a screen and a half of its end, or
  straight away on a tall screen that isn't filled yet. A section with
  hundreds of items opens as fast as one with a few. The catalog itself
  is on the device (loaded in one go, synced in pages of 100 by
  `catalog_sync`), so this is paging what's drawn, not a network call. A
  chip past the built items builds up to its category first, then
  scrolls; the highlighted chip follows what is built, and the last chip
  lights only once every page is built. Positions come from the viewport
  (`getOffsetToReveal`).
- Home is `SectionView(home: true)`: one scroll view and one set of chips
  for Home and for `/section/<slug>`. The old hub (item of the day from
  any section, a card per section) is gone; the item of the day is now the
  open section's. Switching tab is a state change (`resetKey`), not a
  route, so the tab row keeps its place.
- Selected chips are warm milk
  (`AppColors.selected`) in both themes: pure white looked pasted on the
  espresso band and glared in dark mode; the page colour fails in dark
  (1.3:1 against the band).
- From `favorites`: the heart in each card's top-end corner, the long-press
  preview (`BrowseView.onPreviewItem`) and the floating tab bar, which Home
  sits under (its list ends `AppDimens.tabBarHeight` higher). Cards and the
  drink of the day open the drink (`item_details`). The grid is the shared
  `ItemGrid` (`core/widgets/item_grid.dart`), the same as Favorites.
- Calories are labelled approximate at the end of the list («السعرات
  تقريبية»).

## Demo & post
**Hook (first 2 seconds):** «أي حاجة مش فاهمها… في مكان واحد» / "Everything you don't get, in one place."

**Scenario (what the integration test shows, with beat() pauses):**
1. Home opens on the drinks: search and the section tabs on top, the item
   of the day, the cards rise in.
2. Scroll the cards.
3. Flat White: «يعني قهوة باللبن تقيلة في فنجان صغير». Tap it, the photo
   flies into its page; back.
4. Tap «قهوة ساقعة»: the list scrolls there; back, chips and search stay
   pinned on top.
5. Scroll back up, tap the «حلويات» tab: «جاي قريب»; the «مشروبات» tab
   brings the drinks back.

**Caption (English):** Home is now every section in one place: café drinks
today, terms and history next. Search is always on top; each section has
its own page with chips. Flutter, Liquid Glass controls, sections straight
from Supabase.

**Caption (Egyptian Arabic):** الرئيسية بقت كل الأقسام في مكان واحد:
مشروبات الكافيه دلوقتي، والمصطلحات والتاريخ جايين. البحث دايمًا فوق،
وكل قسم ليه صفحته.

**Hashtags:** #flutter #buildinpublic #liquidglass #supabase #yaanieh

### Renamed to «browse» (generic names)
The feature was `browse_menu` with `MenuPage`/`DrinkCard`; it's now
`browse` with `BrowsePage`/`ItemCard`, since Home will hold more than café
menus (terms, history). Analytics events were renamed with it
(`menu_*` → `browse_*`, `drink_*` → `item_*`, property `drink` → `item`):
dashboards must use the new names from this release on. No visual change.
