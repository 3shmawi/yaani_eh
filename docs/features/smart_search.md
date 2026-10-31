# Feature: smart search

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
One field that understands both directions. Type a name («فرابيه»,
`cortado`, one typo allowed) and an answer card says what it is right away.
Type a description ("milk foam", «لبن وقهوة», `laban w ahwa`) and get the
drinks that match, with the matched words highlighted. Arabic, English and
Franco, offline, on the device copy of the menu. Nothing found → «مالقيناش
"…"» with «يمكن تقصد» suggestions.

## User flows
1. Home → the search field in the header → `/search` (keyboard up).
2. Before typing: what search understands, with example queries to tap.
3. A name → AnswerCard («إنت كتبت "…"», name = explanation, pills,
   «التفاصيل») + related drinks below.
4. A description → «N مشروب لـ"…"» + ranked rows (photo, name, spelling,
   explanation with highlights, calories; prices are hidden).
5. Tap anything → the drink (`/drink/:slug`); back returns to the results.
6. Links: `yaanieh://search?q=latte` opens search pre-filled.

## Architecture
- Layers / main files: `lib/features/smart_search/`
  - `domain/entities/search_text.dart` — normalization (أ/إ/آ/ٱ→ا, ة→ه,
    ى→ي, ؤ→و, ئ→ي, diacritics and tatweel removed, Latin lowercase without
    accents, Franco digits kept), light Arabic prefixes (و، ال، بال، لل، ب),
    word positions, Levenshtein, word matching (exact 1, prefix 0.8, one
    typo 0.6 for words of 4+ letters).
  - `domain/usecases/search_menu.dart` — `SearchMenu` (index built once per
    catalog change): names weigh 3×, descriptions 1×; 1–2 words must all
    match, longer queries 60%; a query that starts a name gets a bonus; an
    exact name (or one typo) becomes the answer; `SearchBoosts` multiplies
    the score (`text × (1 + boost)`) — favorites, taste and recently viewed
    plug in there with their features. Queries are capped at 60 characters
    and 8 words.
  - `presentation/` — `search_controller.dart` (index, query, results
    providers), `search_page.dart` (150 ms debounce) → `search_view.dart`;
    widgets `AnswerCard`, `ResultRow` (+ `highlighted`).
  - Shared: `core/widgets/search_field.dart` (input and Home entry point).
- State: Riverpod.
- Data sources: the device copy (`catalog_sync`): names, Arabic spellings,
  explanations in both languages and `item_terms`.
- Routes / deep links: `/search?q=` (`AppRoutes.searchFor`); `q` goes
  through `AppRoutes.cleanQuery` (control/direction characters removed,
  trimmed, ≤ 60).

## Analytics events
| Event | When | Properties |
|---|---|---|
| `search_result_opened` | a result is opened | `from` (`answer`/`list`/`suggestion`), `position` |
| `search_no_results` | a query finds nothing | `length` (never the text) |

## Feature flags
None.

## Tests
- Unit: `test/features/smart_search/domain/search_menu_test.dart` —
  normalization, prefixes, matching, answers in any script, typos, Franco,
  descriptions, boosts, "did you mean", hostile queries (SQL-like, script
  tags, 10 000 chars, emoji, bidi overrides, regex characters, tatweel).
- Widget: `test/features/smart_search/presentation/search_page_test.dart` —
  idle, answer, list with highlights, nothing found, clear, pre-filled link,
  Arabic, dark, hostile typing, 60-character limit, `cleanQuery`.
- Security: `test/security/deep_link_test.dart` — hostile `q` values.
- Integration (demo): `integration_test/smart_search_test.dart`.

## Decisions & edge cases
- Result rows show the drink's **thumbnail** (`PhotoSize.thumbnail`), decoded
  at the row's size, full photo as fallback. The photo is a layer that
  fills the row's height, so rows are laid out once (no `IntrinsicHeight`).
- No server search: the catalog is small and on the device, so search is
  instant and offline; the index rebuilds when a sync changes the menu.
- The tab bar (Home / Search / Favorites / My taste) arrives with
  `favorites`; until then search opens from the Home header.
- «ابعته» (send us the drink) on the empty state comes with
  `suggest_item`.

## Demo & post
**Hook (first 2 seconds):** «كتبت لبن ورغوة…» / "I typed 'milk and foam'…"

**Scenario (what the integration test shows, with beat() pauses):**
1. Home → tap the search field.
2. Type `cortado` → the answer card: what it is, at once.
3. Clear, type `milk foam` → latte, cappuccino… with the words highlighted.
4. Open the first result.

**Caption (English):** Don't know the name? Describe it. Search works both
ways — type a name and get the answer, or type what you want and get the
drinks that match. Arabic, English or Franco, with typos, offline.

**Caption (Egyptian Arabic):** مش عارف الاسم؟ اوصفه. البحث بيشتغل في
الاتجاهين: اكتب اسم وخد الإجابة، أو اكتب اللي نفسك فيه وخد المشروبات اللي
شبهه. عربي أو إنجليزي أو فرانكو، وحتى لو غلطت في الكتابة، ومن غير نت.

**Hashtags:** #flutter #buildinpublic #arabic #search #yaanieh
