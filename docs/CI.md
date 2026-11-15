# CI

`.github/workflows/ci.yml` runs on pull requests targeting `develop`, pushes to `develop`,
and manually (`workflow_dispatch`). It uses no secrets and has read-only permissions.

- **App Store metadata** (Ubuntu): `scripts/check_metadata.sh`. Cheap; runs on every trigger.
- **Detect code changes** (Ubuntu): skips the test job when the change only touches `docs/**`,
  `*.md` or `AppStore/**/*.txt`. (A workflow-level `paths-ignore` would also skip the metadata
  check, so the filter is done in a job instead.)
- **Tests** (`macos-26`, 30 min limit): selects the newest `Xcode_26*.app`, then runs
  `scripts/test.sh` on a throwaway simulator. On failure `build/test.xcresult` is uploaded
  as an artifact for 7 days. To change the device, set `TDT_DEVICE_TYPE` in the workflow.

A newer push to the same ref cancels the run in progress.

## Cost

The repo is private, so GitHub bills macOS runner minutes at 10x. That is why the macOS job
is skipped for docs-only changes and why superseded runs are cancelled. Nothing is cached.

## TestFlight workflow

`.github/workflows/testflight.yml` is manual only (`workflow_dispatch`, `develop` only). It needs `contents: write` to push the release tag, runs in the `testflight` environment on `macos-26` (45 min limit), and queues rather than cancels (`concurrency: testflight`). Steps: full checkout, Xcode via `.github/actions/setup-xcode` (shared with `ci.yml`), optional `scripts/test.sh` (`run_tests`, default on), `scripts/check_metadata.sh`, then `scripts/release.sh --ci`.

Owner setup:

- GitHub: create environment `testflight` (optionally with a required reviewer) holding secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` (`base64 -i AuthKey_XXXX.p8 | pbcopy`).
- App Store Connect: the API key must be a **Team** key with the **Admin** role (cloud-managed distribution signing).
- Run: Actions tab > TestFlight > Run workflow, branch `develop`.

Secrets appear only in the `env:` of the release step. On failure only logs, dSYMs and the test result bundle are uploaded.
