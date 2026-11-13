## Filing work for the pipeline

If you file a task that already contains the plan (the files to change, the
approach and the acceptance criteria), mark it explored so the pipeline skips
its exploring step: pass `explored: true` to `file_proposal`, or `--explored` to
`mason task add`, or put `explored: true` in the task's front matter. Only do
this when the task body really is the plan. Run `mason help filing` for details.

## Building and testing

- Tests: `scripts/test.sh` (creates and deletes its own simulator; the MASON suite runs the same).
- **No XCUITests, ever.** Nothing automated may appear on this Mac's screen, and MASON's
  xcodebuild shim refuses UI test runs. For UI checks, host the view in an offscreen
  `UIWindow` inside the unit-test bundle and render it, as `ContentViewSmokeTests` does.
- No timing assertions in tests.
- `project.pbxproj` is hand-maintained (no XcodeGen). Keep edits small, in the existing ID
  style, and check them with `plutil -lint` and `xcodebuild -list`.
- Never commit, print or ask for signing keys, App Store Connect API keys or passwords. Uploads
  to App Store Connect are the owner's.
