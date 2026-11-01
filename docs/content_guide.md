# Content guide

How to write an item for any section. The shapes below are checked twice,
by `supabase/content/build_seed.py` and by the database
(`item_details_valid()`, migration 0009). The app reads them just as
strictly.

## The core (every item)
| Field | Rule |
|---|---|
| `menu_name` | The name as people see it (a menu prints `Flat White`; a term is `Bureaucracy`). ≤ 80 |
| `menu_name_ar` | The Arabic name: `فلات وايت`, `بيروقراطية`. ≤ 80 |
| `gist_ar` / `gist_en` | **«يعني …» in one line**, ≤ 60 characters |
| `explanation_ar` / `_en` | A short, plain explanation, ≤ 300 |
| `terms` | Extra search words (`ar`, `en`, `franco`) |
| `sources` | Where the facts come from (kept in the content file, not the database). Required outside drinks |

### Rules for «يعني»
- One line. Everyday Egyptian Arabic.
- No jargon. Never explain a hard word with another hard word: «تسويف يعني
  تأجيل» is not enough when «تأجيل الحاجة لحد آخر لحظة» says it.
- Never repeat the word you're explaining.
- Drinks: no other menu word (`MENU_WORDS` in `build_seed.py`).

## Details by kind
Each section has one kind (`detail_kind`) and names it (`details_title_ar`
/ `_en`, ≤ 40).

### `recipe` (drinks, «طريقة التحضير»)
`{kind, minutes, layers[1..6]: {tone, ml, ar, en}, steps[1..8]}`. The
layers add up to the cup. Written in `supabase/content/drinks/recipes.json`.

### `story` (history, «الحكاية»)
`{kind, steps[1..12], sections[0..6]}`
- `steps`: events in order: `title_ar/en` (≤ 60), optional `date_ar/en`
  (≤ 40, written the way people say it: «٦ أكتوبر ١٩٧٣»), `note_ar/en`
  (≤ 160).
- `sections`: e.g. «الأسباب», «النتايج».
- Neutral wording. Facts are checked against reliable sources, cited in
  `sources`.

### `usage` (terms, «إزاي تستخدمها»)
`{kind, sections[1..6]}`, e.g. «في جملة» (an everyday example), «عكسها»,
«كلمات قريبة».

A section is `{title_ar, title_en (≤ 40), lines_ar, lines_en (1..8 lines,
≤ 200 each)}`.

## Examples
- **Drink:** Flat White: «يعني قهوة باللبن تقيلة في فنجان صغير». The recipe
  has the cup and 3 steps.
- **Term:** بيروقراطية: «يعني ورق كتير وإمضاءات قبل أي حاجة تخلص». Usage:
  في جملة «علشان أطلع البطاقة لفيت على ٤ شبابيك، بيروقراطية»; عكسها «تخلص
  في يوم من مكان واحد».
- **History:** حرب ٧٣: «يعني الحرب بين مصر وإسرائيل سنة ١٩٧٣». Story:
  steps «العبور» (٦ أكتوبر ١٩٧٣) … then the sections «الأسباب» and «النتايج».

## Adding a section (content only)
1. `supabase/content/<slug>/section.json`: `slug`, `name_ar/en`, `icon`,
   `sort_order`, `detail_kind`, `details_title_ar/en`, `categories` (chips).
2. `supabase/content/<slug>/items.json`: the items, as above.
3. `python3 supabase/content/build_seed.py --section <slug>` writes the
   next migration, `NNNN_content_<slug>.sql`, once. Commit both, and the
   merge deploys them.
