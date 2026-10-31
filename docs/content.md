# Content (menu data)

Everything the app explains lives in Supabase and is edited in **Supabase
Studio** (the dashboard → Table editor). The app downloads it once, then
syncs only what changed, so content changes never need an app release.

## Tables (`supabase/migrations/0002_catalog.sql`)

| Table | What it holds |
|---|---|
| `categories` | Roots are **sections**, the Home switch: `cafe` («مشروبات / Drinks») and `desserts` («حلويات», no items yet; `0005_menu_sections.sql`). Children are the chips (Coffee, Frappés…). A section with no published items shows as «قريبًا» and goes live with its first item, no app update. The section's `trait_schema` drives the taste quiz and the trait pills. |
| `items` | One drink (later: dish, dessert). Menu name as written on menus + Arabic spelling, short explanations (≤ 300 chars), the «يعني» line (`gist_ar` / `gist_en`, ≤ 60 chars, `0004_item_gist.sql`), calories, size, price range in EGP, photo and audio paths, `traits`. |
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
- **Prices:** `price_min_egp`, `price_max_egp` and `price_updated_at` still
  sync, but the app doesn't show them (`AppContent.showPrices`). Leave them
  empty for new drinks.
- **«طريقة التحضير»** (`recipe`): see [Recipes](#recipes).
- **Photos:** every drink has a photo and a thumbnail, side by side in the
  `item-images` bucket. See [Photos and thumbnails](#photos-and-thumbnails).
- **Pronunciation:** see [Pronunciation clips](#pronunciation-clips).
- **The «يعني» line** (`gist_ar`, `gist_en`): what the drink is, in words
  everyone already knows, shown on its card after «يعني». About 30
  characters (60 at most). Say what it's made of: «قهوة باللبن والتلج
  في الخلاط», not «إسبريسو متخفوق». Words people don't say every day
  («متخفوق») count as menu words too. Another menu word never counts as
  familiar, even «لاتيه» or «ميلك شيك»: say «قهوة باللبن تقيلة», not «زي
  اللاتيه بس أقوى». Compare to what people already drink at home when you
  can («قهوة الكنكة»). Everyday words like «شاي أخضر», «آيس كريم» or
  «كراميل» are fine. Empty: the card shows the explanation's first
  sentence. The lines live in `supabase/content/drinks.csv`;
  `build_seed.py` refuses a line with a menu word (`MENU_WORDS`), and the
  pgTAP tests check the database too. `0004_item_gist.sql` filled the
  launch lines and is never rewritten: a change to a line in the CSV also
  needs a new migration, like `0006_item_gist_everyday_words.sql`.
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

## Pronunciation clips

Each drink can have two short recordings of its name, played by the
pronounce pill (docs/features/pronunciation.md):

| Column | Voice | Button |
|---|---|---|
| `audio_barista_path` | how baristas in Egypt say it | «زي الباريستا» (and the cards' speaker) |
| `audio_original_path` | the original Italian / English | «الأصلي» |

- **Format:** M4A (AAC) or MP3, mono, about 64 kbps, 1–3 seconds, under
  50 KB. Not Ogg: the bucket accepts it but iPhones can't play it.
- **Recording:** the name alone, said once, clearly, no music or "it's
  pronounced…". Trim silence at both ends. Own recordings only.
- **Naming:** `<slug>.barista.m4a` and `<slug>.original.m4a`, e.g.
  `flat_white.barista.m4a`. Upload to the `item-audio` bucket, then put the
  path in the column. A path with `..`, a leading `/` or `//` is ignored by
  the app.
- **Missing clip:** its segment is hidden; no clips at all hides the pill
  and the cards' speaker. **Replacing a clip:** upload it under a new name
  (e.g. `flat_white.barista.2.m4a`) and update the path, so phones that
  already have the old one get the new one on the next sync.
- Phones keep a clip after the first play (and when its drink page is
  opened online), so heard names work offline.

## Recipes

`items.recipe` (JSON, `0007_item_recipes.sql`) is «طريقة التحضير»:

```json
{"minutes": 2,
 "layers": [{"tone": "espresso", "ml": 60, "ar": "قهوة مركّزة (شوتين)", "en": "Strong coffee (2 shots)"}],
 "steps": [{"icon": "grind", "title_ar": "…", "title_en": "…",
            "note_ar": "…", "note_en": "…", "amount_ar": "18 جرام بن", "amount_en": "18 g coffee"}]}
```

- **layers**, bottom to top, 1–6. Their ml add up to the drink's `size_ml`
  (the cup is drawn to scale). `tone` is the colour: `espresso`, `coffee`,
  `foam`, `water`, `milk`, `condensed`, `chocolate`, `white_chocolate`,
  `caramel`, `vanilla`, `cream`, `ice_cream`, `ice`, `blended_coffee`,
  `blended_caramel`, `blended_chocolate`, `blended_vanilla`, `tea`,
  `green_tea`, `chai`, `matcha`, `hibiscus`, `mint_tea`, `mango`,
  `strawberry`, `orange`, `lemon`, `fruit`, `berry`, `hot_chocolate`,
  `sahlab`, `nuts`, `cookies`, `soda`. An unknown tone is drawn as milky
  coffee.
- **steps**, in order, 1–8. `icon`: `grind`, `shot`, `boil`, `steep`,
  `milk`, `steam`, `pour`, `ice`, `blend`, `stir`, `sweeten`, `top`,
  `squeeze`, `serve`. Title ≤ 60, note ≤ 160, amount ≤ 40 characters; note
  and amount are optional.
- **minutes**, 1–1440 (cold brew: a night). From an hour up, the app shows
  hours.
- **Words:** like the «يعني» line, everyday Egyptian: no menu words
  («لاتيه»، «إسبريسو»…), and no number ranges (`25–30` turns around in
  Arabic): say «حوالي 30».
- The database checks the shape; the app also checks every field and, if
  anything is off, hides only «طريقة التحضير», never the drink.
- Launch recipes are in `supabase/content/recipes.json`, checked by
  `build_seed.py` (sizes add up, known tones and icons, no menu words, no
  ranges) and written once into `0007_item_recipes.sql`. After launch, edit
  them in Studio.

## Explanations

The drink page's explanation (`explanation_ar`, `explanation_en`, ≤ 300
characters) follows the same rule as the «يعني» line: words everyone
knows, never another menu word («قهوة مركّزة», not «إسبريسو»; «في الخلاط»,
not «متخفوق»). The launch texts were rewritten that way in
`supabase/content/explanations.json` → `0008_item_explanations_everyday_words.sql`
(checked by `build_seed.py`; it only replaces a text that's still the launch
one). pgTAP checks no explanation uses a menu word.

## Launch content

`supabase/content/drinks.csv` (41 drinks, reviewed) → `python3
supabase/content/build_seed.py` → `supabase/migrations/0003_seed_drinks.sql`.
It runs once on deploy and never overwrites later edits in Studio. After
launch, edit in Studio — not in the CSV.

## Rules that are tested (`supabase/tests/catalog_rls.test.sql`)

RLS on every table; anon sees only published rows and can't write; hidden and
deleted rows reach the app as ids only; editing an item or its search words
bumps `updated_at`; too-long, empty, negative, upside-down or injection-like
values are rejected; every drink has a recipe, a malformed recipe is
rejected, and anon can read recipes but not change them.
