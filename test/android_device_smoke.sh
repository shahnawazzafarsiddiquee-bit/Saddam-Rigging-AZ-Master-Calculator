#!/usr/bin/env bash
set -Eeuo pipefail
package_id=com.saddam.rigging.azmaster
mkdir -p device-evidence fixtures after-update
capture_failure() {
  echo 'Android verification failed; preserving activity, screenshot and log evidence.' >&2
  adb shell dumpsys activity activities > device-evidence/failure-activities.txt || true
  adb logcat -d > device-evidence/failure-logcat.txt || true
  adb exec-out screencap -p > device-evidence/failure-screen.png || true
}
trap capture_failure ERR
python test/device_fixture.py create fixtures
adb install -r artifacts/baseline/app-debug.apk
adb shell run-as "$package_id" mkdir -p databases
for name in saddam_rigging_master.db rigging_pro.db rigging_pro2.db; do
  adb shell -T "run-as $package_id sh -c 'cat > databases/$name'" < "fixtures/$name"
done
launch_and_capture() {
  local label="$1"
  adb logcat -c
  adb shell monkey -p "$package_id" -c android.intent.category.LAUNCHER 1 > "device-evidence/$label-launch.txt"
  foreground=0
  for attempt in $(seq 1 20); do
    adb shell dumpsys activity activities > "device-evidence/$label-activities.txt"
    if grep -E "(mResumedActivity|topResumedActivity|ResumedActivity).*$package_id" "device-evidence/$label-activities.txt" > /dev/null; then foreground=1; break; fi
    sleep 1
  done
  if [ "$foreground" != 1 ]; then
    cat "device-evidence/$label-activities.txt"
    echo "Application did not become resumed: $label" >&2
    return 1
  fi
  if [ "${VERIFY_VISIBLE_DASHBOARD:-0}" = 1 ]; then
    rendered=0
    for attempt in $(seq 1 20); do
      adb shell uiautomator dump /sdcard/rigsafe-visible-ui.xml > "device-evidence/$label-ui-dump.txt" 2>&1 || true
      adb exec-out cat /sdcard/rigsafe-visible-ui.xml > "device-evidence/$label-ui.xml" 2>/dev/null || true
      if grep -F 'SADDAM RIGGING A-Z' "device-evidence/$label-ui.xml" > /dev/null; then rendered=1; break; fi
      sleep 1
    done
    if [ "$rendered" != 1 ]; then
      echo "Dashboard did not render its visible title: $label" >&2
      return 1
    fi
  else
    sleep 4
  fi
  adb shell pidof "$package_id" > "device-evidence/$label-pid.txt"
  test -s "device-evidence/$label-pid.txt"
  app_pid=$(tr -d '\r\n' < "device-evidence/$label-pid.txt")
  adb logcat -d --pid="$app_pid" > "device-evidence/$label-logcat.txt"
  if grep -E -q 'Unhandled Exception|FATAL EXCEPTION' "device-evidence/$label-logcat.txt"; then
    cat "device-evidence/$label-logcat.txt"
    return 1
  fi
  adb exec-out screencap -p > "device-evidence/$label-dashboard.png"
  if [ "${VERIFY_VISIBLE_DASHBOARD:-0}" = 1 ]; then
    drawn=0
    for attempt in $(seq 1 20); do
      if python test/verify_android_png.py --require-app-header "device-evidence/$label-dashboard.png" > "device-evidence/$label-png-check.txt" 2>&1; then drawn=1; break; fi
      sleep 1
      adb exec-out screencap -p > "device-evidence/$label-dashboard.png"
    done
    if [ "$drawn" != 1 ]; then cat "device-evidence/$label-png-check.txt"; return 1; fi
  fi
  adb shell am force-stop "$package_id"
}
launch_and_capture baseline
adb install -r artifacts/current/app-debug.apk > device-evidence/update-install.txt
launch_and_capture upgraded
for name in saddam_rigging_master.db rigging_pro.db rigging_pro2.db; do
  adb exec-out run-as "$package_id" cat "databases/$name" > "after-update/$name"
done
python test/device_fixture.py compare fixtures after-update | tee device-evidence/data-preservation.txt
signer_path=$(find "$ANDROID_HOME/build-tools" -type f -name apksigner | sort -V | tail -n 1)
test -n "$signer_path"
"$signer_path" verify --verbose --print-certs artifacts/baseline/app-debug.apk > device-evidence/baseline-signature.txt
"$signer_path" verify --verbose --print-certs artifacts/current/app-debug.apk > device-evidence/upgraded-signature.txt
python - <<'PY'
import re
from pathlib import Path
certs=[]
for name in ['baseline','upgraded']:
 text=Path(f'device-evidence/{name}-signature.txt').read_text()
 found=re.findall(r'certificate SHA-256 digest: ([0-9a-fA-F]+)',text)
 if not found:raise ValueError('APK signing identity missing')
 certs.append(found)
if certs[0]!=certs[1]:raise ValueError('APK signing identities changed')
print('PASS: existing APK signing identity preserved.')
PY
# Keep the integration-test APK at the same version code, so Flutter does not
# need to uninstall an app to run the platform tests after the update check.
python - <<'PY'
import os,re
from pathlib import Path
p=Path('pubspec.yaml');s=p.read_text()
s=re.sub(r'(?m)^(version:\s*[^+\n]+)\+\d+',lambda m:m.group(1)+'+'+os.environ['APP_VERSION_CODE'],s)
p.write_text(s)
PY
flutter pub get
if [ "${VERIFY_VISIBLE_DASHBOARD:-0}" = 1 ]; then
  # Official host-side screenshot callback saves PNG bytes before the test app
  # is cleaned up. Never treat a non-empty adb error message as an image.
  flutter drive --driver=test/android_visual_driver.dart --target="$INTEGRATION_TARGET" -d emulator-5554 2>&1 | tee device-evidence/native-backup-tests.txt
  python test/verify_android_png.py device-evidence/verified-dashboard.png device-evidence/verified-equipment.png device-evidence/verified-synthetic.png
  echo 'PASS: all three rendered screenshots were exported as validated PNG images.'
else
  flutter test "${INTEGRATION_TARGET:-integration_test/android_backup_test.dart}" -d emulator-5554 --reporter expanded 2>&1 | tee device-evidence/native-backup-tests.txt
fi
