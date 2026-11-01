#!/usr/bin/env python3
"""Builds content migrations. One folder per section in supabase/content/.

    python3 supabase/content/build_seed.py                    # drinks
    python3 supabase/content/build_seed.py --section terms    # any other

Any other section: <slug>/section.json (name, icon, detail_kind, details
title, chips) and <slug>/items.json (items with «يعني», explanation,
details of the section's kind, search terms and sources) → the next free
migration NNNN_content_<slug>.sql, written once. Shapes and rules:
docs/content_guide.md.

Drinks (the launch section, drinks/):

Writes supabase/migrations/0003_seed_drinks.sql: the Café section, its
categories and the drinks in drinks.csv, with their search terms. Every
insert is `on conflict do nothing`, so it never overwrites edits made later
in Supabase Studio. After launch, content is edited in Studio, not here.

Also writes 0004_item_gist.sql, the short «يعني» line of each drink
(gist_ar / gist_en), but only when it doesn't exist yet: it is applied in
production, and an applied migration is never rewritten. Later changes to
the lines in drinks.csv go out as a new migration (like 0006).

And 0007_item_recipes.sql, «طريقة التحضير» from recipes.json, the same
way (written once, then frozen), and 0008, the drink-page explanations
rewritten without menu words (explanations.json). drinks.csv keeps the
launch texts: 0008 replaces one only while it's still the launch text.

Every «يعني» line is checked against MENU_WORDS: it must say what a drink
is in words everyone knows, so it can't lean on another menu word.
"""

import csv
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent
# One folder per section; drinks keeps its launch files (CSV + JSON).
DRINKS = ROOT / "drinks"
OUT = ROOT.parent / "migrations" / "0003_seed_drinks.sql"
GIST_OUT = ROOT.parent / "migrations" / "0004_item_gist.sql"
RECIPE_OUT = ROOT.parent / "migrations" / "0007_item_recipes.sql"
EXPLAIN_OUT = ROOT.parent / "migrations" / "0008_item_explanations_everyday_words.sql"

# Borrowed menu words a «يعني» line may not use: someone who doesn't know
# one drink may not know these either. Everyday words (شاي أخضر، كركديه،
# آيس كريم، كراميل) are fine.
MENU_WORDS = [
    "لاتيه", "إسبريسو", "اسبريسو", "موكا", "فرابيه", "ميلك شيك", "ماكياتو",
    "كابتشينو", "ماتشا", "سموذي", "كولد برو", "أفوجاتو", "دوبيو", "كورتادو",
    "أمريكانو", "تشاي", "موهيتو",
    # Not a menu word, but not everyday Egyptian either: say «في الخلاط».
    "متخفوق",
    "latte", "espresso", "mocha", "frapp", "milkshake", "macchiato",
    "cappuccino", "matcha", "smoothie", "cold brew", "affogato", "doppio",
    "cortado", "americano", "chai", "mojito",
]

# The Café section's traits: the taste quiz and the trait pills read these.
TRAIT_SCHEMA = [
    {
        "key": "temp",
        "type": "enum",
        "question": {"ar": "بتحب مشروبك سخن ولا ساقع؟", "en": "Hot or iced?"},
        "options": [
            {"value": "hot", "ar": "سخن", "en": "Hot"},
            {"value": "cold", "ar": "ساقع", "en": "Iced"},
            {"value": "both", "ar": "سخن أو ساقع", "en": "Hot or iced"},
        ],
    },
    {
        "key": "sweetness",
        "type": "scale",
        "min": 0,
        "max": 3,
        "question": {"ar": "بتحبه حلو قد إيه؟", "en": "How sweet do you like it?"},
        "labels": {
            "ar": ["سادة", "مظبوط", "حلو", "حلو أوي"],
            "en": ["Not sweet", "A little sweet", "Sweet", "Very sweet"],
        },
    },
    {
        "key": "milk",
        "type": "bool",
        "question": {"ar": "بلبن ولا من غير؟", "en": "With milk or without?"},
        "labels": {"ar": ["من غير لبن", "بلبن"], "en": ["No milk", "With milk"]},
    },
    {
        "key": "caffeine",
        "type": "scale",
        "min": 0,
        "max": 3,
        "question": {"ar": "عايز قهوة قد إيه؟", "en": "How much of a kick?"},
        "labels": {
            "ar": ["من غير كافيين", "خفيف", "متوسط", "قوي"],
            "en": ["No caffeine", "Light", "Medium", "Strong"],
        },
    },
]

# slug: (name_ar, name_en, icon)
CATEGORIES = {
    "coffee": ("قهوة", "Coffee", "coffee"),
    "iced_coffee": ("قهوة ساقعة", "Iced coffee", "ice_cream"),
    "frappe": ("فرابيه", "Frappés", "drop"),
    "tea": ("شاي", "Tea", "leaf"),
    "juice": ("عصاير", "Juices", "orange_slice"),
    "other": ("مشروبات تانية", "Other drinks", "cup"),
}


def lit(value):
    """A SQL literal: dollar-quoted text, numbers, null."""
    if value is None or value == "":
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    text = str(value)
    assert "$c$" not in text, f"unexpected quote marker in {text!r}"
    return f"$c${text}$c$"


def main():
    rows = list(csv.DictReader(open(DRINKS / "drinks.csv", encoding="utf-8-sig")))
    unknown = {r["category"] for r in rows} - CATEGORIES.keys()
    assert not unknown, f"categories missing from CATEGORIES: {unknown}"

    out = [
        "-- Launch content: the Café section and its drinks.",
        "-- GENERATED by supabase/content/build_seed.py from drinks.csv — don't edit;",
        "-- after launch, edit content in Supabase Studio. Inserts never overwrite.",
        "",
        "insert into public.categories (slug, name_ar, name_en, icon, trait_schema, sort_order)",
        f"values ('cafe', {lit('الكافيه')}, {lit('Café')}, 'coffee', "
        f"{lit(json.dumps(TRAIT_SCHEMA, ensure_ascii=False))}::jsonb, 0)",
        "on conflict (slug) do nothing;",
        "",
        "insert into public.categories (parent_id, slug, name_ar, name_en, icon, sort_order)",
        "select (select id from public.categories where slug = 'cafe'), v.slug, v.name_ar, v.name_en, v.icon, v.sort_order",
        "from (values",
    ]
    values = [
        f"  ({lit(slug)}, {lit(ar)}, {lit(en)}, {lit(icon)}, {i})"
        for i, (slug, (ar, en, icon)) in enumerate(CATEGORIES.items())
    ]
    out += [",\n".join(values), ") as v (slug, name_ar, name_en, icon, sort_order)",
            "on conflict (slug) do nothing;", ""]

    out += [
        "insert into public.items (category_id, slug, menu_name, menu_name_ar, explanation_ar,",
        "  explanation_en, calories, size_ml, traits, sort_order)",
        "select c.id, v.slug, v.menu_name, v.menu_name_ar, v.explanation_ar, v.explanation_en,",
        "  v.calories, v.size_ml, v.traits::jsonb, v.sort_order",
        "from (values",
    ]
    values = []
    for i, r in enumerate(rows):
        traits = {
            "temp": r["temp"],
            "sweetness": int(r["sweetness_0_3"]),
            "milk": r["milk"].strip().lower() == "true",
            "caffeine": int(r["caffeine_0_3"]),
        }
        values.append(
            "  (" + ", ".join([
                lit(r["category"]), lit(r["slug"]), lit(r["menu_name"]), lit(r["menu_name_ar"]),
                lit(r["explanation_ar"]), lit(r["explanation_en"]),
                lit(int(r["calories_approx"])) if r["calories_approx"] else "null::int",
                lit(int(r["size_ml"])) if r["size_ml"] else "null::int",
                lit(json.dumps(traits)), str(i),
            ]) + ")"
        )
    out += [",\n".join(values),
            ") as v (category, slug, menu_name, menu_name_ar, explanation_ar, explanation_en,",
            "  calories, size_ml, traits, sort_order)",
            "join public.categories c on c.slug = v.category",
            "on conflict (slug) do nothing;", ""]

    terms = []
    for r in rows:
        names = {r["menu_name"].lower(), r["menu_name_ar"]}
        for lang, column in (("ar", "terms_ar"), ("en", "terms_en"), ("franco", "terms_franco")):
            seen = set()
            for term in r[column].split("|"):
                term = term.strip()
                if not term or term.lower() in seen:
                    continue
                seen.add(term.lower())
                kind = "name" if term.lower() in names or lang == "franco" else "description"
                terms.append(f"  ({lit(r['slug'])}, {lit(term)}, '{lang}', '{kind}')")
    out += [
        "insert into public.item_terms (item_id, term, lang, kind)",
        "select i.id, v.term, v.lang, v.kind",
        "from (values",
        ",\n".join(terms),
        ") as v (slug, term, lang, kind)",
        "join public.items i on i.slug = v.slug",
        "on conflict (item_id, term, lang) do nothing;",
        "",
    ]
    OUT.write_text("\n".join(out), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT.parent.parent)}: {len(rows)} items, {len(terms)} terms")
    write_gists(rows)
    write_recipes(rows)
    write_explanations(rows)


def write_gists(rows):
    """0004: the gist columns, then each drink's line where it's empty."""
    out = [
        "-- The «يعني» line: what a drink is in everyday words, shown on its card",
        "-- («فرابيه يعني ميلك شيك بالقهوة»). Short, and never another menu word.",
        "-- GENERATED by supabase/content/build_seed.py from drinks.csv — don't edit.",
        "-- Updates only fill empty lines, so edits made in Studio are kept; the",
        "-- touch trigger bumps updated_at, so phones pick the lines up on next sync.",
        "",
        "alter table public.items",
        "  add column if not exists gist_ar text",
        "    check (gist_ar is null or char_length(gist_ar) between 1 and 60),",
        "  add column if not exists gist_en text",
        "    check (gist_en is null or char_length(gist_en) between 1 and 60);",
        "",
        "update public.items i",
        "set gist_ar = coalesce(i.gist_ar, v.gist_ar),",
        "  gist_en = coalesce(i.gist_en, v.gist_en)",
        "from (values",
    ]
    for r in rows:
        assert 1 <= len(r["gist_ar"]) <= 60 and 1 <= len(r["gist_en"]) <= 60, r["slug"]
        for line in (r["gist_ar"], r["gist_en"]):
            used = [w for w in MENU_WORDS if w in line.lower()]
            assert not used, f"{r['slug']}: «{line}» uses a menu word {used}"
    if GIST_OUT.exists():
        print(f"kept {GIST_OUT.relative_to(ROOT.parent.parent)} (applied; never rewritten)")
        return
    out.append(",\n".join(
        f"  ({lit(r['slug'])}, {lit(r['gist_ar'])}, {lit(r['gist_en'])})" for r in rows
    ))
    out += [
        ") as v (slug, gist_ar, gist_en)",
        "where i.slug = v.slug and (i.gist_ar is null or i.gist_en is null);",
        "",
    ]
    GIST_OUT.write_text("\n".join(out), encoding="utf-8")
    print(f"wrote {GIST_OUT.relative_to(ROOT.parent.parent)}: {len(rows)} lines")


# The colours a cup layer can have and the pictures a step can have. The app
# knows the same names (RecipeTone / RecipeIcon); an unknown one falls back.
RECIPE_TONES = {
    "espresso", "coffee", "foam", "water", "milk", "condensed", "chocolate",
    "white_chocolate", "caramel", "vanilla", "cream", "ice_cream", "ice",
    "blended_coffee", "blended_caramel", "blended_chocolate", "blended_vanilla",
    "tea", "green_tea", "chai", "matcha", "hibiscus", "mint_tea", "mango",
    "strawberry", "orange", "lemon", "fruit", "berry", "hot_chocolate",
    "sahlab", "nuts", "cookies", "soda",
}
RECIPE_ICONS = {
    "grind", "shot", "boil", "steep", "milk", "steam", "pour", "ice", "blend",
    "stir", "sweeten", "top", "squeeze", "serve",
}
# A range like «25–30» turns around in RTL text; content says «حوالي 30».
RANGE = re.compile(r"\d\s*[-–—]\s*\d")


def recipe_json(slug, recipe, size_ml):
    """One drink's recipe as stored in items.recipe, after checking it."""
    layers = recipe["layers"]
    steps = recipe["steps"]
    assert 1 <= len(layers) <= 6, f"{slug}: 1 to 6 layers"
    assert 1 <= len(steps) <= 8, f"{slug}: 1 to 8 steps"
    total = sum(ml for _, ml, _, _ in layers)
    assert total == size_ml, f"{slug}: layers add up to {total} ml, the drink is {size_ml}"
    assert 1 <= recipe["minutes"] <= 1440, slug
    texts = []
    out_layers = []
    for tone, ml, ar, en in layers:
        assert tone in RECIPE_TONES, f"{slug}: unknown tone {tone}"
        assert ml > 0 and 1 <= len(ar) <= 40 and 1 <= len(en) <= 40, f"{slug}: {ar}"
        texts += [ar, en]
        out_layers.append({"tone": tone, "ml": ml, "ar": ar, "en": en})
    out_steps = []
    for icon, title_ar, note_ar, amount_ar, title_en, note_en, amount_en in steps:
        assert icon in RECIPE_ICONS, f"{slug}: unknown icon {icon}"
        assert 1 <= len(title_ar) <= 60 and 1 <= len(title_en) <= 60, f"{slug}: {title_ar}"
        assert len(note_ar) <= 160 and len(note_en) <= 160, f"{slug}: {title_ar}"
        assert len(amount_ar) <= 40 and len(amount_en) <= 40, f"{slug}: {title_ar}"
        assert bool(note_ar) == bool(note_en) and bool(amount_ar) == bool(amount_en), f"{slug}: {title_ar}"
        texts += [title_ar, note_ar, amount_ar, title_en, note_en, amount_en]
        step = {"icon": icon, "title_ar": title_ar, "title_en": title_en}
        if note_ar:
            step |= {"note_ar": note_ar, "note_en": note_en}
        if amount_ar:
            step |= {"amount_ar": amount_ar, "amount_en": amount_en}
        out_steps.append(step)
    for text in texts:
        used = [w for w in MENU_WORDS if w in text.lower()]
        assert not used, f"{slug}: «{text}» uses a menu word {used}"
        assert not RANGE.search(text), f"{slug}: «{text}» has a number range"
    return {"minutes": recipe["minutes"], "layers": out_layers, "steps": out_steps}


def write_recipes(rows):
    """0007: the recipe column, then each drink's «طريقة التحضير»."""
    recipes = json.loads((DRINKS / "recipes.json").read_text(encoding="utf-8"))
    recipes.pop("_about", None)
    slugs = [r["slug"] for r in rows]
    assert set(recipes) == set(slugs), f"recipes.json vs drinks.csv: {set(recipes) ^ set(slugs)}"
    built = [
        (r["slug"], recipe_json(r["slug"], recipes[r["slug"]], int(r["size_ml"])))
        for r in rows
    ]
    if RECIPE_OUT.exists():
        print(f"kept {RECIPE_OUT.relative_to(ROOT.parent.parent)} (applied; never rewritten)")
        return
    out = [
        "-- «طريقة التحضير»: how each drink is made. The cup's layers to scale",
        "-- (tone, ml, name; bottom to top, adding up to size_ml) and the steps in",
        "-- order (icon, title, note, amount), in Arabic and English.",
        "-- GENERATED by supabase/content/build_seed.py from recipes.json — don't edit.",
        "-- Updates only fill empty recipes, so edits made in Studio are kept; the",
        "-- touch trigger bumps updated_at, so phones pick them up on next sync.",
        "",
        "alter table public.items",
        "  add column if not exists recipe jsonb",
        "    check (",
        "      recipe is null or (",
        "        jsonb_typeof(recipe) = 'object'",
        "        and jsonb_typeof(recipe -> 'layers') = 'array'",
        "        and jsonb_array_length(recipe -> 'layers') between 1 and 6",
        "        and jsonb_typeof(recipe -> 'steps') = 'array'",
        "        and jsonb_array_length(recipe -> 'steps') between 1 and 8",
        "        and pg_column_size(recipe) <= 16384",
        "      )",
        "    );",
        "",
        "update public.items i",
        "set recipe = coalesce(i.recipe, v.recipe::jsonb)",
        "from (values",
        ",\n".join(
            f"  ({lit(slug)}, {lit(json.dumps(recipe, ensure_ascii=False))})"
            for slug, recipe in built
        ),
        ") as v (slug, recipe)",
        "where i.slug = v.slug and i.recipe is null;",
        "",
    ]
    RECIPE_OUT.write_text("\n".join(out), encoding="utf-8")
    print(f"wrote {RECIPE_OUT.relative_to(ROOT.parent.parent)}: {len(built)} recipes")


def write_explanations(rows):
    """0008: each explanation in everyday words, where it's still the launch text."""
    new = json.loads((DRINKS / "explanations.json").read_text(encoding="utf-8"))
    new.pop("_about", None)
    slugs = [r["slug"] for r in rows]
    assert set(new) == set(slugs), f"explanations.json vs drinks.csv: {set(new) ^ set(slugs)}"
    for slug, texts in new.items():
        for text in texts:
            assert 1 <= len(text) <= 300, f"{slug}: {len(text)} characters"
            used = [w for w in MENU_WORDS if w in text.lower()]
            assert not used, f"{slug}: «{text}» uses a menu word {used}"
            assert not RANGE.search(text), f"{slug}: «{text}» has a number range"
    if EXPLAIN_OUT.exists():
        print(f"kept {EXPLAIN_OUT.relative_to(ROOT.parent.parent)} (applied; never rewritten)")
        return
    out = [
        "-- The drink page's explanations, in words everyone knows: «قهوة مركّزة»",
        "-- instead of «إسبريسو», «في الخلاط» instead of «متخفوق»… so no",
        "-- explanation leans on another menu word.",
        "-- GENERATED by supabase/content/build_seed.py from explanations.json — don't edit.",
        "-- Each language is replaced only while it's still the launch text, so",
        "-- edits made in Studio are kept; the touch trigger bumps updated_at.",
        "",
    ]
    for lang in ("ar", "en"):
        out += [
            "update public.items i",
            f"set explanation_{lang} = v.new",
            "from (values",
            ",\n".join(
                f"  ({lit(r['slug'])}, {lit(r[f'explanation_{lang}'])}, "
                f"{lit(new[r['slug']][0 if lang == 'ar' else 1])})"
                for r in rows
            ),
            ") as v (slug, old, new)",
            f"where i.slug = v.slug and i.explanation_{lang} = v.old;",
            "",
        ]
    EXPLAIN_OUT.write_text("\n".join(out), encoding="utf-8")
    print(f"wrote {EXPLAIN_OUT.relative_to(ROOT.parent.parent)}: {len(rows)} drinks")


# --- Any other section: supabase/content/<slug>/section.json + items.json --

SLUG = re.compile(r"^[a-z0-9_]{1,60}$")
KINDS = {"recipe", "story", "usage"}


def check_steps(where, steps, most):
    assert isinstance(steps, list) and 1 <= len(steps) <= most, f"{where}: 1..{most} steps"
    for st in steps:
        for lang in ("ar", "en"):
            title = st.get(f"title_{lang}")
            assert isinstance(title, str) and 1 <= len(title) <= 60, f"{where}: step title_{lang}"
            for key, most_len in (("note", 160), ("amount", 40), ("date", 40)):
                value = st.get(f"{key}_{lang}")
                assert value is None or (isinstance(value, str) and len(value) <= most_len), (
                    f"{where}: {key}_{lang} too long")


def check_sections(where, sections):
    assert isinstance(sections, list) and 1 <= len(sections) <= 6, f"{where}: 1..6 sections"
    for sec in sections:
        for lang in ("ar", "en"):
            title = sec.get(f"title_{lang}")
            lines = sec.get(f"lines_{lang}")
            assert isinstance(title, str) and 1 <= len(title) <= 40, f"{where}: section title_{lang}"
            assert isinstance(lines, list) and 1 <= len(lines) <= 8, f"{where}: 1..8 lines_{lang}"
            for line in lines:
                assert isinstance(line, str) and 1 <= len(line) <= 200, f"{where}: a line"


def check_details(where, kind, details):
    """The same shapes as item_details_valid() (migration 0009)."""
    assert details.get("kind") == kind, f"{where}: details.kind must be {kind}"
    if kind == "story":
        check_steps(where, details.get("steps"), 12)
        if "sections" in details:
            check_sections(where, details["sections"])
    elif kind == "usage":
        check_sections(where, details.get("sections"))
    else:
        raise AssertionError(f"{where}: write recipes in drinks/recipes.json")
    assert len(json.dumps(details, ensure_ascii=False).encode()) <= 16000, f"{where}: details too big"


def build_section(slug):
    """Writes the next free migration `NNNN_content_<slug>.sql` from
    supabase/content/<slug>/ (section.json, items.json). Like the drinks
    files, it is written once and then frozen: later edits go in Studio or a
    new migration. Every item must cite its sources (`sources`, kept here,
    not in the database)."""
    folder = ROOT / slug
    section = json.loads((folder / "section.json").read_text(encoding="utf-8"))
    items = json.loads((folder / "items.json").read_text(encoding="utf-8"))
    migrations = ROOT.parent / "migrations"
    existing = sorted(migrations.glob(f"*_content_{slug}.sql"))
    if existing:
        print(f"kept {existing[0].name} (applied; never rewritten)")
        return
    assert section["slug"] == slug and SLUG.match(slug), "section slug"
    kind = section["detail_kind"]
    assert kind in KINDS, f"detail_kind must be one of {KINDS}"
    chips = {c["slug"] for c in section["categories"]}
    seen = set()
    for item in items:
        where = item.get("slug", "?")
        assert SLUG.match(where) and where not in seen, f"{where}: bad or repeated slug"
        seen.add(where)
        assert item["category"] in chips, f"{where}: unknown category"
        for lang in ("ar", "en"):
            gist = item[f"gist_{lang}"]
            assert 1 <= len(gist) <= 60, f"{where}: gist_{lang} is one short line"
            assert 1 <= len(item[f"explanation_{lang}"]) <= 300, f"{where}: explanation_{lang}"
        name = item["menu_name_ar"]
        assert name not in item["gist_ar"], f"{where}: «يعني» can't repeat the word it explains"
        assert item.get("sources"), f"{where}: cite at least one source"
        check_details(where, kind, item["details"])

    number = max(int(m.name[:4]) for m in migrations.glob("[0-9][0-9][0-9][0-9]_*.sql")) + 1
    out_path = migrations / f"{number:04d}_content_{slug}.sql"
    cat_cols = "(parent_id, slug, name_ar, name_en, icon, sort_order)"
    out = [
        f"-- «{section['name_ar']}» / {section['name_en']}: a section of kind {kind}.",
        f"-- GENERATED by supabase/content/build_seed.py --section {slug} — don't edit.",
        "-- Sources are cited in supabase/content/" + slug + "/items.json.",
        "",
        "insert into public.categories (slug, name_ar, name_en, icon, sort_order,",
        "  detail_kind, details_title_ar, details_title_en)",
        "values (" + ", ".join(lit(section[k]) for k in (
            "slug", "name_ar", "name_en", "icon", "sort_order",
            "detail_kind", "details_title_ar", "details_title_en")) + ")",
        "on conflict (slug) do nothing;",
        "",
    ]
    for c in section["categories"]:
        out += [
            f"insert into public.categories {cat_cols}",
            f"select id, {lit(c['slug'])}, {lit(c['name_ar'])}, {lit(c['name_en'])}, "
            f"{lit(c.get('icon'))}, {c.get('sort_order', 0)}",
            f"from public.categories where slug = {lit(slug)}",
            "on conflict (slug) do nothing;",
        ]
    out.append("")
    for i, item in enumerate(items):
        traits = json.dumps(item.get("traits", {}), ensure_ascii=False)
        details = json.dumps(item["details"], ensure_ascii=False)
        out += [
            "insert into public.items (category_id, slug, menu_name, menu_name_ar,",
            "  gist_ar, gist_en, explanation_ar, explanation_en, traits, details, sort_order)",
            "select id, " + ", ".join(lit(item[k]) for k in (
                "slug", "menu_name", "menu_name_ar", "gist_ar", "gist_en",
                "explanation_ar", "explanation_en")) + f", {lit(traits)}::jsonb, {lit(details)}::jsonb, {i}",
            f"from public.categories where slug = {lit(item['category'])}",
            "on conflict (slug) do nothing;",
        ]
        for term in item.get("terms", []):
            assert term["lang"] in ("ar", "en", "franco") and 1 <= len(term["term"]) <= 60
            out += [
                "insert into public.item_terms (item_id, term, lang)",
                f"select id, {lit(term['term'])}, {lit(term['lang'])} from public.items "
                f"where slug = {lit(item['slug'])}",
                "on conflict (item_id, term, lang) do nothing;",
            ]
    out.append("")
    out_path.write_text("\n".join(out), encoding="utf-8")
    print(f"wrote {out_path.relative_to(ROOT.parent.parent)}: {len(items)} items")


if __name__ == "__main__":
    import sys

    if len(sys.argv) == 3 and sys.argv[1] == "--section":
        build_section(sys.argv[2])
    else:
        main()
