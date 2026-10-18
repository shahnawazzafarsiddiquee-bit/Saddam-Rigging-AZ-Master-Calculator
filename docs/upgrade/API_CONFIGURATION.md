# API and device configuration

No weather, cloud-auth, AI, BLE-anemometer or NFC provider is configured in the
current checkpoint. These integrations must not be represented as operational.
Existing calculators and local SQLite workflows do not require API credentials.

## Future integration requirements

- Weather: choose the company-approved provider and freshness policy; show the
  timestamp, location, source, wind and gust. Manufacturer/project wind limits
  must be entered with their source; no universal crane limit is supplied.
- BLE: obtain the actual anemometer model, GATT service/characteristics and
  device protocol before writing a decoder. Manual readings remain required.
- Cloud: select the authorized backend and project/company tenancy model;
  enforce roles server-side and keep a revision-aware offline repository.
- AI/OCR: require confirmation of extracted values and competent-person review.
  OCR/AI may never issue lifting authorization.
- API secrets: keep privileged provider credentials in a backend/CI secret
  store. Do not embed private API keys in Dart source, assets or an APK.

The upgrade workflow uses only the built-in short-lived GitHub token with
contents/actions read permissions. It does not publish to Play or change
production release assets. Existing fixed debug signing is for sideload tests;
a Play release needs the owner's private upload signing configuration.

## Release compatibility gate

Delivered checkpoint packages use versionCode 1012 and the repository test key. Before production publishing, use the correct original/private release signing key and a monotonically higher versionCode. The main workflow's old run-number counter is not sufficient after installing 1012. No production publishing is performed by this checkpoint.
