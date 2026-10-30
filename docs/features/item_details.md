# Feature: item details

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
Tapping any drink opens its page: the photo under the status bar, then a
sheet with the name exactly as menus print it and its Arabic spelling, a
plain explanation in the reader's language, trait pills (calories, hot or
iced, sweetness, milk, caffeine), the price range at cafés with the month it
was checked, and similar drinks to compare. Works offline, from the device
copy.

## User flows
1. Home → tap a card (or the drink of the day) → the drink.
2. Scroll → tap a similar drink → its page; back returns step by step.
3. A link `yaanieh://drink/flat_white` opens the drink directly (after the
   first download); back goes to Home.
4. A link to a drink that no longer exists → «مش لاقيين المشروب ده» with a
   button home.

## Architecture
- Layers / main files: `lib/features/item_details/`
  - `domain/usecases/describe_item.dart` — `DescribeItem` (trait pills
    from the section's `trait_schema`: `enum` / `scale` / `bool`, in `ar`
    or `en`; stale price after 90 days or when undated) and `SimilarItems`
    (same category first, then closest temperature / sweetness / milk /
    caffeine).
  - `presentation/drink_controller.dart` — `drinkDetailsProvider(slug)`:
    `DrinkLoading` / `DrinkMissing` / `DrinkFound` (walks up to the section
    for the schema).
  - `presentation/drink_page.dart` → `drink_view.dart` (Details artboard),
    `widgets/trait_pills.dart`.
- State: Riverpod (derived from the catalog streams; updates after a sync).
- Data sources: the device copy from `catalog_sync`.
- Routes / deep links: `/drink/:slug` (`AppRoutes.drink(slug)`), wrapped in
  `CatalogSyncPage`. Slugs must match `^[a-z0-9_]{1,60}$` (same rule as the
  database); anything else is the not-found page.

## Analytics events
| Event | When | Properties |
|---|---|---|
| `drink_viewed` | a drink page opens | `drink` (slug) |

## Feature flags
None.

## Tests
- Unit: `test/features/item_details/domain/usecases/describe_item_test.dart`
  — labels in both languages, unknown types and hostile schemas ignored,
  price freshness, similar drinks.
- Widget: `test/features/item_details/presentation/drink_page_test.dart` —
  content, Arabic RTL, stale / missing price, back and similar taps, dark,
  small phone with 1.3× text, missing drink, `expectAccessible`.
- Security: `test/security/deep_link_test.dart` — traversal, script tags,
  SQL-like and oversized slugs land on not-found; a real slug opens the
  drink; an unknown one shows the missing state.
- Integration (demo): `integration_test/item_details_test.dart`.

## Decisions & edge cases
- The photo at the top is the **full** photo (`PhotoSize.full`, 1200×1600),
  decoded at the screen's width; its thumbnail (usually cached from the
  card) shows while it loads, and offline when the full photo was never
  downloaded. Similar-drink cards use thumbnails. See docs/content.md →
  Photos and thumbnails.
- The heart (`favorites`) and the pronunciation pill (`pronunciation`) join
  this screen with their features.
- "Average of N cafés" from the design needs a café count in the data; for
  now the card shows the month the price was checked.
- Month names come from `intl`; the year stays in Western digits, as menus
  print it.

## Demo & post
**Hook (first 2 seconds):** «يعني إيه فلات وايت؟» / "What even is a flat white?"

**Scenario (what the integration test shows, with beat() pauses):**
1. Home → find Flat White among the cards → tap it.
2. Read: the plain explanation, calories, hot, with milk, strong.
3. Scroll to similar drinks → tap one.
4. Back, back → the menu.

**Caption (English):** Tap any drink and get it in one breath: what it is,
how it differs from its neighbour, calories, hot or iced, milk or not, and
what cafés charge. Traits come from data, so desserts will bring their own.

**Caption (Egyptian Arabic):** دوس على أي مشروب وافهمه في نفَس واحد: هو إيه،
فرقه إيه عن اللي جنبه، سعراته، سخن ولا ساقع، بلبن ولا لأ، وسعره في
الكافيهات.

**Hashtags:** #flutter #buildinpublic #arabic #yaanieh
