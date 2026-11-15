#!/bin/bash
# Fails while the App Store support/privacy URLs are missing or still placeholders.
# Usage: check_store_urls.sh [metadata-dir]   (default AppStore/metadata/en-US)
set -euo pipefail
if [ $# -ge 1 ]; then M="$1"; else cd "$(dirname "$0")/.."; M=AppStore/metadata/en-US; fi
fail=0
for f in privacy_url support_url; do
  p="$M/$f.txt"
  if [ ! -f "$p" ]; then echo "MISSING $p"; fail=1
  elif grep -qi 'example\.com' "$p"; then echo "PLACEHOLDER $p still contains example.com"; fail=1
  else echo "ok $f"; fi
done
exit $fail
