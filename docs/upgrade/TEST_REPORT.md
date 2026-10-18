# Verification report

## Verified checkpoint

Run 39073629975, commit 1f913aff884350e585415e90b55b30fed7f7e9a0:
static analysis completed, all 82 tests passed and debug APK compilation passed.

The suite covered frozen released database schemas/12-table backup restoration,
legacy preservation, invalid backup rejection, late transaction rollback,
53 screen construction/layout cases, the original theme palette, numerical
calculation boundaries and seven existing calculator form workflows.

Screen construction is not proof that every feature, camera, OCR, QR, file
picker, PDF share, hardware integration or operating-system permission works.
No production device database was supplied.

## Additional verification in progress

- Run 39091132004: 84 tests and APK passed; native update failed due to signing-certificate mismatch and a missing runner utility. Test runner and explicit signing path are being corrected.
- Synthetic sling capacity/source/damage/edge tests and real form interaction.
- The emulator seeds disposable v1 fixtures, installs the baseline APK and
  updates in place; it compares every table/ID/photo blob, checks signer identity,
  captures dashboard screenshots and exercises native restore/rollback.

The published APK uses a different certificate from the fixed repository key.
Its original private signing key is required for a data-preserving update; do
not uninstall the existing app. A rebuilt original-source baseline with the
fixed key checks schema/data compatibility only, not published-APK compatibility.

Only actual completed job evidence will be marked passed. Pending modules and
manual/device requirements are tracked in FEATURE_MATRIX.md. The official PDF
visual regression test cannot run until the original template is supplied.
