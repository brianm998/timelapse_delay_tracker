#!/bin/bash
# Fails if an App Store metadata field is missing or over its character limit.
set -euo pipefail
cd "$(dirname "$0")/.."
M=AppStore/metadata/en-US
fail=0
len() { python3 -I -c 'import sys;print(len(open(sys.argv[1],encoding="utf-8").read().rstrip("\n")))' "$1"; }
check() { # file limit
  local f="$M/$1.txt"
  if [ ! -f "$f" ]; then echo "MISSING $f"; fail=1; return; fi
  local n; n=$(len "$f")
  if [ "$n" -gt "$2" ]; then echo "TOO LONG $f: $n > $2"; fail=1; else echo "ok $1: $n/$2"; fi
}
check name 30; check subtitle 30; check description 4000
check keywords 100; check promotional_text 170
for f in release_notes support_url privacy_url; do
  [ -f "$M/$f.txt" ] || { echo "MISSING $M/$f.txt"; fail=1; }
done
for f in PRIVACY.md review_notes.txt app_privacy.md; do
  [ -f "AppStore/$f" ] || { echo "MISSING AppStore/$f"; fail=1; }
done
if [ -f "$M/keywords.txt" ] && [ -f "$M/name.txt" ] && [ -f "$M/subtitle.txt" ]; then
  words=$(cat "$M/name.txt" "$M/subtitle.txt" | tr 'A-Z,-' 'a-z  ' | tr -s ' \n' '\n\n' | sort -u)
  kw=$(tr 'A-Z,-' 'a-z  ' < "$M/keywords.txt" | tr -s ' \n' '\n\n' | sort -u)
  dup=$(comm -12 <(echo "$words") <(echo "$kw") | grep -v '^$' || true)
  if [ -n "$dup" ]; then echo "keywords repeat name/subtitle words: $dup"; fail=1; fi
fi
exit $fail
