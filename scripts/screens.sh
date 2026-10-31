#!/usr/bin/env bash
# Screenshots of the app's main screens (Arabic + English, dark) in
# build/screens/, for reviewing a change by eye before a PR. Runs on any
# machine, no simulator: real screens, the app's fonts, glass in its solid
# look. The iPhone simulator's own screenshots (full glass) come with the
# Demo video comment on every PR.
#   scripts/screens.sh            # iPhone 15 (393×852 pt)
#   scripts/screens.sh 430x932    # another size in points (Pro Max)
#   scripts/screens.sh 375x667 --sheet   # also one contact sheet per language
set -euo pipefail
cd "$(dirname "$0")/.."
size=${1:-393x852}
rm -rf build/screens
flutter test test/screens --update-goldens \
  --dart-define=SCREENS=true --dart-define=SCREENS_SIZE="$size" >/dev/null
if [ "${2:-}" = --sheet ] && command -v ffmpeg >/dev/null; then
  for lang in ar en; do
    ffmpeg -y -loglevel error -pattern_type glob -i "build/screens/${lang}_*.png" \
      -vf "scale=360:-2,tile=5x2:padding=12:color=0x14100D" -frames:v 1 \
      "build/screens/sheet_$lang.png"
  done
fi
ls build/screens
