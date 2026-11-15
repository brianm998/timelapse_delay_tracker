#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
/usr/local/bin/actionlint .github/workflows/ci.yml
test -f docs/CI.md
grep -q "^Summary: " docs/stages/s366.md
