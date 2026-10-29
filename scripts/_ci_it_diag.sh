#!/usr/bin/env bash
# TEMPORARY: surfaces the integration test output + device crash log as annotations.
adb logcat -c || true
timeout 600 flutter test integration_test --reporter expanded --dart-define-from-file=env/example.json > it.log 2>&1
code=$?
cat it.log
if [ "$code" -ne 0 ]; then
  {
    echo "exit code: $code"
    grep -v -E 'Unzipping|^\[=*|available\)$' it.log | tail -n 25
    echo "===== logcat (crash/errors) ====="
    adb logcat -d -b crash 2>/dev/null | tail -n 60
    adb logcat -d 2>/dev/null | grep -E 'YE_STEP|flutter|Impeller|FATAL|AndroidRuntime|SIGSEGV|SIGABRT|ANR in|has died|Choreographer|Skipped .* frames' | tail -n 120
  } > it_key.log
  split -C 3500 -d it_key.log chunk_
  n=0
  for c in chunk_*; do
    n=$((n + 1)); [ "$n" -gt 9 ] && break
    body=$(sed 's/%/%25/g; s/\r//g' "$c" | awk '{printf "%s%%0A", $0}')
    echo "::error title=integration log part $n::$body"
  done
fi
exit "$code"
