# Next phase prompt

The prompt for the next phase of the project, kept here so any agent can
pick it up.

Read CLAUDE.md fully, then docs/README.md, docs/design.md, docs/features/*.md,
supabase/migrations/ and supabase/content/. Follow every rule in CLAUDE.md
(official docs first, tests + docs + an integration demo, no hard-coded
strings/colours/sizes, RTL, tablets with AppReadableWidth, screenshot review
incl. 1032x1376 and 1376x1032, Conventional Commits). A merge to main
releases to both stores: never merge without my explicit OK. Merge commits,
no force-push. One PR per step below; ask me before merging each.

## The product (this replaces anything else in the repo that says otherwise)
«يعني إيه؟» explains any word or thing you don't understand, in plain
Egyptian Arabic. It is NOT a café app. Café menus are only the first
section. Next come terms («بيروقراطية»، «تسويف»، «نضج») and history («ثورة
يناير»، «حرب ٧٣» → «يعني الحرب بين مصر وإسرائيل سنة ١٩٧٣…»), and more
later. Every item has the same core: its name as people see it, the
Arabic name, «يعني …» in one line, a short plain explanation, optional
image and pronunciation, search terms. Each section adds ONE kind of
details of its own: drinks → how it's made (recipe); history → causes,
events, results; terms → used in a sentence, its opposite, related words.
A new section must be content only (Supabase) whenever its details fit an
existing kind; a new kind ships in an app update.

## Step 1: remove what doesn't fit
- Remove «ذوقي» (lib/features/taste_profile, the /taste route, the «على
  ذوقك» row, its search boost, Dependencies/overrides, tests, the
  integration test, docs, the privacy-policy line in both languages, the
  roadmap row). Drop «اقترح عليا» (suggest_item) from the roadmap.
- Welcome: replace page 3 («على ذوقك» + «قولنا ذوقك») with a general page
  (save what matters to you, works offline, new sections coming) and one
  button that opens Home. Keep the rest of the welcome.
- PR #34 (iPad + store pack, branch claude/admiring-clarke-kin717-store-ipad):
  keep iPad and AppReadableWidth; remove the 8_taste screenshot and every
  «ذوقي» line from store texts; replace docs/next_phase_prompt.md with this
  prompt. Re-run ./scripts/store_shots.sh.
- Delete leftovers: unused tokens, ARB keys, AppIcons.taste, fake_taste.

## Step 2: generic names (refactor, no visual change)
- drink/menu → item/browse everywhere in code: DrinkCard → ItemCard,
  DrinkPage/View → ItemPage/View, browse_menu → browse, «مشروب النهارده» →
  «كلمة النهارده» (copy changes in step 4), drink_* analytics → item_*
  (update the feature docs' event tables).
- Route /drink/:slug → /item/:slug; /drink/... redirects to /item/... so old
  links keep working (deep_link_test cases for both). docs/deep_links.md.

## Step 3: generic data model + section-specific details
- Migration (new file, RLS kept, pgTAP updated):
  - categories.detail_kind text null (recipe | story | usage), sections
    only.
  - items.details jsonb null (validated shape per kind by a check
    function). Move items.recipe into details for drinks.
  - Drop price_* (hidden already). Move calories/size_ml into the drinks
    section's traits.
  - audio_barista_path → audio_spoken_path (UI: «زي ما بتتقال» /
    «الأصلي»).
- Domain: a sealed ItemDetails (RecipeDetails, StoryDetails, UsageDetails,
  UnknownDetails) built from two primitives: Steps (ordered, optional
  amount/date/icon) and Sections (title + bullet lines). Parser tolerant
  like the current recipe parser (hostile input tests).
- Item page: blocks in order (gist, explanation, traits, details,
  similar). Details render by kind; the cup drawing stays only in
  RecipeDetails. UnknownDetails (content newer than the app) shows «حدّث
  التطبيق عشان تشوف التفاصيل» with a button to the store (reuse the update
  feature's store URL).
- Details sheet/screen title comes from the section (content), e.g.
  «طريقة التحضير», «الحكاية», «إزاي تستخدمها». Step-by-step mode works for
  any Steps.
- Drift schema bump + sync of the new columns; tombstones unchanged.
- supabase/content/<section>/... (one folder per section); build_seed.py
  generic. docs/content_guide.md: rules for «يعني» (one line, no jargon,
  never explain a word with another hard word), per kind what details
  contain, examples for drinks, terms and history.

## Step 4: general wording and Home
- Home sections come from the backend (no hard-coded «مشروبات / حلويات
  قريبًا»); each section can be empty → EmptyView «جاي قريب».
- Tagline «اطلب وإنت فاهم» → a general one; search hints from several
  sections; welcome page 1 general (menus as one example).
- Store texts, keywords, website landing, CLAUDE.md and README first line:
  the general product.

## Step 5: prove it with two sections, content only
- Add «مصطلحات» (usage): بيروقراطية، تسويف، نضج + ~20 more, with
  details. Add «تاريخ» (story): ثورة ٢٥ يناير، حرب أكتوبر ١٩٧٣ + ~10 more,
  facts checked against reliable sources (cite them in the content file),
  neutral wording.
- No app code changes in this step except bugs found. Screenshot review
  and an integration demo opening a term and a history item.

## Also: app update gate (lib/core/update, announce-update.yml)
It works (optional = Update/Later, force = Update only, can't be
dismissed). Fix:
1. The iOS store_url in app_versions is still
   https://apps.apple.com/app/idYOUR_APP_ID: ask me for the App Store ID
   and set it with a migration; add a test that rejects a placeholder.
2. Optional: remember «بعدين» per version for 2 days instead of every
   launch.
3. Check again on resume (throttled, e.g. every 6 hours), not only at
   launch.
4. announce-update.yml: require changelog_ar (or fall back to English in
   the app).
5. Show it as an AppSheet (glass, like the recipe sheet), force = no grab
   handle and no swipe-to-close. Widget tests for both types, Arabic, iPad,
   expectAccessible; docs/features/app_update.md updated.
