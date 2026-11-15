# 0369: App Store submit workflow

1. `app-store.yml` is `workflow_dispatch` only, develop only, in environment `app-store` (owner adds a required reviewer).
2. Uses fastlane deliver with `skip_binary_upload`, `automatic_release: false`, `force: true`, precheck before submit; `submit` defaults to false.
3. URL placeholder check lives in `scripts/check_store_urls.sh`, not `check_metadata.sh`, so CI and TestFlight stay green while the URLs are placeholders.
4. Screenshots are staged into a temp `en-US` dir; checked-in files are not moved.
5. Runs on ubuntu-latest (unverified; fallback macos-26). Gemfile.lock is not committed: bundler could not run here.
