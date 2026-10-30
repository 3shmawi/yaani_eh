# Content (menu data)

Everything the app explains lives in Supabase and is edited in **Supabase
Studio** (the dashboard → Table editor). The app downloads it once, then
syncs only what changed, so content changes never need an app release.

## Tables (`supabase/migrations/0002_catalog.sql`)

| Table | What it holds |
|---|---|
| `categories` | Roots are **sections** (`cafe` now; restaurants later). Children are the chips (Coffee, Frappés…). The section's `trait_schema` drives the taste quiz and the trait pills. |
| `items` | One drink (later: dish, dessert). Menu name as written on menus + Arabic spelling, short explanations (≤ 300 chars), calories, size, price range in EGP, photo and audio paths, `traits`. |
| `item_terms` | Extra search words per item: `ar`, `en` or `franco` (e.g. `2ahwa`). |
| `catalog_tombstones` | Filled automatically when you delete a row; the app reads it through `catalog_removed_since`. |

The app (`anon`) can only **read published** rows. Nothing can be written
from the app: only Studio / the service role.

## Everyday edits

- **Add a drink:** insert a row in `items` (pick its `category_id`), then add
  its search words in `item_terms`. It shows up in the app on the next
  launch or resume.
- **Hide a drink:** set `is_published` to false (or delete the row). The app
  removes it on the next sync.
- **Prices:** fill `price_min_egp`, `price_max_egp` and `price_updated_at`.
  The app shows a "price may be old" note after 3 months.
- **Photos:** every drink has a photo and a thumbnail, side by side in the
  `item-images` bucket. See [Photos and thumbnails](#photos-and-thumbnails).
- **Pronunciation:** upload to `item-audio`, then fill `audio_barista_path`
  and/or `audio_original_path`. A missing clip just hides its button.
- **Names:** the menu name stays exactly as menus print it. Trademarked
  names (Frappuccino, Oreo…) may only be search terms, never item names.

## Photos and thumbnails

| File | Size | Shown on |
|---|---|---|
| `latte.webp` (the photo) | WebP, 1200×1600 (3:4), < 300 KB | the drink page |
| `latte.thumb.webp` (its thumbnail) | WebP, 400 px wide (3:4), ≤ 40 KB (usually 30–40) | cards: Home, search, similar drinks |

**Naming:** the thumbnail sits in the same folder as its photo, with
`.thumb.webp` in place of the photo's extension: `latte.webp` →
`latte.thumb.webp`, `cafe/flat_white.jpg` → `cafe/flat_white.thumb.webp`.
The app works the thumbnail's name out from `image_path`
(`MediaUrls.thumbnailPath`), so the database only holds the photo's path.

**Adding or changing a photo:**
1. The photo: WebP, 1200×1600, < 300 KB — own photos or
   Pexels/Unsplash-licensed; no café logos, branded cups or faces.
2. Make its thumbnail (needs `cwebp`: `brew install webp` / `apt install webp`):
   ```bash
   ./scripts/make_thumbnails.sh path/to/photos      # a folder, or files
   ```
   It writes `<name>.thumb.webp` next to each photo (400 px wide, metadata
   removed, quality lowered until ≤ 40 KB), skips thumbnails that are newer
   than their photo (`--force` remakes them) and warns about any that stay
   over 40 KB.
3. Upload **both** files to `item-images` (same folder), then put the
   photo's path (e.g. `latte.webp`) in `image_path`. Changing a photo: upload
   both again under the same names.

**A thumbnail is missing:** cards fall back to the full photo (slower, more
data) and stop asking for that thumbnail until the app restarts. Nothing
breaks, but upload the thumbnail. **The photo is missing:** the drink page
shows the thumbnail; with neither, the brand gradient and first letter.

Both are cached on the phone after the first view (up to 600 files, kept
180 days after last use), so photos already seen still show offline.

## Launch content

`supabase/content/drinks.csv` (41 drinks, reviewed) → `python3
supabase/content/build_seed.py` → `supabase/migrations/0003_seed_drinks.sql`.
It runs once on deploy and never overwrites later edits in Studio. After
launch, edit in Studio — not in the CSV.

## Rules that are tested (`supabase/tests/catalog_rls.test.sql`)

RLS on every table; anon sees only published rows and can't write; hidden and
deleted rows reach the app as ids only; editing an item or its search words
bumps `updated_at`; too-long, empty, negative, upside-down or injection-like
values are rejected.
