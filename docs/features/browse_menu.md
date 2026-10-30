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
| `menu_category_selected` | a chip or «شوف الكل» is tapped | `category` (slug, or `all`) |

## Feature flags
None.

## Tests
- Unit: `test/features/browse_menu/domain/usecases/build_menu_test.dart`.
- Widget: `test/features/browse_menu/presentation/menu_page_test.dart` —
  states (loading, empty, all, one category), chips and «شوف الكل»,
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
- Card layout ("caption below", chosen over a frosted label, a photo
  scrim and list rows): glass only on the controls over the photo (play,
  later the heart), the text on the solid surface. Text always reads, in
  light, dark and with large text, and there's no blur per card, so 40+
  cards scroll smoothly on mid-range Android.
- Card type: `TextRole.cardTitle` (15) for the name, `TextRole.cardBody`
  (13) for the spelling and the «يعني» line. The line always takes two
  lines of space, so the cards in a row line up.
- Motion (`AppMotion`, all off with Reduce Motion): the first 8 cards rise
  in one after another (`AppReveal`, 280 ms, 45 ms apart, once); a card
  shrinks to 0.97 while pressed (`AppPressable`; a scroll cancels it); its
  photo flies into the drink page (`Hero`, `DrinkCard.heroTag`, Home grid
  only so a tag is never on screen twice).
- The search field in the header opens `smart_search`.
- The speaker button (`pronunciation`, through `MenuView.cardAction`) sits
  in the drink of the day's top-end corner and each card's top-start
  corner, for drinks that have a clip; it plays without opening the drink.
- Not here yet, each comes with its feature: hearts (`favorites`, the
  cards' top-end corner) and the tab bar (once a second tab exists). Cards
  and the drink of the day open the drink (`item_details`).
- Calories and prices are labelled approximate at the end of the list.

## Demo & post
**Hook (first 2 seconds):** «منيو الكافيه… بس مفهوم» / "A café menu… that finally makes sense."

**Scenario (what the integration test shows, with beat() pauses):**
1. Home opens: the cards rise in after the drink of the day.
2. Scroll through the cards: every name with its Arabic spelling.
3. Flat White: «يعني قهوة باللبن تقيلة في فنجان صغير». Tap it, the photo flies
   into its page; back.
4. Tap «قهوة ساقعة»: only iced coffee.
5. Tap «الكل»: everything again.

**Caption (English):** Every drink on a café menu, explained in words you
already know: a frappé is a coffee milkshake, a flat white is strong milky
coffee in a small cup. The name exactly as the menu prints it, how to say it, and
what it is. Flutter, Liquid Glass controls, content in Supabase.

**Caption (Egyptian Arabic):** كل مشروب في منيو الكافيه بكلام إنت عارفه:
الفرابيه يعني ميلك شيك بالقهوة، والفلات وايت يعني قهوة باللبن تقيلة في فنجان
صغير.
الاسم زي ما هو مكتوب، بيتقال إزاي، ويعني إيه.

**Hashtags:** #flutter #buildinpublic #liquidglass #supabase #yaanieh
