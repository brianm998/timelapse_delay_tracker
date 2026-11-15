# 0360: Release script CI mode

1. `scripts/release.sh --ci` is for GitHub Actions. Without it, behaviour is as in 0273, plus the API key auth flags on archive and export when credentials are set.
2. The key comes from `ASC_KEY_P8_BASE64`, decoded to a mode-600 `mktemp` file removed by an EXIT trap (`ASC_KEY_PATH` still works). Errors name variables only.
3. The build number is `BUILD_NUMBER` or the commit count, passed as `CURRENT_PROJECT_VERSION`; no agvtool, no commit. Shallow clones fail with a clear message.
4. Clean-tree and on-develop checks are replaced by requiring `HEAD` in `origin/develop` (`ALLOW_NON_DEVELOP=1` overrides). An existing tag on origin fails the run before archiving.
5. After upload only the tag is pushed, never `develop`. `tag`, `marketing` and `build` go to `$GITHUB_OUTPUT`.
