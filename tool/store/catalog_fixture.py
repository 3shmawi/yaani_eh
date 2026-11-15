#!/usr/bin/env python3
"""The launch catalog as server rows, for the store screenshots.

    python3 tool/store/catalog_fixture.py build/store/catalog.json

Same content the app ships (supabase/content/drinks: drinks.csv with the
«يعني» lines, recipes.json, explanations.json), in the shape CatalogRows
reads (migration 0009: details by section kind, calories and size as
traits), so the screenshots show real drinks and words instead of test data.
"""

import csv
import importlib.util
import json
import pathlib
import sys
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[2]
CONTENT = ROOT / "supabase" / "content"
DRINKS = CONTENT / "drinks"

spec = importlib.util.spec_from_file_location("seed", CONTENT / "build_seed.py")
seed = importlib.util.module_from_spec(spec)
spec.loader.exec_module(seed)


def uid(name):
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"yaanieh:{name}"))


def main(out):
    rows = list(csv.DictReader(open(DRINKS / "drinks.csv", encoding="utf-8-sig")))
    recipes = json.loads((DRINKS / "recipes.json").read_text(encoding="utf-8"))
    explain = json.loads((DRINKS / "explanations.json").read_text(encoding="utf-8"))
    stamp = "2026-10-31T00:00:00Z"
    categories = [
        {"id": uid("cafe"), "parent_id": None, "slug": "cafe", "name_ar": "مشروبات",
         "name_en": "Drinks", "icon": "coffee", "trait_schema": seed.TRAIT_SCHEMA,
         "detail_kind": "recipe", "details_title_ar": "طريقة التحضير",
         "details_title_en": "How it's made", "sort_order": 0, "updated_at": stamp},
        {"id": uid("desserts"), "parent_id": None, "slug": "desserts", "name_ar": "حلويات",
         "name_en": "Desserts", "icon": "cake", "trait_schema": None, "sort_order": 1,
         "updated_at": stamp},
    ]
    for i, (slug, (ar, en, icon)) in enumerate(seed.CATEGORIES.items()):
        categories.append({"id": uid(slug), "parent_id": uid("cafe"), "slug": slug,
                           "name_ar": ar, "name_en": en, "icon": icon, "trait_schema": None,
                           "sort_order": i, "updated_at": stamp})
    items = []
    for i, r in enumerate(rows):
        s = r["slug"]
        items.append({
            "id": uid(s), "category_id": uid(r["category"]), "slug": s,
            "menu_name": r["menu_name"], "menu_name_ar": r["menu_name_ar"],
            "explanation_ar": explain[s][0], "explanation_en": explain[s][1],
            "gist_ar": r["gist_ar"], "gist_en": r["gist_en"],
            "traits": {"temp": r["temp"], "sweetness": int(r["sweetness_0_3"]),
                       "milk": r["milk"].strip().lower() == "true",
                       "caffeine": int(r["caffeine_0_3"]),
                       **({"calories": int(r["calories_approx"])} if r["calories_approx"] else {}),
                       **({"size_ml": int(r["size_ml"])} if r["size_ml"] else {})},
            "sort_order": i,
            "details": {"kind": "recipe",
                        **seed.recipe_json(s, recipes[s], int(r["size_ml"]))},
            "updated_at": stamp,
        })
    pathlib.Path(out).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(out).write_text(json.dumps({"categories": categories, "items": items},
                                            ensure_ascii=False), encoding="utf-8")
    print(f"wrote {out}: {len(items)} drinks")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "build/store/catalog.json")
