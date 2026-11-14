#!/bin/bash
# Render the App Store screenshots offscreen and copy them into AppStore/screenshots/.
#   scripts/screenshots.sh
set -euo pipefail
cd "$(dirname "$0")/.."

stage="$PWD/build/screenshots"
rm -rf "$stage"
mkdir -p "$stage"

run() {
  SCREENSHOT_DIR="$stage" TEST_RUNNER_SCREENSHOT_DIR="$stage" \
    scripts/test.sh -only-testing:TimelapseDelayTrackerTests/StoreScreenshotTests
}

run
TDT_DEVICE_TYPE="iPad Pro 13-inch (M4)" run

rm -rf AppStore/screenshots/iphone-6.9 AppStore/screenshots/ipad-13
mkdir -p AppStore/screenshots/iphone-6.9 AppStore/screenshots/ipad-13
cp "$stage"/iphone-6.9-*.png AppStore/screenshots/iphone-6.9/
cp "$stage"/ipad-13-*.png AppStore/screenshots/ipad-13/

fail=0
check() { # file expected-width expected-height
  local w h
  w="$(sips -g pixelWidth "$1" | awk '/pixelWidth/ {print $2}')"
  h="$(sips -g pixelHeight "$1" | awk '/pixelHeight/ {print $2}')"
  if [ "$w" != "$2" ] || [ "$h" != "$3" ]; then
    echo "screenshots.sh: $1 is ${w}x${h}, expected $2x$3" >&2
    fail=1
  fi
}
for f in AppStore/screenshots/iphone-6.9/*.png; do check "$f" 1320 2868; done
for f in AppStore/screenshots/ipad-13/*-portrait-*.png; do check "$f" 2064 2752; done
for f in AppStore/screenshots/ipad-13/*-landscape-*.png; do check "$f" 2752 2064; done
[ "$(ls AppStore/screenshots/iphone-6.9 | wc -l)" -eq 3 ] || { echo "expected 3 iPhone PNGs" >&2; fail=1; }
[ "$(ls AppStore/screenshots/ipad-13 | wc -l)" -eq 6 ] || { echo "expected 6 iPad PNGs" >&2; fail=1; }
exit $fail
