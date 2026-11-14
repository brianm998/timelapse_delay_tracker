# 0273: Release script

1. Build number is `git rev-list --count HEAD`, applied with `agvtool new-version -all` (pbxproj gets `VERSIONING_SYSTEM = "apple-generic"`).
2. A real run archives and uploads first; only after success does it commit the bump and tag `v<marketing>-<build>` locally. A trap restores the pbxproj on failure. `--push` pushes develop and the tag.
3. `--dry-run` edits no files, passes the build number on the command line, exports with destination=export, and skips the clean/branch/credential checks.
4. `CODE_SIGNING_ALLOWED` is passed through to the archive when set.
5. Credentials come from the environment or git-ignored `scripts/release.env`; errors name the variable only, values are never printed.
