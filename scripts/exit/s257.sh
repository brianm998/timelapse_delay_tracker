#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
scripts/check_metadata.sh
grep -q '^Summary: ' docs/stages/s257.md
