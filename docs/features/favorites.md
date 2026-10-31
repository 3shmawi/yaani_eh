# Feature: favorites

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
Save the drinks you like and find them again in one tap. Every card has a
heart in its top-end corner, and so does the drink page. Saved drinks live
in a new **Favorites** tab, which brings the app's floating glass tab bar
(«المنيو | المفضلة»), with a count of what's saved. Saved drinks stay on
the phone: no account, they work offline, and deleting the app deletes them.

A **long press** on any card opens a quick preview that answers «يعني إيه؟»
without leaving the menu: the photo, the name, its spelling, the «يعني» line
and the start of the explanation, with «اسمع الاسم», «طريقة التحضير» (with
a «جديد» tag; feature `recipes`), «احفظ في المفضلة» / «شيل من المفضلة» and
«افتح المشروب».

## User flows
1. Tap the heart on a card → it turns warm milk and pops; the Favorites tab
   counts one more. Tap again → removed.
2. Long-press a card → the page blurs, the preview opens; choose a row, or
   tap outside to close.
3. Open the Favorites tab → the saved drinks, newest first, as the same
   cards as Home (play, heart, long press, open).
4. Nothing saved → «لسه محفظتش حاجة» with «شوف المنيو».
5. Offline → everything still works (it's all on the phone).

## Architecture
- Layers / main files: `lib/features/favorites/`
  - `domain/`: `Favorite`, `FavoritesRepository` (watch, add, remove),
    `FavoriteDrinks` (saved drinks still on the menu, newest first).
  - `data/`: `FavoritesDatabase` (its own drift file `favorites`, apart from
    the menu copy, so a menu resync never touches it) and
    `FavoritesRepositoryImpl` (`guard`, no retries: it's local). Saving
    twice keeps the first date. Dates are kept to the second, so two drinks
    saved in the same second come back last-saved first (by row id).
  - `presentation/`: `favorites_controller.dart` (`favoritesProvider`,
    `favoriteIdsProvider`, `favoriteDrinksProvider`,
    `FavoritesController.toggle`), `FavoriteButton`, `FavoritesPage` →
    `FavoritesView`, `drink_preview.dart` (`showDrinkPreview`,
    `DrinkPreview`).
- Shared building blocks (`lib/core/`):
  - `AppTabScaffold` + `AppTab` (`app_ui.dart`): the glass tab bar
    (`GlassTabBar.bottom`), with a count badge.
  - `showAppPreviewMenu` + `AppPreviewAction` (`app_ui.dart`): the
    long-press preview.
  - `AppIconButton(selectedLook: AppSelectedLook.chosen)`: the saved heart.
  - `DrinkGrid` (`core/widgets/drink_grid.dart`): the cards of Home and
    Favorites.
  - `DrinkCard.trailingAction` / `onLongPress`.
- Tabs: `app/app_tabs_shell.dart`, a `StatefulShellRoute` in
  `app_router.dart` with one navigator per tab, so each keeps its scroll.
  Drink, search and settings pages cover the tab bar.
- State: Riverpod.
- Data sources: on the phone only (`favorites` SQLite file). The drinks
  themselves come from `catalog_sync`.
- Routes / deep links: `/favorites` (docs/deep_links.md).

## Analytics events
| Event | When | Properties |
|---|---|---|
| `favorite_added` | a drink is saved | `drink` (slug), `from` (`card`, `drinkPage`, `preview`, `favorites`) |
| `favorite_removed` | a drink is removed | `drink`, `from` |
| `drink_previewed` | the long-press preview opens | `drink` |

## Feature flags
None.

## Tests
- Unit: `test/features/favorites/data/repositories/favorites_repository_impl_test.dart`
  (fresh install, newest first, remove, saving twice keeps the first date,
  the stream follows every change, an injection-like id stays data),
  `test/features/favorites/domain/favorite_drinks_test.dart`.
- Widget: `test/features/favorites/presentation/favorites_test.dart` — the
  heart (save, remove, labels, the chosen look, a failed write changes
  nothing), Favorites (loading, empty with its way back, cards and count,
  Arabic / dark, small phone with 1.3× text, tablet, `expectAccessible`),
  newest first and un-hearting takes a card off, the preview (contents,
  save, open, «hear» only with a clip, tap outside closes).
- Security: `test/security/deep_link_test.dart` — `/favorites` opens the
  tab (with crafted queries too), crafted `/favorites/…` paths show
  not-found, and the tab bar switches tabs, counts saved drinks and is
  covered by a drink page.
- Integration (demo): `integration_test/favorites_test.dart`.

## Decisions & edge cases
- **On the phone only.** No accounts yet, so nothing to sync. When accounts
  arrive, favorites can move to Supabase (with RLS) and the local ones be
  uploaded once. The privacy policy says they stay on the phone.
- **The saved heart is warm milk with an espresso heart** (`AppColors.selected`),
  like a selected chip. Red looked like a stain on coffee photos and was the
  only red in the app (compared in https://claude.ai/artifact/5pzpJCAdghkuTqHCNBotax).
- **The long press is our own glass overlay**, the same on iOS and Android.
  The iOS system context menu copies the card, Hero and all, into an
  overlay, which would put two Heroes with one tag on screen.
- **Heroes and tabs:** both tabs stay mounted, and a saved drink is on Home
  too, with the same Hero tag. Only the tab on screen has heroes enabled
  (`HeroMode` in `navigatorContainerBuilder`), so the photo flies from the
  card you tapped, and the tags never clash.
- A saved drink that's hidden or removed in a sync drops out of the tab, and
  comes back if it's published again (its id stays saved).
- `favoriteIdsProvider` is always listened to while the app runs (the tab
  bar's count), so a heart or the preview never reads a stale list.
- The drink of the day has no heart yet: its top-end corner is the play
  button (Home artboard).

## Demo & post
**Hook (first 2 seconds):** «احفظ اللي عجبك» / "Keep the ones you like."

**Scenario (what the integration test shows, with beat() pauses):**
1. Long-press Flat White: the page blurs and the preview says what it is.
2. «احفظ في المفضلة».
3. Heart Espresso right on its card; the tab bar counts 2.
4. Open the Favorites tab: Espresso, then Flat White.
5. Open Flat White, its photo flies in; back.
6. Un-heart both: «لسه محفظتش حاجة»; «شوف المنيو» goes back to the menu.

**Caption (English):** Long-press any drink to see what it is without
leaving the menu, then keep the ones you like. Favorites stay on your phone,
work offline, and need no account. A floating Liquid Glass tab bar in
Flutter.

**Caption (Egyptian Arabic):** دوس مطوّل على أي مشروب تعرف يعني إيه من غير ما
تسيب المنيو، واحفظ اللي عجبك. المفضلة على موبايلك، شغالة من غير نت، ومن غير
حساب.

**Hashtags:** #flutter #buildinpublic #liquidglass #yaanieh
