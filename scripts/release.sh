#!/bin/bash
# Archive and upload a build to App Store Connect. Run by the owner.
# Usage: scripts/release.sh [--dry-run] [--push]
set -euo pipefail
cd "$(dirname "$0")/.."

DRY_RUN=0
PUSH=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --push) PUSH=1 ;;
    -h|--help)
      echo "Usage: scripts/release.sh [--dry-run] [--push]"
      echo "  --dry-run  archive and export to build/export; no upload, no credentials, no file edits"
      echo "  --push     after a successful upload, push develop and the tag"
      exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

SCHEME=TimelapseDelayTracker
PBXPROJ=TimelapseDelayTracker.xcodeproj/project.pbxproj
ARCHIVE=build/TimelapseDelayTracker.xcarchive

if [ "$DRY_RUN" -eq 0 ]; then
  if [ -f scripts/release.env ]; then
    set -a
    # shellcheck disable=SC1091
    . scripts/release.env
    set +a
  fi
  for var in ASC_KEY_PATH ASC_KEY_ID ASC_ISSUER_ID; do
    if [ -z "${!var:-}" ]; then
      echo "Missing $var: set it in the environment or in scripts/release.env" >&2
      exit 1
    fi
  done
  if [ ! -f "$ASC_KEY_PATH" ]; then
    echo "ASC_KEY_PATH does not point to an existing file" >&2
    exit 1
  fi
  if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree is not clean; commit or stash first" >&2
    exit 1
  fi
  if [ "$(git rev-parse --abbrev-ref HEAD)" != develop ]; then
    echo "Not on develop; releases are cut from develop" >&2
    exit 1
  fi
fi

MARKETING=$(xcodebuild -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
  | awk '$1 == "MARKETING_VERSION" { print $3; exit }')
if [ -z "$MARKETING" ]; then
  echo "Could not read MARKETING_VERSION" >&2
  exit 1
fi
BUILD=$(git rev-list --count HEAD)
echo "Release $MARKETING ($BUILD)"

EXTRA=()
if [ -n "${CODE_SIGNING_ALLOWED:-}" ]; then
  EXTRA+=("CODE_SIGNING_ALLOWED=$CODE_SIGNING_ALLOWED")
fi

restore() { git checkout -- "$PBXPROJ" 2>/dev/null || true; }

if [ "$DRY_RUN" -eq 0 ]; then
  trap restore ERR
  xcrun agvtool new-version -all "$BUILD" >/dev/null
else
  EXTRA+=("CURRENT_PROJECT_VERSION=$BUILD")
fi

rm -rf "$ARCHIVE"
xcodebuild archive -scheme "$SCHEME" -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" -allowProvisioningUpdates ${EXTRA[@]+"${EXTRA[@]}"}

if [ "$DRY_RUN" -eq 1 ]; then
  cp scripts/ExportOptions.plist build/ExportOptions-dryrun.plist
  /usr/libexec/PlistBuddy -c 'Set :destination export' build/ExportOptions-dryrun.plist
  xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath build/export \
    -exportOptionsPlist build/ExportOptions-dryrun.plist -allowProvisioningUpdates
  echo "Dry run complete: build/export"
  exit 0
fi

xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath build/upload \
  -exportOptionsPlist scripts/ExportOptions.plist -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"

trap - ERR
TAG="v$MARKETING-$BUILD"
git add "$PBXPROJ"
git commit -m "Release $TAG"
git tag "$TAG"
echo "Uploaded and tagged $TAG"
if [ "$PUSH" -eq 1 ]; then
  git push origin develop "$TAG"
else
  echo "Not pushed. Run: git push origin develop $TAG"
fi
