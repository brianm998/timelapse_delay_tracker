#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
actionlint .github/workflows/*.yml
scripts/test_check_store_urls.sh
! scripts/check_store_urls.sh >/dev/null
grep -q 'skip_binary_upload: true' fastlane/Fastfile
grep -q 'automatic_release: false' fastlane/Fastfile
grep -q 'Submitting for review from GitHub' RELEASING.md
grep -q '^Summary: ' docs/stages/s376.md
