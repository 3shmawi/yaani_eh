# 0005 — Generic items: one core, one kind of details per section

Date: 2026-11-01 · Status: accepted

## Context
«يعني إيه؟» explains any word or thing, not only café drinks. Terms
(«بيروقراطية») and history («حرب أكتوبر ١٩٧٣») come next. The data model
was drink-shaped: `recipe`, `calories`, `size_ml`, `price_*` and
`audio_barista_path` were columns on every item.

## Decision
- **Every item has the same core:** name as people see it, Arabic name,
  «يعني» line, a short explanation, an optional image and clips, and
  search terms.
- **Each section adds one kind of details** (`categories.detail_kind`):
  `recipe` (drinks: the cup + steps), `story` (history: events in order,
  then sections such as causes and results), `usage` (terms: in a
  sentence, opposite, related words). They are built from two primitives:
  steps (ordered; optional amount, date and icon) and sections (a title +
  short lines). The section names them in content (`details_title_*`).
- A new section is content only when its details fit a known kind. A new
  kind ships in an app update. Until then the app shows «حدّث التطبيق عشان
  تشوف التفاصيل» with a link to the store (`UnknownDetails`).
- `items.details` is validated per kind by `item_details_valid()` (≤ 16 KB,
  ≤ 12 steps, ≤ 6 sections of ≤ 8 lines). The app parses it just as
  strictly: broken details hide the details, never the item.
- Calories and cup size are drinks-only, so they're traits now.
- The clip is `audio_spoken_path` («زي ما بتتقال»; for drinks, the barista).
- Prices are gone from the app (they were hidden already).

## Compatibility (installed versions)
Installed app versions select `recipe`, `audio_barista_path`, `calories`,
`size_ml` and `price_*` by name, so dropping them would break their sync.
Migration 0009 only adds. A trigger (`items_legacy_columns`) keeps old and
new columns in step, from either side. After a forced update has moved
every phone past this version (`min_supported_version`), a later migration
drops the old columns and the trigger.

On the phone, drift schema v4 rebuilds `items` and moves recipe, clip and
calories over in SQL, so the offline copy keeps working. The next sync
fetches everything again.
