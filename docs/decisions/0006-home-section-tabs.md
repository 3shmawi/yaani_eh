# 0006 — Home: section tabs on top, items first, a page at a time

Date: 2026-11-02 · Status: accepted (option A of the Home layouts)

## Context
0004 made Home a hub: a card per section, and one tap to see any item.
With one live section («مشروبات») and «حلويات» coming, that tap shows
nothing the first screen couldn't, and the first screen had no food or
drink on it. The sections still have to scale: more are coming («مصطلحات»,
«تاريخ», breakfast, sandwiches…) as backend data.

Layouts compared on a design canvas (today's hub; items first with section
tabs; a preview row per section; and each again at eight sections):

| | Items with 0 taps | Fits 8 sections | Cost |
|---|---|---|---|
| Hub (0004) | no | yes | one tap before any item |
| **A: tabs on the band, chips under it** | **yes** | **yes, the tabs scroll sideways** | small |
| B: icon strip + a row per section | yes | yes, with a cap on rows | more layout, lazy rows |

## Decision
**A.** Home opens on the first section with items. The band holds the app's
name, search and **one** sideways-scrolling row: the section tabs, a thin
divider, then that section's category chips (`CategoryChips(leading:)`). The body below is the section page's body, unchanged: item of the
day, categories, cards.

- A section is still data. One with no items has its tab and says
  «جاي قريب»; the tabs stay so there's always a way out, and
  `browse_section_opened` (with `coming_soon`) keeps telling us which
  coming sections people want.
- `/section/<slug>` stays (links, search results), with its back button.
  Home and the section page are the same `SectionView`.
- Items are built **a page at a time** (24): the next page when the list is
  within a screen and a half of its end. The catalog is already on the
  device (synced in pages of 100), so this keeps a section with hundreds of
  items as fast to open as one with a few, and does not add network calls.
  A chip past the built items builds up to it, then scrolls.

## Later
At about six or more sections with items, move to B (a quick-jump strip of
section icons, then a row of items per section, only the first few rows
built, the rest as you scroll): the section data and `SectionView` body
don't change, only what sits above them.

## Not done
- A second chip style for the tabs (they look like the category chips: the
  selected one is warm milk, the others clear glass). The divider tells the
  two groups apart for now. On a phone the categories can sit past the
  screen's edge while there are several sections: the row scrolls, and the
  chips are also in the pinned bar once the band scrolls away.
- «كل الأقسام» grid button (opens every section at once): not needed until
  the row needs it.
