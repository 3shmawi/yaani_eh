#!/usr/bin/env bash
# TEMPORARY: integration test diagnostics. Every step is time-boxed so the
# job always ends with readable annotations, even if the emulator hangs.
note() { echo "::notice title=diag $(date -u +%H:%M:%S)::$*"; }
note "script started; device: $(timeout 20 adb get-state 2>&1)"
timeout 20 adb logcat -c || true
timeout 900 adb logcat -v time > logcat.txt 2>&1 &
logpid=$!
timeout 480 flutter test integration_test --reporter expanded --dart-define-from-file=env/example.json --dart-define=GLASS_LITE=true > it.log 2>&1
code=$?
note "flutter test finished with exit code $code (124 = killed by the 8-minute limit)"
kill "$logpid" 2>/dev/null || true
note "device after test: $(timeout 20 adb get-state 2>&1)"
cat it.log
{
  echo "exit code: $code"
  grep -v -E 'Unzipping|^\[=*|available\)$' it.log | tail -n 30
  echo "===== device log ====="
  grep -E 'YE_STEP|flutter|Impeller|FATAL|AndroidRuntime|SIGSEGV|SIGABRT|ANR in|has died|Skipped .* frames|vulkan|Vulkan|EGL|GLES' logcat.txt | tail -n 120
} > it_key.log
split -C 3500 -d it_key.log chunk_
n=0
for c in chunk_*; do
  n=$((n + 1)); [ "$n" -gt 9 ] && break
  body=$(sed 's/%/%25/g; s/\r//g' "$c" | awk '{printf "%s%%0A", $0}')
  echo "::error title=integration log part $n::$body"
done
exit "$code"
