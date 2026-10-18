# Changelog

## Unreleased — upgrade/rigsafe-super-pro

### Preserved
- Existing app identity, original palette and navigation routes.
- All three version-1 SQLite schemas and original record identifiers.
- Existing calculation, inspection, QR, OCR and report screens.

### Upgraded
- Full 12-table backup including photo blobs, pre-restore recovery snapshots,
  legacy backup compatibility, validation and transaction rollback.
- Dedicated calculation engine with input validation, canonical units, method,
  assumptions, source and incomplete-data gates.
- Sling angle conventions including 90 degrees; XYZ CG; gross hook load;
  representative crane chart boundaries; ground/mat calculations and units.
- Removed universal wind thresholds from upgraded calculation/summary flows.
- Existing synthetic sling screen now uses actual tag and manufacturer assembly
  factor inputs, explicit verification and separate body/inspection-period colours.
  Generic material/chemical guidance no longer declares compatibility.
- Fixed wire-rope dropdown and shared result-row phone-width overflows.

### Verification
- Phase 2 checkpoint: static analysis, 82 tests and debug APK passed.
- Further journal-mode, native Android update/backup and synthetic workflow
  tests are being verified; consult TEST_REPORT.md for current evidence.
- No schema migration, production-device data deletion or main-branch merge.
