#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
bash -n scripts/release.sh
if command -v shellcheck >/dev/null; then shellcheck scripts/release.sh; fi
[[ "$(scripts/release.sh --help)" == *--ci* ]]
if env -u ASC_KEY_P8_BASE64 -u ASC_KEY_PATH scripts/release.sh --ci 2>/dev/null; then exit 1; fi
grep -q 'From GitHub Actions' RELEASING.md
grep -q '^Summary: ' docs/stages/s367.md
