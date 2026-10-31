# 0003 — Drink cards say what a drink is, not what it costs

Date: 2026-10-30 · Status: accepted

## Context
The app exists to answer «يعني إيه؟»: to bridge the foreign words on café
menus and the words people in Egypt already use. The Home card showed the
menu name, its Arabic spelling and a price range (or calories while prices
weren't checked, so one slot meant two things). The text sat on frosted
glass over the photo: hard to keep at 4.5:1 on busy photos, and one blur
per card cost scrolling speed on Android.

Four layouts were compared with the same content and type scale
(https://claude.ai/artifact/6jUejU6u846SWWyW6d8siU): A frosted label,
B caption below, C meaning first, D list row.

## Decision
- **B, caption below, with the name on the photo:** the photo is a tile,
  its controls (play, later the heart) are clear glass on it, and the name
  and spelling sit at its bottom over a soft shadow, not a box (a review
  asked for A's look without its frosted block). The «يعني» line sits
  under the photo on the solid surface, never cut (≤ 60 characters in the
  database, no line limit). Glass only on controls, as Liquid Glass
  intends.
- **The card's third line is the «يعني» line**, not the price:
  `items.gist_ar` / `gist_en` (≤ 60 chars), everyday words only («فرابيه
  يعني قهوة باللبن متخفوقة بالتلج»). Without one, the explanation's first sentence.
  The price and calories stay on the drink page.
- The name stays first (it's how you find the drink you just read on the
  menu); C (meaning as the headline) was weaker for that.

## Alternatives
- **A, frosted label:** shortest card, but three lines of glass cover half
  the photo, with the contrast and performance cost above.
- **C, meaning first:** the boldest, best for learning the menu; harder to
  find an exact name.
- **D, list row:** the most detail, but small photos, and the full
  explanations often use other menu words («إسبريسو بلبن…»). A candidate
  for one category's view later.

## Revisit when
Users ask for prices on Home (e.g. analytics show most drink-page opens
are only to read the price), or the sections switch (drinks / desserts)
lands and a category view gets its own layout.
