#!/usr/bin/env bash
# TEMPORARY: surfaces the integration test output as an annotation.
flutter test integration_test --dart-define-from-file=env/example.json > it.log 2>&1
code=$?
cat it.log
if [ "$code" -ne 0 ]; then
  { grep -n -E "EXCEPTION CAUGHT|The following|Exception|Error:|Expected|Actual|Which|timed out|Failed" it.log | head -60; echo "----- tail -----"; tail -n 70 it.log; } > it_key.log
  body=$(sed 's/%/%25/g; s/\r//g' it_key.log | awk '{printf "%s%%0A", $0}')
  echo "::error title=integration log::$body"
fi
exit "$code"
