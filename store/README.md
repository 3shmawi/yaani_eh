# Store listings (as code)

Edit the text files, open a PR, then run **Actions → Store listing**
(manual) to upload them. Google Play uses `store/android/<locale>/`, the App
Store uses `store/ios/<locale>/` — fastlane `supply` / `deliver` layouts.

| File | Limit |
|---|---|
| android `title.txt` | 30 chars |
| android `short_description.txt` | 80 chars |
| android `full_description.txt` | 4000 chars |
| ios `name.txt`, `subtitle.txt` | 30 chars each |
| ios `keywords.txt` | 100 chars, comma-separated |
| ios `promotional_text.txt` | 170 chars |
| ios `description.txt` | 4000 chars |
| ios `release_notes.txt` ("What's New") | 4000 chars |
| android `changelogs/default.txt` ("What's new") | 500 chars |
| ios `copyright.txt` | App Store "Copyright", one line: `<year> <owner>` (no ©); update the year when it changes |
| ios `review_information/notes.txt` | App Review notes (how to try the app); required, see docs/release.md |

`test/store/listing_test.dart` fails if a limit is exceeded or a placeholder
("Feature one", "keyword1", "اكتب هنا") is still there when you run the
upload workflow.

## Screenshots and graphics
Made from the app itself, not drawn by hand:

```bash
./scripts/store_shots.sh
```

It renders the main screens from the real launch content at every store
size, in Arabic and English, adds a caption to each, and writes them where
the workflow uploads from:
- `store/ios/screenshots/<ar-SA|en-US>/<n>_iphone69.jpg` (1320×2868) and `<n>_ipad13.jpg` (2064×2752, the app runs on iPad)
- `store/android/<ar|en-US>/images/phoneScreenshots/<n>.jpg` (1080×1920),
  `sevenInchScreenshots/` (1200×1920), `tenInchScreenshots/` (1600×2560)
- `store/android/<ar|en-US>/images/featureGraphic.png` (1024×500), `icon.png` (512)
- `store/assets/app_store_icon_1024.png` (reference only: the App Store takes the icon from the build)

Captions live in `tool/store/frame.js`. The workflow uploads screenshots
and images only when those files exist.

## Brand video
A vertical motion video of every feature (Reels, TikTok, Shorts, store preview
source) is generated from code: see `tool/brand_video/README.md`.

## Everything else the stores ask
Privacy labels, Data safety, age and content rating, export compliance and
review notes: [submission.md](submission.md).

## What's new
`store/ios/<locale>/release_notes.txt` (App Store "What's New in This
Version") and `store/android/<locale>/changelogs/default.txt` (Play "What's
new") are uploaded by **Store listing**, in Arabic and English. Update both
before each store release. On Play the notes go on the latest release of the
track release.yml uploads to (`PLAY_TRACK`, default `internal`), replacing
the English notes release.yml writes from the commits; run Store listing
after the release build is on Play. Apple shows no "What's New" for an app's
first version.

## Play Console App content
The Play Console "App content" forms (privacy policy, app access, ads,
content rating, target audience, data safety, government, financial
features, health, category and contact) have no API. Their answers live in
[`play_app_content.json`](play_app_content.json), filled from the code.
Open `store/tools/app_content.html` to copy them in: one card per Play
Console screen, a copy button per answer and a checkmark per step. From disk
the browser asks for the JSON file; or serve the folder
(`python3 -m http.server -d store`, then `/tools/app_content.html`).
