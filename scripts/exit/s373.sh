#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
actionlint .github/workflows/*.yml
grep -q 'setup-xcode' .github/workflows/ci.yml
! grep -n 'secrets\.' .github/workflows/testflight.yml | grep -v -E 'ASC_[A-Z0-9_]+: \$\{\{ secrets\.ASC_' 
grep -q 'ASC_KEY_P8_BASE64' RELEASING.md
grep -q 'ASC_KEY_P8_BASE64' docs/CI.md
grep -q '^Summary: ' docs/stages/s373.md
