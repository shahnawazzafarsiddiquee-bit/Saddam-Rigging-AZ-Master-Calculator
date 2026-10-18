#!/usr/bin/env bash
set -euo pipefail
package_id=com.saddam.rigging.azmaster
mkdir -p device-evidence fixtures after-update
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
    if adb shell dumpsys activity activities | grep -E "mResumedActivity.*$package_id" > /dev/null; then foreground=1; break; fi
    sleep 1
  done
  test "$foreground" = 1
  sleep 4
  adb shell pidof "$package_id" > "device-evidence/$label-pid.txt"
  test -s "device-evidence/$label-pid.txt"
  app_pid=$(tr -d '\r\n' < "device-evidence/$label-pid.txt")
  adb logcat -d --pid="$app_pid" > "device-evidence/$label-logcat.txt"
  if grep -E -q 'Unhandled Exception|FATAL EXCEPTION' "device-evidence/$label-logcat.txt"; then
    cat "device-evidence/$label-logcat.txt"
    return 1
  fi
  adb exec-out screencap -p > "device-evidence/$label-dashboard.png"
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
flutter test integration_test/android_backup_test.dart -d emulator-5554 --reporter expanded 2>&1 | tee device-evidence/native-backup-tests.txt
