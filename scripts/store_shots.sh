#!/usr/bin/env bash
# Makes every store screenshot, in Arabic and English, from the real launch
# content (supabase/content): the app's screens rendered at each device's
# size (test/screens/store_shots_test.dart), then framed with a caption
# (tool/store/frame.js). Writes them where the Store listing workflow
# uploads them from:
#   store/ios/screenshots/<ar-SA|en-US>/<n>_iphone69.jpg, <n>_ipad13.jpg
#   store/android/<ar|en-US>/images/{phone,sevenInch,tenInch}Screenshots/<n>.jpg
# (JPEG at quality 90: a quarter of the PNG size, accepted by both stores)
# plus the Play feature graphic and icon, and the App Store icon.
#   scripts/store_shots.sh
# Needs Flutter, Python 3 and Node with Playwright (preinstalled in CI images
# and Claude Code sessions).
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tool/store/catalog_fixture.py build/store/catalog.json

# device id | points@scale to render | final store size | where it goes
devices=(
  "iphone69|440x956@3|1320x2868|ios"
  "ipad13|1032x1376@2|2064x2752|ios"
  "phone|360x640@3|1080x1920|phoneScreenshots"
  "seven|600x960@2|1200x1920|sevenInchScreenshots"
  "ten|800x1280@2|1600x2560|tenInchScreenshots"
)
shots=(1_home 2_drink 3_preview 4_recipe 5_steps 6_search 7_favorites)

for entry in "${devices[@]}"; do
  IFS='|' read -r id render size dest <<<"$entry"
  for lang in ar en; do
    raw="build/screens/raw/$id/$lang"
    rm -rf "$raw"
    flutter test test/screens/store_shots_test.dart --update-goldens \
      --dart-define=SCREENS=true --dart-define=STORE_DEVICE="$render" \
      --dart-define=STORE_LANG="$lang" --dart-define=STORE_OUT="raw/$id/$lang" >/dev/null
    w=${size%x*}; h=${size#*x}
    for i in "${!shots[@]}"; do
      n=$((i + 1))
      if [ "$dest" = ios ]; then
        locale=$([ "$lang" = ar ] && echo ar-SA || echo en-US)
        out="store/ios/screenshots/$locale/${n}_$id.jpg"
      else
        locale=$([ "$lang" = ar ] && echo ar || echo en-US)
        out="store/android/$locale/images/$dest/$n.jpg"
      fi
      node tool/store/frame.js "$raw" "$out" "$w" "$h" "$lang" "${shots[$i]}"
    done
    echo "✓ $id $lang"
  done
done

node tool/store/graphics.js
echo "✓ store graphics"
