# Releasing to TestFlight / App Store

The owner runs these steps. Agents never handle signing keys or App Store Connect credentials.

## One-time setup

1. Register the App ID (bundle ID) `com.brianmartin.TimelapseDelayTracker` under team `G3L75S65V9` (developer.apple.com > Identifiers).
2. Create the app record in App Store Connect (My Apps > +) using that bundle ID.
3. Create an App Store Connect API key (Users and Access > Integrations) with the **App Manager** role. Download the `.p8` once and save it outside the repo (e.g. `~/.private/AuthKey_XXXX.p8`). Note the Key ID and Issuer ID.
4. Create `scripts/release.env` (git-ignored) containing:
   ```
   ASC_KEY_PATH=/absolute/path/to/AuthKey_XXXX.p8
   ASC_KEY_ID=XXXXXXXXXX
   ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```
   Or export the same three variables in your shell.
5. Host the privacy policy (`AppStore/PRIVACY.md`) at a public URL and put it in `AppStore/metadata/en-US/privacy_url.txt`.
6. Fill in App Privacy in App Store Connect from `AppStore/app_privacy.md`.
7. Set the age rating (4+) from the same file.
8. Paste the listing metadata from `AppStore/metadata/en-US/*` and the review notes from `AppStore/review_notes.txt`.
9. Make screenshots (none are checked in) and upload them.

## Each release

1. Make sure `develop` is clean and current.
2. Run `scripts/check_metadata.sh` and `scripts/test.sh`.
3. Optional: `scripts/release.sh --dry-run` archives and exports to `build/export` without uploading.
4. Run `scripts/release.sh` (or `scripts/release.sh --push` to also push `develop` and the tag). It sets the build number to the commit count, archives, uploads, then commits the bump and tags `v<marketing>-<build>` locally. `MARKETING_VERSION` is changed by hand in the Xcode project.
5. Wait for App Store Connect to finish processing the build.
6. In App Store Connect, select the build and submit for review.
7. If you did not use `--push`: `git push origin develop v<marketing>-<build>`.
