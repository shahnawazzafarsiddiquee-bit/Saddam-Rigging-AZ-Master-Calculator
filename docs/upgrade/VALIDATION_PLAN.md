# Upgrade validation gates

No phase is considered complete merely because a screen or class exists.

## Baseline
- Build unchanged application code on the upgrade branch.
- Capture full Actions logs, toolchain, APK artifact and SHA-256.
- Existing test directory is absent: record tests as not present.
- Preserve theme file checksum, application ID and existing signing identity.

## Data preservation
- Round-trip every table across all three databases with deliberately non-sequential IDs.
- Verify photo bytes and inspection-photo references survive exactly.
- Reject malformed JSON, missing tables, unexpected columns, duplicate primary keys, unsupported format versions and invalid blobs before destructive operations.
- Inject insertion failure after rows have been deleted and ensure rollback retains all previous records.
- Keep an automatic recovery backup before intentional restore.
- Legacy six-table backups must not erase either Pro database.
- Test fresh install and existing version-1 schemas separately when migrations are introduced.
- Verify external report PDF content portability; missing referenced files must be reported honestly.

## Calculation engine
- Validate finite inputs, required values, units and domain bounds.
- Exercise horizontal 0/30/45/60/90 degrees and equivalent vertical convention.
- Use independently computed equilibrium examples, conservation of load and round-trip unit conversion checks.
- Test payload plus every rigging component, gross load equal to and over capacity.
- Test two-point CG at each support and outside span; do not claim indeterminate four-point load sharing without engineering assumptions.
- Test radius geometry and field-verification metadata, pressure in kPa and mat area in square metres.
- No approved source, expired source or missing verified configuration means incomplete/review, never automatic lifting approval.

## Workflow and UI
- Preserve existing theme constants and route destinations.
- Reject/quarantine must exclude gear from plan selection without deleting history.
- Approved revisions must be immutable; changes create a new draft revision.
- Verify offline/manual paths for unavailable GPS, weather, BLE and internet.
- Exact PDF template test requires the original supplied PDF and page-by-page rendered comparison.
- Device installation, camera/OCR, QR, BLE, NFC and actual sync require runtime/device checks; unit tests are not substitutes.

## Release
- Run phase tests, static analysis and Android build before marking a phase complete.
- Deliver debug APK with hash; release APK/AAB only with the actual available signing/configuration.
- Keep unconfigured integrations visibly unavailable behind feature flags.
- Distinguish completed, partial, untested and externally blocked items in the final feature matrix.
