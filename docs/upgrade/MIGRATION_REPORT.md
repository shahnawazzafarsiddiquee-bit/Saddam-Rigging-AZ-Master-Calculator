# Phase 1 migration and preservation report

Baseline application: 9a1965f22c7529bb02d6225900353c5a0b873f1e.
Baseline debug APK: GitHub Actions run 39051201748, successful.
Phase 1 verification run: 39071603307. Static analysis and all six preservation tests passed; Android APK compilation is pending.

## Schema changes
None. All three existing database filenames, version 1 schemas, table names,
columns and existing record IDs are retained. No production device database
was supplied; no claim of a production-device migration is made.

## Backup changes
- The versioned JSON backup includes all 12 tables in all three databases.
- Photo blobs use base64; original inspection/photo IDs are preserved.
- All rows and schema fields are validated before deleting records.
- A restore transaction spans attached database files with rollback journaling.
- Full restore refuses unsupported journal modes before any deletion.
- A full automatic recovery backup is written before an intentional restore.
- Legacy six-table backups restore main only; Pro data is retained.
- JSON output uses a temporary file and rename after a flushed write.

## Limits
External PDFs are referenced by path, not embedded. Keep original PDFs separately.
The settings screen and backup metadata state this limitation.
Actual Android file selection/sharing and in-place device installation still
require runtime verification. Unit tests cannot verify these platform flows.

## Tests prepared
Frozen schema fixtures reproduce all 12 tables from the released commit.
Tests cover all-table round trip, photo bytes/IDs, legacy compatibility,
malformed backups, missing database/table, unknown column, wrong value type,
invalid blob, duplicate IDs, dangling photo references, transaction rollback
after a late insert error and refusal of WAL restoration.
