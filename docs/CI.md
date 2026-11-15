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
