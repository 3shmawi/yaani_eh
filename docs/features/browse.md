# Feature: browse (Home)

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
Home is a hub (docs/decisions/0004-home-header.md): a short espresso band
with the app's name and search, the item of the day from any section,
then one card per section («مشروبات»، «حلويات»، later «مصطلحات»،
«تاريخ»…). Sections come from the backend, so a new one appears with no
app update; one without items yet says «جاي قريب».

A card opens the section's page (`/section/<slug>`): its category chips
and its items as cards. Each card answers «يعني إيه؟» at a glance:

1. the photo (recognise it),
2. the name exactly as menus print it (find it),
3. its Arabic spelling (say it),
4. the «يعني» line, what it is in everyday words, e.g. «فرابيه يعني ميلك
   شيك بالقهوة» (understand it).

No price anywhere: the app explains what a thing is, not its cost.

## User flows
1. Open the app → Home: search, the item of the day, «الأقسام» and a card
   per section (name, count, first names).
2. Tap «مشروبات» → its page: item of the day, then every category's items,
   one after another. Tap a chip → the list scrolls to that category.
   Scrolling on, the highlighted chip follows; once the band has scrolled
   away, back, the chips and search stay pinned at the top.
3. Tap «حلويات» (no desserts yet) → «حلويات: جاي قريب», with «ارجع
   للأقسام» back Home.
4. Scroll Home → search stays pinned at the top.
5. Offline → same screens from the device, with the offline pill.

## Architecture
- Layers / main files: `lib/features/browse/`
  - `domain/usecases/build_browse.dart` (pure):
    - `BuildHub` → `HubModel`: every section in order as a `HubSection`
      (count of items in its categories, first 3 as examples; 0 = coming
      soon), and the item of the day from all of them (stable for a day,
      by date).
    - `BuildBrowse` → `BrowseModel?` for one section by slug (null if no
      section has it): its chips (only categories with items), their
      items, and the section's item of the day.
  - `presentation/browse_controller.dart` — `hubProvider`,
    `sectionProvider(slug)` (`SectionLoading` / `SectionMissing` /
    `SectionReady`), `todayProvider`, analytics helpers.
  - `presentation/browse_page.dart` → `browse_view.dart` (Home hub),
    `widgets/section_card.dart`, `widgets/item_of_the_day.dart`.
  - `presentation/section_page.dart` → `section_view.dart` (one section);
    `ItemCard` (`core/widgets/item_card.dart`).
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
| `browse_section_opened` | a section card is tapped on Home (replaces `browse_section_selected`) | `section` (slug), `coming_soon` (bool: it has no items yet; tells us which coming sections people want) |
| `browse_category_selected` | a chip is tapped (the list scrolls to it) | `category` (slug) |

## Feature flags
None.

## Tests
- Unit: `test/features/browse/domain/usecases/build_browse_test.dart` —
  hub: cards in order with count and examples, an empty section is
  coming soon, a new section appears with no code change, the item of the
  day from any section, stable for a day, nothing on the device, items
  outside every section left out; section: by slug, coming soon, desserts
  go live with their first item, an unknown or category slug is no
  section, empty categories get no chip.
- Widget: `test/features/browse/presentation/browse_page_test.dart` (hub:
  short band with search and no settings, a card per section, «جاي قريب»
  still opens, one button label per card, search pinned on scroll,
  loading / no sections / nothing published, Arabic / dark, 320 pt with
  1.6× text, iPad portrait 2 columns and landscape 3 with search at a
  readable width, the band, item of the day and sections sharing their
  start edge on iPad in English and Arabic, `expectAccessible`) and `section_page_test.dart`
  (section: header with back, count and search, a chip scrolling to its
  category and lighting up in the pinned bar with back and search, coming
  soon and unknown sections, `ItemCard`, the entry stagger, Arabic / dark
  / small phone with 1.3× text / tablet, `expectAccessible`).
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
- The list is built at once (not lazily), so a chip can scroll to any
  category and the highlight can follow them all; a section is ~40 cards.
  Positions come from the viewport (`getOffsetToReveal`), so they're right
  even for off-screen categories.
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
1. Home opens: search on top, the item of the day, then the sections.
2. Tap «مشروبات»: its page, the cards rise in.
3. Flat White: «يعني قهوة باللبن تقيلة في فنجان صغير». Tap it, the photo
   flies into its page; back.
4. Tap «قهوة ساقعة»: the list scrolls there; back, chips and search stay
   pinned on top.
5. Back Home, tap «حلويات»: «جاي قريب»; «ارجع للأقسام» brings the sections
   back.

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
