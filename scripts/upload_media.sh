#!/usr/bin/env bash
# Uploads supabase/content/media/<bucket>/* to the Supabase Storage bucket of
# the same name (item-images, item-audio), one file at a time, overwriting
# what's there. Run by .github/workflows/supabase.yml BEFORE `db push`, so a
# migration never points the app at a file that isn't uploaded yet.
#
#   ./scripts/upload_media.sh            # the linked project (supabase link)
#   UPLOAD_TARGET=--local ./scripts/upload_media.sh
#
# Needs the Supabase CLI (storage commands are experimental in 2.120.0) and,
# for --linked, SUPABASE_ACCESS_TOKEN in the environment: the CLI fetches the
# project's service key itself and never prints it. Files are never renamed
# here: a changed photo or clip gets a new file name (docs/content.md), so
# overwriting only ever rewrites the same bytes.
#
# Why one file at a time: `storage cp -r <dir> ss:///<bucket>` nests the files
# under a second <bucket>/ folder; `cp -r <file> ss:///<bucket>/<name>` puts
# the file at exactly <name>, and -r is the mode that overwrites (x-upsert).
set -euo pipefail

SUPABASE_BIN=${SUPABASE_BIN:-supabase}
UPLOAD_TARGET=${UPLOAD_TARGET:---linked}
ROOT=${MEDIA_ROOT:-supabase/content/media}
# Names change when content changes, so a file can be cached for a year.
CACHE_CONTROL='max-age=31536000'

case "$UPLOAD_TARGET" in --linked | --local) ;; *)
  echo "UPLOAD_TARGET must be --linked or --local" >&2
  exit 2
  ;;
esac

content_type() {
  case "$1" in
    *.webp) echo image/webp ;;
    *.jpg | *.jpeg) echo image/jpeg ;;
    *.png) echo image/png ;;
    *.m4a) echo audio/mp4 ;;
    *.mp3) echo audio/mpeg ;;
    *) return 1 ;;
  esac
}

uploaded=0
for bucket in item-images item-audio; do
  dir="$ROOT/$bucket"
  [ -d "$dir" ] || continue
  while IFS= read -r -d '' file; do
    name=$(basename "$file")
    # Same rule as the app and the buckets: plain names only.
    if ! [[ "$name" =~ ^[a-z0-9_]+(\.[a-z0-9_]+)*\.[a-z0-9]+$ ]]; then
      echo "Skipping $file: name must be lowercase letters, digits, _ and dots." >&2
      exit 1
    fi
    if ! type=$(content_type "$name"); then
      echo "Skipping $file: unknown file type." >&2
      exit 1
    fi
    "$SUPABASE_BIN" storage cp "$UPLOAD_TARGET" --experimental -r \
      --content-type "$type" --cache-control "$CACHE_CONTROL" \
      "$file" "ss:///$bucket/$name" >/dev/null
    echo "Uploaded $bucket/$name ($type)"
    uploaded=$((uploaded + 1))
  done < <(find "$dir" -maxdepth 1 -type f ! -name '.*' -print0 | sort -z)
done
echo "Media: $uploaded file(s) uploaded."
