# 0366: TestFlight workflow

1. `testflight.yml` is `workflow_dispatch` only and fails fast unless run from `refs/heads/develop`.
2. Secrets are used only in the `env:` of the `release.sh --ci` step, in the `testflight` environment.
3. Xcode selection lives in the composite action `.github/actions/setup-xcode`, used by `ci.yml` and `testflight.yml`.
4. Failure artifacts are logs, dSYMs and the test result bundle; never the `.ipa` or key.
