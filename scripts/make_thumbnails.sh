#!/usr/bin/env bash
# Makes the small WebP thumbnail that drink cards load, next to each photo:
#   latte.webp → latte.thumb.webp   (any photo extension; docs/content.md)
#
#   ./scripts/make_thumbnails.sh <photo or folder>... [--force]
#
# 400 px wide (height keeps the 3:4 shape, ≈ 400×533), metadata stripped,
# quality lowered step by step until the file is ≤ 40 KB. Existing
# thumbnails newer than their photo are kept unless --force. Then upload
# the photo and its thumbnail to the `item-images` bucket side by side.
#
# Needs cwebp (libwebp): `brew install webp` / `apt install webp`. Uses
# `-resize_mode down_only` (libwebp ≥ 1.6.0) when available so a small
# photo is never blown up.
set -euo pipefail

WIDTH=400
MAX_BYTES=$((40 * 1024))
START_Q=82
MIN_Q=50

force=false
inputs=()
for arg in "$@"; do
  case "$arg" in
    --force) force=true ;;
    -h | --help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) inputs+=("$arg") ;;
  esac
done
if [ ${#inputs[@]} -eq 0 ]; then
  echo "Usage: $0 <photo or folder>... [--force]" >&2
  exit 2
fi
if ! command -v cwebp >/dev/null 2>&1; then
  echo "cwebp not found — install libwebp: brew install webp (macOS) or apt install webp." >&2
  exit 1
fi

resize=(-resize "$WIDTH" 0)
if cwebp -longhelp 2>&1 | grep -q -- '-resize_mode'; then
  resize+=(-resize_mode down_only)
fi

file_size() { wc -c <"$1" | tr -d ' '; }

# Photos to process: the files given, and the photos in the folders given
# (not their sub-folders), never thumbnails themselves.
photos=()
for input in "${inputs[@]}"; do
  if [ -d "$input" ]; then
    while IFS= read -r -d '' f; do photos+=("$f"); done < <(
      find "$input" -maxdepth 1 -type f \
        \( -iname '*.webp' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
        ! -name '*.thumb.webp' -print0 | sort -z
    )
  elif [ -f "$input" ]; then
    photos+=("$input")
  else
    echo "Not found: $input" >&2
    exit 1
  fi
done

if [ ${#photos[@]} -eq 0 ]; then
  echo "No photos found (.webp, .jpg, .jpeg, .png)."
  exit 0
fi

made=0 kept=0 big=0
for photo in "${photos[@]}"; do
  case "$photo" in *.thumb.webp) continue ;; esac
  name=$(basename "$photo")
  dir=$(dirname "$photo")
  # Same rule as MediaUrls.thumbnailPath: drop the extension unless the
  # name starts with its only dot.
  stem="$name"
  case "$name" in ?*.*) stem="${name%.*}" ;; esac
  thumb="$dir/$stem.thumb.webp"

  if [ "$force" = false ] && [ -f "$thumb" ] && [ "$thumb" -nt "$photo" ]; then
    kept=$((kept + 1))
    continue
  fi

  q=$START_Q
  tmp="$thumb.tmp"
  while :; do
    cwebp -quiet -q "$q" -m 6 -sharp_yuv -metadata none "${resize[@]}" \
      "$photo" -o "$tmp"
    size=$(file_size "$tmp")
    if [ "$size" -le "$MAX_BYTES" ] || [ "$q" -le "$MIN_Q" ]; then break; fi
    q=$((q - 5))
  done
  mv "$tmp" "$thumb"
  made=$((made + 1))
  note=""
  if [ "$size" -gt "$MAX_BYTES" ]; then
    big=$((big + 1))
    note="  ⚠ over 40 KB at the lowest quality — check the photo"
  fi
  printf '%s → %s  %d KB (q %d)%s\n' "$name" "$(basename "$thumb")" \
    "$(((size + 1023) / 1024))" "$q" "$note"
done

summary="Thumbnails: $made made, $kept already up to date"
if [ "$big" -gt 0 ]; then summary="$summary, $big over 40 KB"; fi
echo "$summary."
