#!/bin/bash
# Archive and upload a build to App Store Connect. Run by the owner.
# Usage: scripts/release.sh [--dry-run] [--push] [--ci]
set -euo pipefail
cd "$(dirname "$0")/.."

DRY_RUN=0
PUSH=0
CI=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --push) PUSH=1 ;;
    --ci) CI=1 ;;
    -h|--help)
      echo "Usage: scripts/release.sh [--dry-run] [--push] [--ci]"
      echo "  --dry-run  archive and export to build/export; no upload, no credentials, no file edits"
      echo "  --push     after a successful upload, push develop and the tag"
      echo "  --ci       GitHub Actions mode: key from ASC_KEY_P8_BASE64 (or ASC_KEY_PATH), API-key signing,"
      echo "             build number from BUILD_NUMBER or commit count, no commit, pushes only the tag"
      exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

SCHEME=TimelapseDelayTracker
PBXPROJ=TimelapseDelayTracker.xcodeproj/project.pbxproj
ARCHIVE=build/TimelapseDelayTracker.xcarchive

AUTH=()
KEYFILE=""
cleanup_key() { [ -n "$KEYFILE" ] && rm -f "$KEYFILE"; return 0; }
trap cleanup_key EXIT

if [ "$DRY_RUN" -eq 0 ]; then
  if [ "$CI" -eq 0 ] && [ -f scripts/release.env ]; then
    set -a
    # shellcheck disable=SC1091
    . scripts/release.env
    set +a
  fi
  { set +x; } 2>/dev/null
  if [ "$CI" -eq 1 ] && [ -z "${ASC_KEY_PATH:-}" ]; then
    if [ -z "${ASC_KEY_P8_BASE64:-}" ]; then
      echo "Missing ASC_KEY_P8_BASE64 (or ASC_KEY_PATH)" >&2
      exit 1
    fi
    KEYFILE=$(mktemp)
    chmod 600 "$KEYFILE"
    if ! printf '%s' "$ASC_KEY_P8_BASE64" | base64 -d >"$KEYFILE" 2>/dev/null \
       && ! printf '%s' "$ASC_KEY_P8_BASE64" | base64 -D >"$KEYFILE" 2>/dev/null; then
      echo "ASC_KEY_P8_BASE64 is not valid base64" >&2
      exit 1
    fi
    ASC_KEY_PATH=$KEYFILE
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
  if [ "$CI" -eq 0 ]; then
    if [ -n "$(git status --porcelain)" ]; then
      echo "Working tree is not clean; commit or stash first" >&2
      exit 1
    fi
    if [ "$(git rev-parse --abbrev-ref HEAD)" != develop ]; then
      echo "Not on develop; releases are cut from develop" >&2
      exit 1
    fi
  elif [ "${ALLOW_NON_DEVELOP:-}" != 1 ]; then
    if ! git merge-base --is-ancestor HEAD origin/develop 2>/dev/null; then
      echo "HEAD is not contained in origin/develop (set ALLOW_NON_DEVELOP=1 to override)" >&2
      exit 1
    fi
  fi
  AUTH=(-authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID")
fi

MARKETING=$(xcodebuild -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
  | awk '$1 == "MARKETING_VERSION" { print $3; exit }')
if [ -z "$MARKETING" ]; then
  echo "Could not read MARKETING_VERSION" >&2
  exit 1
fi
if [ "$CI" -eq 1 ] && [ -n "${BUILD_NUMBER:-}" ]; then
  BUILD=$BUILD_NUMBER
else
  if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
    echo "Shallow clone: cannot count commits. Fetch full history (fetch-depth: 0) or set BUILD_NUMBER" >&2
    exit 1
  fi
  BUILD=$(git rev-list --count HEAD)
fi
echo "Release $MARKETING ($BUILD)"
TAG="v$MARKETING-$BUILD"

if [ "$CI" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
  if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
    echo "Tag $TAG already exists on origin" >&2
    exit 1
  fi
fi

EXTRA=()
if [ -n "${CODE_SIGNING_ALLOWED:-}" ]; then
  EXTRA+=("CODE_SIGNING_ALLOWED=$CODE_SIGNING_ALLOWED")
fi

restore() { git checkout -- "$PBXPROJ" 2>/dev/null || true; }

if [ "$DRY_RUN" -eq 0 ] && [ "$CI" -eq 0 ]; then
  trap 'restore; cleanup_key' ERR
  xcrun agvtool new-version -all "$BUILD" >/dev/null
else
  EXTRA+=("CURRENT_PROJECT_VERSION=$BUILD")
fi

rm -rf "$ARCHIVE"
xcodebuild archive -scheme "$SCHEME" -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" -allowProvisioningUpdates ${AUTH[@]+"${AUTH[@]}"} \
  ${EXTRA[@]+"${EXTRA[@]}"}

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
  "${AUTH[@]}"

if [ "$CI" -eq 1 ]; then
  git tag "$TAG"
  git push origin "refs/tags/$TAG"
  echo "Uploaded, tagged and pushed $TAG"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
      echo "tag=$TAG"
      echo "marketing=$MARKETING"
      echo "build=$BUILD"
    } >>"$GITHUB_OUTPUT"
  fi
  exit 0
fi

trap - ERR
git add "$PBXPROJ"
git commit -m "Release $TAG"
git tag "$TAG"
echo "Uploaded and tagged $TAG"
if [ "$PUSH" -eq 1 ]; then
  git push origin develop "$TAG"
else
  echo "Not pushed. Run: git push origin develop $TAG"
fi
