# Yaani Eh — documentation

Start with [`../CLAUDE.md`](../CLAUDE.md) (rules + stack), then:

- [Design](design.md) — Claude Design links, tokens → code, screen checklist
- [Getting started](getting_started.md) — run the app, env files, Supabase
- [Release & CI/CD](release.md) — how merging to `main` ships to the stores
- [Content (menu data)](content.md) — tables, editing drinks in Supabase Studio, photos, prices
- [Deep links](deep_links.md)
- [Security](security.md) — what is tested and how
- [Decisions](decisions/) — why the stack looks the way it does; [photo thumbnails](decisions/0002-photo-thumbnails.md); [drink cards say what a drink is](decisions/0003-drink-card-meaning.md)

## Roadmap
Build in this order, one feature per PR (each with tests, doc and demo):

| # | Feature | Status |
|---|---|---|
| 1 | `catalog_sync` — the menu downloads once and works offline | ✅ |
| 2 | `browse_menu` — Home: category chips and drink cards | ✅ |
| 3 | `item_details` — drink page: traits, price, similar drinks | ✅ |
| 4 | `smart_search` — by name or description, offline | ✅ |
| 5 | `pronunciation` — hear the drink's name (barista + original), the play pill on cards and the drink page | ✅ |
| 6 | `favorites` — hearts, a Favorites tab (brings the tab bar), the long-press preview | ✅ |
| 7 | `recipes` — «طريقة التحضير»: the cup's layers to scale and the steps, from the long-press preview | next |
| 8 | `taste_profile` — "My taste": what you like, used to rank search and suggestions | |
| 9 | `suggest_item` — suggest a drink from your taste | |

Update the status here when a feature merges.

## Features
- [Catalog sync (offline menu)](features/catalog_sync.md)
- [Browse menu (Home)](features/browse_menu.md)
- [Item details](features/item_details.md)
- [Smart search](features/smart_search.md)
- [Favorites (hearts, tab, long-press preview)](features/favorites.md)
- [Pronunciation](features/pronunciation.md)
- [App update gate](features/app_update.md)
- [Settings (language & theme)](features/settings.md)
- [favorites](features/favorites.md)
