# 0359: GitHub Actions CI

1. Docs-only filtering is done by a Linux `changes` job, not workflow-level `paths-ignore`, so the metadata check still runs when metadata changes.
2. `scripts/test.sh` is used unchanged; the workflow can set `TDT_DEVICE_TYPE` if the image lacks iPhone 17.
3. The workflow could not be run from the pipeline; the first real run happens on push.
