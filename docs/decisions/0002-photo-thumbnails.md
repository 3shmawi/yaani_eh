# 0002 — Drink photo thumbnails as files

Date: 2026-10-30 · Status: accepted

## Context
Cards (Home, search, similar drinks) loaded the full 1200×1600 photo
(< 300 KB each) and decoded it at full size: slow on mobile data, heavy on
phone memory with 40+ cards.

## Decision
- A second file per photo, `<name>.thumb.webp` (400 px wide, ≤ 40 KB), next
  to it in `item-images`, made by `scripts/make_thumbnails.sh` (cwebp).
  The app derives the name from `image_path`; no database change.
- Cards load the thumbnail, the drink page the full photo; each falls back
  to the other. Thumbnails that answer 4xx aren't asked for again in the
  session.
- Images are decoded at the size they're shown (`memCacheWidth` only, so
  the photo keeps its shape) and cached in a dedicated `MediaCache`
  (600 files, 180 days) for offline use.

## Alternatives
- **Supabase Storage image transformations** (resize on request): not on
  the Free plan, billed per origin image, and every size is a new URL to
  cache. Files we make once are free and work with any CDN.
- **One smaller photo for everything:** the drink page would look soft on
  large phones and tablets.

## Revisit when
The project moves to a paid Supabase plan with transformations, or photos
change often enough that making thumbnails by hand is a chore (then: a
Storage webhook or CI job that makes them on upload).

Checked 2026-10-30: cached_network_image 4.0.6 / flutter_cache_manager 3.4.6
(pub.dev changelogs), libwebp 1.6.0 (`-resize_mode`, NEWS on GitHub).
