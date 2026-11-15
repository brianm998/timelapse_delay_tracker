#!/bin/bash
# Self-test for check_store_urls.sh using temp fixtures only.
set -euo pipefail
S="$(cd "$(dirname "$0")" && pwd)/check_store_urls.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
expect() { # name want-status dir
  local rc=0; "$S" "$3" >/dev/null 2>&1 || rc=$?
  if { [ "$2" = pass ] && [ $rc -ne 0 ]; } || { [ "$2" = fail ] && [ $rc -eq 0 ]; }; then
    echo "FAIL: $1"; exit 1; fi
  echo "ok: $1"
}
mkdir "$T/ph"; echo "https://Example.COM/privacy" > "$T/ph/privacy_url.txt"; echo "https://real.test/s" > "$T/ph/support_url.txt"
expect "placeholder privacy" fail "$T/ph"
mkdir "$T/ph2"; echo "https://real.test/p" > "$T/ph2/privacy_url.txt"; echo "https://example.com/s" > "$T/ph2/support_url.txt"
expect "placeholder support" fail "$T/ph2"
mkdir "$T/miss"; echo "https://real.test/p" > "$T/miss/privacy_url.txt"
expect "missing file" fail "$T/miss"
mkdir "$T/good"; echo "https://real.test/p" > "$T/good/privacy_url.txt"; echo "https://real.test/s" > "$T/good/support_url.txt"
expect "real urls" pass "$T/good"
