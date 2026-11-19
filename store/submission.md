# Store submission answers

What App Store Connect and the Play Console ask for that isn't uploaded from
`store/` by the **Store listing** workflow. Keep it true: if the app starts
collecting something new, update this page, `website/privacy.html` and both
stores' privacy forms in the same PR.

Checked against the app on 2026-10-31. Apple's screenshot sizes were read on
developer.apple.com that day; Google's help pages weren't reachable from the
session that wrote this, so the Play sizes are its long-standing ones.
Re-check both pages before the first upload.

## First-release readiness (checked 2026-11-12)
- `flutter analyze` clean; 512 tests pass (unit, widget, security, store).
- Store pack complete in Arabic and English: texts, 512 icon, feature graphic,
  phone / 7" / 10" Android screenshots, iPhone 6.9" and iPad 13" screenshots.
- Launcher name: Android shows «يعني إيه؟» (Arabic) / "Yaani Eh" (other
  languages) from `res/values*/strings.xml`; iOS shows "Yaani Eh".
- Still manual, by the owner: create both store apps and the signing/API
  secrets (`tool/setup_secrets.sh`), fill the privacy and rating forms below,
  review contact details, run Actions → **Store listing**, and re-check both
  stores' screenshot-size pages (Google's sizes are long-standing, not re-read).
- The first release uses `0.1.0` from `pubspec.yaml`; to launch as 1.0.0, merge
  a `feat!:` PR or run Release manually with `major`.

## Both stores

| Field | Value |
|---|---|
| App name | iOS `store/ios/<locale>/name.txt`, Play `store/android/<locale>/title.txt` |
| Price | Free, no in-app purchases, no ads |
| Category | Food & Drink (iOS secondary: Reference) |
| Languages | Arabic (default for Egypt), English |
| Privacy policy | https://3shmawi.github.io/yaani_eh/privacy.html |
| Support / marketing site | https://3shmawi.github.io/yaani_eh |
| Copyright | © 2026 Mohamed Ashmawy |
| Account needed | No. Everything works without signing in |

## What the app collects (both privacy forms)

| Data | Tool | Why | Linked to the person | Used to track |
|---|---|---|---|---|
| Product interaction (screens opened, drinks viewed, saved, previewed; slugs only) | PostHog | Analytics, feature rollout | No | No |
| Crash data, performance data, other diagnostics (device model, OS, app version, error) | Sentry | App functionality (fixing bugs) | No | No |
| An anonymous install ID | PostHog | Analytics (counting installs, not people) | No | No |

Not collected: name, email, phone, location, contacts, photos, payment,
health, browsing history, search text. Favorites stay on the phone and are
never sent. Data is encrypted in transit (HTTPS). No data is sold, and none
is used for advertising.

## App Store Connect

- **Screenshots:** `store/ios/screenshots/<ar-SA|en-US>/`, JPEG, 7 per size:
  iPhone 6.9" (`<n>_iphone69.jpg`, 1320×2868) and iPad 13" (`<n>_ipad13.jpg`,
  2064×2752, required because the app runs on iPad). fastlane deliver
  2.241.2 recognises both by their size. Sizes checked on
  developer.apple.com (Screenshot specifications) on 2026-11-01.
- **iPhone and iPad** (`TARGETED_DEVICE_FAMILY = "1,2"`), every orientation
  on iPad, so Split View and Stage Manager work. Grids (Home, Favorites) use
  the full width; single-column screens (drink, settings, search results,
  sheets, the quiz, step by step, the welcome) stay at most
  `AppDimens.readableWidth` (640 pt) wide, centred.
- **App Privacy:** Data Used to Track You: none. Data Not Linked to You:
  - Usage Data → Product Interaction (Analytics, App Functionality)
  - Diagnostics → Crash Data, Performance Data, Other Diagnostic Data (App Functionality)
  - Identifiers → Device ID (Analytics). This is PostHog's anonymous ID: choose it to be safe.
- **Age rating:** answer None / No to every question: no violence, no
  mature themes, no gambling, no unrestricted web access, no user-generated
  content. Drinks with «mojito» in the name are explained as "no alcohol".
  The result is 4+.
- **Export compliance:** the app only uses HTTPS (standard OS encryption).
  `ITSAppUsesNonExemptEncryption = false` is in `ios/Runner/Info.plist`, so
  App Store Connect doesn't ask on each build (confirmed by the owner on
  2026-11-01).
- **Content rights:** the app doesn't contain, show or access third-party
  content it has no rights to. Drink names are generic. Photos are CC0 /
  public domain (sources in `supabase/content/media/SOURCES.md`); the
  «الأصلي» clips are generated with Piper voices trained on CC0, public
  domain or CC BY data. Check this again when new media is added.
- **Sign-in required:** No.
- **Review notes** (App Review Information → Notes). Apple asked for all
  of this on the first submission (Guideline 2.1 - Information Needed,
  2026-11-18), so send it with every new-app submission. Fill in the
  bracketed parts; keep it under 4,000 characters. Attach the screen
  recording in App Review Information → Attachment, or link it (unlisted
  YouTube or a Drive link anyone can open).

  ```text
  1. SCREEN RECORDING
  [link to video, or "attached below"]. Recorded on [iPhone model], iOS [version], starting from launching the app. The app has no account registration or login (so no account deletion), no user-generated content, and no paid content, in-app purchases or ads.

  2. PURPOSE AND AUDIENCE
  Yaani Eh ("What does it mean?") explains café menu items in plain Egyptian Arabic and English. Café menus in Egypt are full of Italian and English names (Flat White, Cortado, Affogato) that many customers can't read, pronounce or understand. For each drink the app gives its Arabic spelling, a short line that says what it really is, approximate calories, a to-scale picture of the cup's layers, preparation steps, and a recording of how the name is said. Audience: adults and teens (13+) in Egypt and Arabic speakers anywhere who order at cafés or want to make drinks at home.

  3. HOW TO USE IT
  No login, credentials or sample files are needed.
  - First launch: a three-page welcome explains the app (tap Skip / «تخطّي» to leave it) while the drink menu downloads once. Internet is needed for this first download; after that the app works offline.
  - The app opens in Arabic. To switch to English: gear icon at the top of Home → Language.
  - Home: category chips and drink cards. Tap a card to open the drink.
  - Drink page: tap «زي الباريستا» (barista pronunciation) or «الأصلي» (original) to hear the name; 0.75× slows it down.
  - Open Flat White → «طريقة التحضير» / "How it's made" to see the cup drawn to scale, then «خطوة بخطوة» / "Step by step".
  - Search (field at the top of Home): type a name ("cortado") or a description ("something cold with chocolate").
  - Tap the heart to save a favorite; it appears in the Favorites tab. Long-press any card for a quick preview.

  4. EXTERNAL SERVICES
  - Supabase: hosts the read-only menu content (drink text, photos, pronunciation audio). It is not used for sign-in; the app has no accounts.
  - PostHog: anonymous product analytics and feature flags (no personal data, no advertising, no tracking).
  - Sentry: crash and error reporting.
  - Piper (open-source text-to-speech, run offline by us): generated some of the "original" pronunciation clips ahead of time. The app itself makes no calls to it or to any AI service.
  The app uses no payment processors, authentication providers or ad networks. Search runs entirely on the device.

  5. REGIONAL DIFFERENCES
  The app works the same in every region. Nothing is restricted or changed by country. The content is written for Egypt (Egyptian Arabic, how baristas in Egypt say the names), but every feature is available everywhere. The app does not show prices.

  6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
  Not applicable. The app is not in a regulated industry and doesn't sell or deliver anything. All drink descriptions and recipes are our own. Any "barista" pronunciation recordings are our own; the "original" pronunciation clips were generated with Piper voices trained on CC0, public-domain or CC BY data. Drink photos are CC0 (public domain) from the WordPress Photo Directory, with no café brands, logos or people. Drink names are generic. Calories are approximate and shown for general information, not as health advice.
  ```

  Keep items 4 and 6 true: a new service (an AI or text-to-speech tool
  included) goes in item 4, and new media sources go in item 6 and
  `supabase/content/media/SOURCES.md`.
- **Screen recording:** a real iPhone (not the Simulator) on the latest
  iOS, iOS screen recording from Control Center, starting with the app
  deleted so the video opens on launch and the first menu download. About
  2 minutes: welcome (or Skip) → Home, a category chip → a drink, both
  pronunciations → "How it's made" → Step by step → search "something cold
  with chocolate", open a result → a heart, the Favorites tab, a long-press
  preview → Settings, switch to English → (optional) airplane mode, still
  works.
- **Contact for review:** your name, phone and email (only App Review sees them).

## Google Play Console

- **Graphics:** `store/android/<ar|en-US>/images/`. There's `icon.png` (512×512),
  `featureGraphic.png` (1024×500), and 7 screenshots each in
  `phoneScreenshots` (1080×1920), `sevenInchScreenshots` (1200×1920) and
  `tenInchScreenshots` (1600×2560).
- **App access:** all functionality is available without special access.
- **Ads:** No.
- **Content rating (IARC):** category Reference, News, or Educational; answer No to
  everything. The expected result is Everyone / PEGI 3.
- **Target audience:** 13 and over (the privacy policy says the app isn't
  directed to children under 13). It doesn't appeal to children.
- **Data safety:**
  - Collected: App activity → App interactions (Analytics), App info and
    performance → Crash logs, Diagnostics (App functionality, Analytics),
    Device or other IDs (Analytics).
  - Shared with third parties: No. Service providers processing data for us
    don't count as sharing.
  - Processed ephemerally: No. Collection is required: Yes, it can't be
    turned off in the app yet.
  - Encrypted in transit: Yes.
  - Can users request deletion: Yes, by email
    (https://3shmawi.github.io/yaani_eh/delete-account.html). The app has no
    accounts, so that page says how: delete the app for what's on the phone,
    email for what we hold.
- **News, health, finance, government apps:** No to all.

## Re-making the screenshots

```bash
./scripts/store_shots.sh
```

This renders the app's screens from the real launch content
(`supabase/content/`) at every device size, in Arabic and English, frames
each one with its caption (`tool/store/frame.js`), and makes the feature
graphic and icons (`tool/store/graphics.js`). It takes about 9 minutes.

Run it again after a UI change or when drink photos arrive: only some drinks
have photos (`supabase/content/media/`); the rest show the drink's initial.
