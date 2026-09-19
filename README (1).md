# Saddam Rigging A-Z Master Calculator

**Master Lifting Calculator** — a professional, offline-first Flutter app for
rigging engineering, crane planning, lift plan generation, equipment
management, and HSE (Health, Safety & Environment) documentation on
construction and industrial lifting sites.

---

## Features

### 1. Rigging Calculator (8 real engineering calculators)
| Calculator | Formula / Logic |
|---|---|
| Sling Angle | `Leg Load = Load / (Legs × sin(angle))` |
| Load Share | 2/3/4-leg sling load distribution with angle-correction factor |
| WLL Calculator | `WLL = Breaking Load / Safety Factor` for sling / chain / wire rope |
| Shackle Calculator | Required capacity vs. standard bow-shackle sizes |
| Wire Rope Calculator | Approximate breaking strength by construction/grade, `WLL = Breaking Strength / SF` |
| D/d Ratio | `D/d = Sheave Diameter / Rope Diameter`, checked against minimum safe ratio |
| Center of Gravity | Multi-point-load COG (weighted average of X/Y positions) |
| Pad Eye Check | Bearing stress + tensile stress vs. allowable stress |

Every calculator shows a clear **SAFE / NOT SAFE** verdict banner.

### 2. Crane Planning
Built-in representative crane load-chart database (mobile / crawler / all-terrain
cranes) with radius-based capacity interpolation and utilization % check.

### 3. Lift Plan Generator
Full lift-plan form (project, client, load, crane, rigging arrangement,
sequence, personnel, safety requirements) saved to the local database and
exported as a professional PDF, ready to share.

### 4. Equipment Management
Equipment register (wire rope sling, chain sling, web sling, shackle, hook,
spreader beam) with ID, serial number, manufacturer, WLL, inspection/expiry
dates and status — stored in SQLite.

### 5. QR Code System
Generate a QR code for any equipment item and scan it on site to instantly
pull up its details and inspection status — fully offline, no server needed.

### 6. HSE Safety Module
- JSA (Job Safety Analysis) generator with PDF export
- Risk Assessment (`Risk Score = Probability × Severity`) with LOW/MEDIUM/HIGH/EXTREME banding
- Toolbox Talk logging
- Crane & Rigging inspection checklists

### 7. PDF Reports
Every calculation, lift plan, JSA and inspection can be exported to PDF and
shared directly from the device.

### 8. Backup & Restore
Export the entire local database to a single JSON file and restore it later
— useful when switching devices or archiving a project.

---

## Tech Stack
- **Flutter 3.x / Dart 3** — Material 3, dark navy / safety-orange industrial theme
- **sqflite** — local, offline-first SQLite database
- **pdf** + **printing** — PDF generation & sharing
- **qr_flutter** + **mobile_scanner** — QR generation & scanning
- **path_provider**, **file_picker**, **share_plus** — file & backup handling

---

## Project Structure
```
lib/
  main.dart
  app/            theme.dart, routes.dart
  screens/        dashboard, rigging_tools, crane_planning, lift_plan,
                  equipment, hse, reports, settings
  calculators/    sling_angle, load_share, wll, shackle, wire_rope,
                  dd_ratio, cog, pad_eye
  database/       sqlite_helper.dart
  models/         equipment_model, inspection_model, lift_model
  services/       pdf_service, qr_service, backup_service
android/          full Gradle project (application ID: com.saddam.rigging.azmaster)
.github/workflows/build_apk.yml
```

---

## Running Locally (Android Studio / VS Code)

1. Install Flutter 3.24+ and Android Studio with the Android SDK.
2. Open the project folder in Android Studio — it will detect the Flutter
   project and prompt you to create `android/local.properties` automatically
   (or copy `android/local.properties.example` → `android/local.properties`
   and edit the two paths).
3. From the project root:
   ```bash
   flutter pub get
   flutter run
   ```
4. To build a release APK locally:
   ```bash
   flutter build apk --release
   ```
   The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

> **Note on the Gradle wrapper:** to keep this ZIP small and avoid shipping a
> binary `gradle-wrapper.jar`, the wrapper files are generated automatically —
> Android Studio does this the first time you open/sync the project. If you
> ever see a "gradlew not found" error when building manually from a terminal,
> just run (with Gradle installed):
> ```bash
> cd android
> gradle wrapper --gradle-version 8.6
> ```

---

## Building the APK via GitHub Actions (recommended — zero local setup)

1. Push this project to a new GitHub repository.
2. GitHub Actions will automatically run `.github/workflows/build_apk.yml` on
   every push to `main`/`master` (or trigger it manually from the **Actions**
   tab → **Build Android APK** → **Run workflow**).
3. The workflow:
   - Checks out the code
   - Installs JDK 17 and Flutter (stable channel)
   - Generates the Gradle wrapper if it isn't already present
   - Runs `flutter pub get`
   - Runs `flutter analyze` (non-blocking, just for visibility)
   - Builds both split-per-ABI and universal **release** APKs
   - Uploads all APKs as a downloadable build artifact named
     **`saddam-rigging-az-master-calculator-apk`**
4. Once the run finishes (green check), open it and download the artifact
   ZIP under the **Artifacts** section — it contains the installable
   `app-release.apk` (and per-architecture variants).

---

## Signing for Play Store Release

The current `android/app/build.gradle` signs release builds with the Android
**debug key** so the workflow above produces an installable APK immediately.
Before publishing to the Play Store, generate your own upload keystore and
replace the `signingConfigs.debug` reference with your own signing config
(see the official Flutter docs: *Build and release an Android app*).

---

## Data & Privacy
This app is fully **offline-first**: all data (equipment, lift plans, HSE
records, PDFs, backups) is stored locally on the device in SQLite and the
local filesystem. No data is sent to any server.

---

## License
Internal engineering tool — adapt freely for your organization's rigging and
lifting operations.
