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
- **Photos:** upload to the `item-images` bucket (WebP, 1200×1600, < 300 KB —
  own photos or Pexels/Unsplash-licensed; no café logos, branded cups or
  faces), then put the path (e.g. `latte.webp`) in `image_path`.
- **Pronunciation:** upload to `item-audio`, then fill `audio_barista_path`
  and/or `audio_original_path`. A missing clip just hides its button.
- **Names:** the menu name stays exactly as menus print it. Trademarked
  names (Frappuccino, Oreo…) may only be search terms, never item names.

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
