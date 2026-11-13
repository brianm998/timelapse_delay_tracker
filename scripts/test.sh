#!/bin/bash
# Run the test suite on a throwaway simulator: created for this run, booted headless by
# xcodebuild (no Simulator window), deleted afterwards. A private device means parallel runs
# never share one, and the run never touches simulators another pipeline is using.
#
#   scripts/test.sh [extra xcodebuild args...]
#   TDT_DEVICE_TYPE="iPad Pro 13-inch (M4)" scripts/test.sh
set -euo pipefail
cd "$(dirname "$0")/.."

device_type="${TDT_DEVICE_TYPE:-iPhone 17}"
runtime="${TDT_RUNTIME:-$(xcrun simctl list runtimes iOS -j | /usr/bin/python3 -I -c '
import json, sys
rs = [r for r in json.load(sys.stdin)["runtimes"] if r.get("isAvailable")]
print(max(rs, key=lambda r: [int(x) for x in r["version"].split(".")])["identifier"])')}"

udid="$(xcrun simctl create "tdt-test-$$" "$device_type" "$runtime")"
cleanup() {
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
  xcrun simctl delete "$udid" >/dev/null 2>&1 || true
}
trap cleanup EXIT
echo "test.sh: $device_type on $runtime as $udid"

rm -rf build/test.xcresult
xcodebuild test \
  -project TimelapseDelayTracker.xcodeproj \
  -scheme TimelapseDelayTracker \
  -destination "id=$udid" \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/test.xcresult \
  "$@" 2>&1
