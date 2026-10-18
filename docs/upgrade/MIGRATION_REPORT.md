# Phase 1 migration and preservation report

Baseline application: 9a1965f22c7529bb02d6225900353c5a0b873f1e.
Baseline debug APK: GitHub Actions run 39051201748, successful.
Phase 1 verification run: 39072237698. Static analysis, 60 preservation/layout tests and debug APK compilation passed.
Phase 2 verification run: 39073629975. Static analysis, 82 tests and debug APK compilation passed.
Native run 39091132004: analysis, 84 tests and APK build passed. Device update failed before restore testing because the original CI artifact and new APK used different generated debug certificates. No native preservation pass is claimed for that run.

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

## Tests and runtime checks
Frozen schema fixtures reproduce all 12 tables from the released commit.
Tests cover all-table round trip, photo bytes/IDs, legacy compatibility,
malformed backups, missing database/table, unknown column, wrong value type,
invalid blob, duplicate IDs, dangling photo references, transaction rollback
after a late insert error, TRUNCATE/PERSIST rollback-journal restoration and refusal of WAL restoration.

The isolated Android job installs the baseline APK, seeds all 12 released tables, updates without uninstalling, compares IDs/values/photo bytes and checks APK signer identity. A separate integration target exercises BackupService with the real Android SQLite and path-provider plugins. These fixtures are not packaged as production user data.


## Signing compatibility — material limitation

The published `latest/saddam-rigging.apk` certificate SHA256 is
`134e40b6363976161bad4c851d0df139ffaf1dce3cb00037e879997dd2db1c9d`.
The repository's existing fixed debug keystore certificate is
`df8356e1e772135b87347f1cb18cf2a6c66c01acba3f8a06ff6e66b646ae76ba`.
The first CI baseline and subsequent debug artifacts also had different
certificates. Copying a key into the default home path did not pin the signing
identity. The upgrade explicitly sets the debug storeFile to the existing key.

An installed published APK signed with the former key cannot be updated by
this different key. Its original private signing key is required. Do not
uninstall the existing application: this may remove its local records.
No signing-key recovery or production-device migration is claimed.

The corrected isolated migration test rebuilds original commit 9a1965f with
only the signing-path fix, then installs its v1 fixtures and updates to the
new build signed by the same fixed key. This verifies data/schema compatibility
and a stable key for future builds; it does not establish compatibility with
the differently signed published APK.
