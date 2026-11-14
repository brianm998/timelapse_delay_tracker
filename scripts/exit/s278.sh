#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
bash -n scripts/release.sh
if command -v shellcheck >/dev/null; then shellcheck scripts/release.sh; fi
plutil -lint scripts/ExportOptions.plist
for s in "com.brianmartin.TimelapseDelayTracker" "App Manager" "release.env" "privacy" "App Privacy" "age rating" "screenshots" "submit for review"; do
  grep -qi "$s" RELEASING.md
done
scripts/check_metadata.sh
grep -q '^Summary: ' docs/stages/s278.md
