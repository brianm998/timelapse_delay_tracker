#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
A=TimelapseDelayTracker/Assets.xcassets/AppIcon.appiconset/AppIcon.png
[ "$(sips -g pixelWidth -g pixelHeight "$A" | grep -c ' 1024')" = 2 ]
sips -g hasAlpha "$A" | grep -q 'no'
sips -g profile "$A" | grep -q sRGB
grep -q '^Summary: ' docs/stages/s365.md
