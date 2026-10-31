# Store submission answers

What App Store Connect and the Play Console ask for that isn't uploaded from
`store/` by the **Store listing** workflow. Keep it true: if the app starts
collecting something new, update this page, `website/privacy.html` and both
stores' privacy forms in the same PR.

Checked against the app on 2026-10-31. Apple's screenshot sizes were read on
developer.apple.com that day; Google's help pages weren't reachable from the
session that wrote this, so the Play sizes are its long-standing ones.
Re-check both pages before the first upload.

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

- **Screenshots:** `store/ios/screenshots/<ar-SA|en-US>/`. There are 7 for iPhone
  6.9" (1320×2868) and 7 for iPad 13" (2064×2752). The app supports
  iPad (`TARGETED_DEVICE_FAMILY = 1,2`), so iPad screenshots are required.
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
  App Store Connect doesn't ask on each build. Confirm this is right for you;
  it's a legal declaration.
- **Content rights:** the app doesn't contain, show or access third-party
  content it has no rights to. Drink names are generic. There are no photos
  yet; check this again when photos are added.
- **Sign-in required:** No.
- **Review notes:**

  > No account needed. On first launch the app downloads the drink menu once
  > (internet needed for that), then works offline. Try: long-press a drink
  > card for a quick look; open Flat White → «طريقة التحضير» / "How it's
  > made" → «خطوة بخطوة» / "Step by step"; search "something cold with
  > chocolate". The app's language defaults to Arabic; switch it in
  > Settings (gear icon, top of Home).

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
    (https://3shmawi.github.io/yaani_eh/delete-account.html).
- **News, health, finance, government apps:** No to all.

## Re-making the screenshots

```bash
./scripts/store_shots.sh
```

This renders the app's screens from the real launch content
(`supabase/content/`) at every device size, in Arabic and English, frames
each one with its caption (`tool/store/frame.js`), and makes the feature
graphic and icons (`tool/store/graphics.js`). It takes about 9 minutes.

Run it again after a UI change or when drink photos arrive: the drinks have
no photos yet, so their tiles show the drink's initial.
