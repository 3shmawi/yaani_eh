#!/usr/bin/env bash
# TEMPORARY: surfaces the integration test output as annotations.
flutter test integration_test --dart-define-from-file=env/example.json > it.log 2>&1
code=$?
cat it.log
if [ "$code" -ne 0 ]; then
  echo "exit code: $code" > it_key.log
  grep -v -E 'Unzipping|^\[=*' it.log | tail -n 120 >> it_key.log
  # GitHub caps an annotation at 4096 chars: send ~3500-char chunks.
  split -C 3500 -d it_key.log chunk_
  n=0
  for c in chunk_*; do
    n=$((n + 1)); [ "$n" -gt 9 ] && break
    body=$(sed 's/%/%25/g; s/\r//g' "$c" | awk '{printf "%s%%0A", $0}')
    echo "::error title=integration log part $n::$body"
  done
fi
exit "$code"
