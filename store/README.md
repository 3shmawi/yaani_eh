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
- `store/ios/screenshots/<ar-SA|en-US>/<n>_iphone69.jpg` (1320×2868), `<n>_ipad13.jpg` (2064×2752)
- `store/android/<ar|en-US>/images/phoneScreenshots/<n>.jpg` (1080×1920),
  `sevenInchScreenshots/` (1200×1920), `tenInchScreenshots/` (1600×2560)
- `store/android/<ar|en-US>/images/featureGraphic.png` (1024×500), `icon.png` (512)
- `store/assets/app_store_icon_1024.png` (reference only: the App Store takes the icon from the build)

Captions live in `tool/store/frame.js`. The workflow uploads screenshots
and images only when those files exist.

## Everything else the stores ask
Privacy labels, Data safety, age and content rating, export compliance and
review notes: [submission.md](submission.md).
