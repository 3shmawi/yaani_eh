# Feature: catalog sync

> Keep this page current — it is how a new developer or AI agent learns the feature.

## What it does
The whole menu lives on the phone. The first launch downloads it once (a
cup fills up while «تعرف إن…» shares a fact about a drink name); after that
the app opens instantly and works with no internet. Each time the app
starts or comes back to the foreground, it quietly downloads only what
changed in Supabase Studio: new drinks, edits, and drinks that were hidden
or deleted. No app update is ever needed for content.

## User flows
1. **First launch, online:** Loading screen (progress «24 من 60 مشروب») →
   the menu.
2. **First launch, offline:** «محتاجين نت أول مرة بس» with «جرّب تاني»; the
   app retries by itself every 30 s and as soon as the connection returns.
3. **Later launches:** the menu shows at once; a background sync updates it.
   Offline → the menu still works, with the offline pill under the header.

## Architecture
- Layers / main files: `lib/features/catalog_sync/`
  - `domain/` — `CatalogItem`, `CatalogCategory`, `ItemTerm`, `SyncProgress`,
    `SyncReport`; `CatalogRepository`; use cases `SyncCatalog`,
    `WatchCatalog`.
  - `data/` — `SupabaseCatalogRemote` (reads), `CatalogDatabase` (drift /
    SQLite on the device), `CatalogLocalDataSource`, `CatalogRows` (strict
    parsing: bad rows are skipped, never crash), `CatalogRepositoryImpl`
    (the sync).
  - `presentation/` — `CatalogSyncController` (Notifier), `CatalogSyncPage`
    (gate in front of Home), `CatalogSyncView` (Loading / Error artboards);
    `catalogItemsProvider` / `catalogCategoriesProvider` for screens.
- State: Riverpod (Notifier). States: `CatalogChecking` → `CatalogFirstLoad`
  (progress) → `CatalogReady`, or `CatalogUnavailable` (nothing cached and
  the download failed).
- Data sources: Supabase `categories`, `items`, `item_terms`, RPC
  `catalog_removed_since` (see [content](../content.md)); on the device,
  SQLite (`catalog` database) with a sync cursor.
- Routes / deep links: none new — `/` is wrapped by `CatalogSyncPage`.

### How a sync works
1. `since` = the saved cursor − 2 minutes (rows committed late aren't
   missed; saving a row twice is harmless), or the epoch the first time.
2. Categories, then items page by page (100) with their search terms; an
   item's terms are replaced together with the item.
3. Hidden and deleted rows (`catalog_removed_since`) are dropped. A hidden
   category hides its items on the device too.
4. The cursor (newest `updated_at` seen) is saved last, so an interrupted
   sync starts over from the same point and an unfinished first sync never
   counts as "the menu is on the phone".
5. Malformed rows are skipped and reported to Sentry (count only).

Syncs run at start-up, on resume (at most every 2 minutes) and, while
nothing is cached, every 30 s and on reconnect. Two calls at once share one
download.

## Analytics events
| Event | When | Properties |
|---|---|---|
| `catalog_sync_completed` | a sync finished | `first`, `changed`, `removed`, `skipped`, `duration_ms` |
| `catalog_sync_failed` | a sync failed | `first`, `reason` (failure type) |

No personal data.

## Feature flags
None.

## Tests
- Unit: `test/features/catalog_sync/data/` — the sync against an in-memory
  SQLite and a fake server (first sync, progress, paging, delta, overlap,
  term replacement, hidden/deleted items and categories, offline, an
  interrupted first sync, hostile rows); `CatalogRows` parsing.
- Controller: `presentation/catalog_sync_controller_test.dart` — states,
  30 s retry, retry button, shared sync, resume throttle.
- Widget: `presentation/catalog_sync_view_test.dart` (+ accessibility, RTL,
  dark, small phone with large text).
- Security: hostile rows (SQL-like slugs, wrong types, absurd numbers, path
  traversal in media paths) are rejected; RLS in
  `supabase/tests/catalog_rls.test.sql`.
- Integration (demo): `integration_test/catalog_sync_test.dart` —
  `DemoApp` starts the real app as a fresh install with a fake server and
  scripted connectivity.

## Decisions & edge cases
- drift (SQLite) over key-value storage: delta upserts, deletes and joins
  stay simple as sections and categories grow.
- Images and audio are cached after first view by the screens that show
  them (`browse_menu`, `item_details`, `pronunciation`), not here.
- Home (`browse_menu`) reads the menu through `catalogItemsProvider` and
  `catalogCategoriesProvider`.
- Content edits never need a release; schema changes need a migration.

## Demo & post
**Hook (first 2 seconds):** «مفيش نت في الكافيه؟ مش مشكلة» / "No internet at the café? No problem."

**Scenario (what the integration test shows, with beat() pauses):**
1. First launch: the cup fills up while the menu downloads, with a «تعرف إن…» tip.
2. The menu appears; scroll through it.
3. Airplane mode on, close the app, open it again.
4. The whole menu is still there with the offline note; scroll to the last drink.

**Caption (English):** The whole café menu lives on your phone. It downloads
once, then works with zero internet — and updates itself quietly when you're
back online. Built offline-first in Flutter: SQLite (drift) + delta sync from
Supabase by `updated_at`, with hidden and deleted items synced as ids only.

**Caption (Egyptian Arabic):** المنيو كله على موبايلك. بيتحمّل مرة واحدة، وبعد
كده يشتغل من غير نت خالص — ولما النت يرجع بيتحدّث لوحده من غير ما تحدّث
التطبيق.

**Hashtags:** #flutter #buildinpublic #offlinefirst #supabase #yaanieh
