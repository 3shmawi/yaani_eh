# Next phase prompt

Paste this into a new Claude Code session on `3shmawi/yaani_eh`.

---

Read `CLAUDE.md` fully, then `docs/README.md` (roadmap), `docs/design.md`,
`docs/features/taste_profile.md` and `docs/features/welcome.md`. Follow every
rule in CLAUDE.md: official docs first, tests + docs + an integration demo
with the feature, no hard-coded strings, colours or sizes, RTL, tablets
(`AppReadableWidth`), screenshot review (`./scripts/screens.sh`, plus
`1032x1376` and `1376x1032` for iPad), Conventional Commits. A merge to
`main` releases to both stores: never merge without my explicit OK. Use
merge commits, not force-push.

## Phase: «اقترح عليا» (`suggest_item`, roadmap #9)

**Goal:** one tap, and the app picks one drink for me right now. It uses my
«ذوقي» answers when I have them, the time of day (coffee in the morning,
something lighter at night), the weather feeling (hot or iced; no location,
no network call, use the month and hour only), and what I saved. "مش ده"
shows another one, never the same one twice in a row. Opening it explains
why in one line («ساقع وحلو، وانت بتحب اللبن»).

**Steps:**
1. **Design first.** Add 2–3 options to the design canvas
   (https://claude.ai/artifact/PTwE3Ex87rG5og9jF8AS4c): where the entry point
   lives (Home under «على ذوقك», a button in the header band, the tab bar),
   and how the pick is shown (a full card on the band, a sheet, a
   "shuffle" card). Phone and iPad. Stop and ask me to pick.
2. **Domain:** a pure-Dart `SuggestDrink` use case (taste score from
   `MatchTaste`, time-of-day and season weights, favorites boost, a
   short-term "already shown" memory), fully unit-tested with a fixed clock
   and seeded randomness. No personal data leaves the phone.
3. **Presentation:** the chosen design, with loading, empty (no drinks fit),
   error and offline states, haptics, Reduce Motion, large text, and
   `expectAccessible` in every screen test.
4. **Route:** `/suggest`, documented in `docs/deep_links.md`, with
   `test/security/deep_link_test.dart` cases.
5. **Analytics:** `suggestion_shown`, `suggestion_skipped`,
   `suggestion_opened` (slugs and counts only), listed in the feature doc.
6. **Docs:** `docs/features/suggest_item.md` (with "Demo & post": hook,
   scenario, captions in English and Egyptian Arabic), the README roadmap,
   and `docs/design.md`.
7. **Store:** add a `9_suggest` store screenshot (caption in both
   languages, `tool/store/frame.js`), re-run `./scripts/store_shots.sh`, and
   update the description, promotional text and release notes in
   `store/ios/*` and `store/android/*`.
8. Open a PR, watch it, review the Demo video's iPhone screenshots, and ask
   me before merging.

## After this phase (suggest them to me, don't start them)
- **Drink photos:** a Supabase Storage bucket plus a catalog field, upload
  tooling, `DrinkPhoto` loading and caching, and a store screenshot refresh
  once the photos are in. I decide where the photos come from.
- **Desserts section** («حلويات · قريبًا»): content, `trait_schema` and
  its own «ذوقي» questions.
