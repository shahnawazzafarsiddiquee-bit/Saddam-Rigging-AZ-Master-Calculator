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

- Legacy nullable equipment, duplicate IDs, invalid WLL/expiry and restricted-state edits are guarded.
- Invalid lift weight is rejected inline before save/PDF; QR empty payloads and repeated scan callbacks are guarded.
- Explicit fixed debug keystore path stabilizes future test builds; it cannot replace the original published signing key.

### Verification
- Build run 39092858778: analysis, 102 tests, debug/ARM64 APK and AAB passed.
- Native 12-table same-key update and real SQLite restore/rollback passed.
- Visual run 39095404794: rendered dashboard/equipment/synthetic screenshots passed.
- No schema migration, production-device data deletion or main-branch merge.
- Full enterprise scope remains pending; see docs/upgrade/FEATURE_MATRIX.md.
