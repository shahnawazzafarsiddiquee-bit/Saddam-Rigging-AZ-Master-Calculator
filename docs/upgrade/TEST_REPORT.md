# Verified upgrade checkpoint — 18 October 2026

This is an incremental upgrade, not completion of all 113 requested modules.
Application source: 8388a0e6a55f60d242b4b5a3286d5562f173ee6c.
Subsequent commits through 0955e4b9c205ee903663e88e930484916c205bea change tests/workflows only; application source/resources are identical.
Branch: upgrade/rigsafe-super-pro. Draft pull request: #5. Main is unchanged.

## Passed

- Build run 39092858778: static analysis, **102 unit/widget tests**, debug APK, optimized ARM64 APK and test-signed AAB.
- Android API 35 Pixel 6 emulator: in-place install from original-source baseline rebuilt with the same fixed test key; all 12 version-1 tables, original IDs and photo bytes survived.
- Native BackupService integration: real SQLite/path-provider round trip, malformed backup rejection, late transaction failure rollback across all three databases, and recovery snapshots.
- Visual run 39095404794: actual delivered version 1012 APK rendered before/after update; dashboard, equipment and synthetic sling PNGs exported and decoded successfully. Images inspected after download. These use disposable fixtures, not user data.
- Original nine colour constants retained; source assertions and 53 existing-screen construction/layout cases pass. Full pixel regression of every screen is not claimed.
- Downloaded artifact ZIP SHA-256 digests/CRC validated; delivered APK/AAB SHA-256 values match the verified build. Android apksigner verified the debug APK fixed certificate.

## Coverage

Shared-engine checks cover finite/domain boundaries, both sling-angle conventions, zero/low/30/45/60/90-degree cases, missing WLL, capacity equality/overload, CG/load share, gross load/utilization, manufacturer-factor shackle/synthetic capacity, radius/boom geometry, ground pressure/mats, unit conversion and tandem math. UI checks cover edited-input invalidation, synthetic tag/source/damage/edge gates, legacy nullable equipment, invalid expiry/ratings, restricted equipment edits, QR payload parsing and invalid lift weight.

## Failures corrected

Earlier runs exposed phone-width overflow, a snackbar covering Save, generated debug-key mismatch, premature splash screenshots, screenshot export after integration cleanup, and a Pixel Launcher ANR in the emulator. Product layout/validation and signing-path fixes plus deterministic launch, official screenshot driver and PNG verification resolved the applicable checks. No application crash checks were disabled. Latest applicable build, native backup and visual jobs pass.

## Important limits

The published APK certificate differs from this fixed test key. These packages cannot update that installed binary in place. Its original private signing key is required; **do not uninstall the existing app to bypass the mismatch**. The same-key fixture migration test does not establish published-binary update compatibility. No production device/database was tested.

Debug and optimized APK/AAB are test-signed, versionCode 1012, versionName 1.0.0. Optimized APK is ARM64 only. The AAB is not Play-ready. A production build needs proper signing and a versionCode greater than the installed version; the old main workflow counter must be corrected before publishing.

No database migration was needed: all three schemas remain version 1. External PDF paths are backed up, not PDF bytes; keep those documents separately. Android document-picker/share flows, camera/OCR/QR hardware permissions, real BLE/NFC/weather/cloud and every legacy workflow are not end-to-end certified by these tests.

The exact original Critical Lift Plan PDF was not supplied. Overlay/autofill and its exact visual test remain pending. Full role/approval/audit/sync, complete lift wizard, inspection lifecycle, live lift, toolroom, personnel and later modules remain unfinished; see FEATURE_MATRIX.md for all 113 entries. Calculations are decision support and never authorize a lift.

## Phase 4 inspection and lift-equipment gate

Run 39110248646, source 748a0e510b82bd8d4a16bd4578c175c198f3e536: analysis, **110 tests**, debug APK and fixed-key signature verification passed. Eight new tests exercise failure quarantine, incomplete/all-N/A HOLD, PASS preserving quarantine, late cross-database rollback, malformed answers/unknown assets, stale quarantine at lift save, missing/expired certificates, and atomic selected-equipment snapshots. Native device and release-package jobs were not requested in this run.

New inspection metadata has a named offline attestation; it is not an authenticated digital signature. No schema version change. This phase does not complete every inspection/approval/permit requirement.

## Phase 5–7 verified checkpoints

- Phase 5 run 39130127425, source 2897f8bee047a777f52929e92adf3b7b91ab9f49: 117 tests and debug APK passed. Manual/site/drawing/boom radius, field verification and input invalidation covered.
- Phase 6 run 39152985627, source 128b78bb21ca3da39902730e2c54877dbbfbd5b2: 126 tests, debug APK, optimized universal APK, AAB and native same-key update/backup passed; versionCode 1019. Wind source/freshness/limits, frozen attachments and missing/stale/project-mismatch checks covered.
- Phase 7 run 39182175553, source 2c9450e903596363281b35a2ba369c9542d7bef7: **136 tests**, debug APK, optimized universal APK, AAB and native same-key update/backup passed; versionCode 1021. Ground boundaries, missing data, source/estimate status, pad geometry, mat quantity, no double-counted reference mass, immutable records, multipage PDF and phone form covered.
- Phase 7's earlier phone test was corrected to unfocus the keyboard and use a real phone viewport before tapping Calculate; the rerun passed. No production calculation assertion was disabled.

These package milestones supersede the older ARM64-only 1012 package note above. Analyzer warnings/information remain non-fatal; no claim of warning-free lint or complete physical-device certification is made.

## Phase 8 gate in progress

Source feeb55ac5ab64d2ddf580913f61954a1e50ed981; run 39564123210. Tests cover exact chart rows, all path radii, source metadata, asset/config matching, old chart archive and transaction rollback, missing weights and typed crane input. Current gate result must be recorded before declaring these tests or packages passed.
