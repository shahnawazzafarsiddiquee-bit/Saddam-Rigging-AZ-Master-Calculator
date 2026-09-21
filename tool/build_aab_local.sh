#!/usr/bin/env bash
# Build a Play Store ready, signed app-release.aab on any Linux machine
# (a GitHub Codespace works well) without needing CI secrets.
#
# It installs Flutter, the Android SDK and a JDK 17 into your home directory,
# creates an upload keystore if you don't already have one, and signs the
# bundle with it.
#
#   curl -fsSL -o build_aab.sh https://raw.githubusercontent.com/shahnawazzafarsiddiquee-bit/Saddam-Rigging-AZ-Master-Calculator/refs/heads/claude/github-file-creation-fnow0w/tool/build_aab_local.sh
#   bash build_aab.sh
#
# Keep upload-keystore.jks and KEYSTORE-PASSWORD.txt somewhere safe afterwards:
# Play Store updates must be signed with the same key. Never commit them.

set -euo pipefail

SIGNING_BRANCH="claude/github-file-creation-fnow0w"
FLUTTER_VERSION="3.47.5"
CMDLINE_TOOLS="commandlinetools-linux-11076708_latest.zip"

REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_DIR"
echo "Working in: $REPO_DIR"

if ! grep -q 'key.properties' android/app/build.gradle 2>/dev/null; then
  if [ -n "$(git status --porcelain --untracked-files=no 2>/dev/null)" ]; then
    echo "ERROR: uncommitted changes to tracked files; commit or stash them so the"
    echo "       branch with the release-signing config can be checked out."
    exit 1
  fi
  echo ""
  echo "==> Switching to $SIGNING_BRANCH (it carries the release-signing config)"
  git fetch origin "$SIGNING_BRANCH"
  git checkout -B "$SIGNING_BRANCH" FETCH_HEAD
fi

mkdir -p .git/info
for f in upload-keystore.jks KEYSTORE-PASSWORD.txt app-release.aab android/key.properties android/local.properties; do
  grep -qxF "$f" .git/info/exclude 2>/dev/null || echo "$f" >> .git/info/exclude
done

if [ -f upload-keystore.jks ] && [ -f KEYSTORE-PASSWORD.txt ]; then
  echo ""
  echo "==> Reusing the upload keystore already in this folder"
else
  echo ""
  echo "==> Creating a new upload keystore"
  rm -f upload-keystore.jks KEYSTORE-PASSWORD.txt
  KS_PASS="$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-20)"
  keytool -genkeypair -v -keystore upload-keystore.jks -alias upload \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$KS_PASS" -keypass "$KS_PASS" \
    -dname "CN=Saddam Rigging AZ Master Calculator, OU=Engineering, O=Saddam Rigging, C=IN" >/dev/null 2>&1
  printf 'KEYSTORE_PASSWORD=%s\nKEY_PASSWORD=%s\nKEY_ALIAS=upload\n' "$KS_PASS" "$KS_PASS" > KEYSTORE-PASSWORD.txt
fi

# Gradle 8.14 (android/gradle/wrapper/gradle-wrapper.properties) cannot run on
# newer JDKs - a Java 25 default produces "Unsupported class file major version
# 69". CI pins JDK 17, so do the same here.
echo ""
echo "==> Locating a JDK 17"
find_jdk17() {
  local d
  for d in "$HOME"/jdk17 /usr/lib/jvm/*17* /usr/local/sdkman/candidates/java/*17* /opt/java/*17*; do
    if [ -x "$d/bin/javac" ]; then echo "$d"; return 0; fi
  done
  return 1
}

JDK17="$(find_jdk17 || true)"

if [ -z "$JDK17" ] && command -v apt-get >/dev/null 2>&1; then
  echo "    not installed - trying apt"
  sudo apt-get update -qq >/dev/null 2>&1 || true
  sudo apt-get install -y -qq openjdk-17-jdk-headless >/dev/null 2>&1 || true
  JDK17="$(find_jdk17 || true)"
fi

if [ -z "$JDK17" ]; then
  echo "    not installed - downloading Temurin 17"
  mkdir -p "$HOME/jdk17"
  curl -fsSL -o /tmp/jdk17.tar.gz \
    "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse"
  tar xzf /tmp/jdk17.tar.gz -C "$HOME/jdk17" --strip-components=1
  rm -f /tmp/jdk17.tar.gz
  JDK17="$HOME/jdk17"
fi

echo "    using $JDK17"
export JAVA_HOME="$JDK17"
export PATH="$JAVA_HOME/bin:$PATH"
java -version 2>&1 | head -1

echo ""
echo "==> Installing Flutter $FLUTTER_VERSION (a few minutes the first time)"
export FLUTTER_HOME="$HOME/flutter"
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  curl -fsSL -o /tmp/flutter.tar.xz \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar xf /tmp/flutter.tar.xz -C "$HOME"
  rm -f /tmp/flutter.tar.xz
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_HOME" 2>/dev/null || true
flutter config --jdk-dir="$JDK17" >/dev/null
flutter --version

echo ""
echo "==> Installing the Android SDK (a few minutes the first time)"
export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  curl -fsSL -o /tmp/cmdtools.zip "https://dl.google.com/android/repository/$CMDLINE_TOOLS"
  unzip -q /tmp/cmdtools.zip -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -f /tmp/cmdtools.zip
fi
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager "platform-tools" "platforms;android-36" "platforms;android-35" "build-tools;36.0.0" >/dev/null

# The project's gradle.properties asks for -Xmx4G plus a 2G metaspace, which
# on top of the Kotlin daemon and the editor server gets the Gradle daemon
# OOM-killed on a small machine ("Gradle build daemon disappeared
# unexpectedly"). Machine-specific limits belong in GRADLE_USER_HOME, which
# takes precedence over the project file and leaves CI untouched.
echo ""
TOTAL_MB="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 8192)"
HEAP_MB=$(( TOTAL_MB * 40 / 100 ))
[ "$HEAP_MB" -lt 2048 ] && HEAP_MB=2048
[ "$HEAP_MB" -gt 4096 ] && HEAP_MB=4096
echo "==> Machine has ${TOTAL_MB} MB RAM and $(nproc) CPUs - capping Gradle at ${HEAP_MB} MB"
mkdir -p "$HOME/.gradle"
cat > "$HOME/.gradle/gradle.properties" <<PROPS
org.gradle.jvmargs=-Xmx${HEAP_MB}m -XX:MaxMetaspaceSize=512m
org.gradle.parallel=false
org.gradle.workers.max=1
org.gradle.caching=false
kotlin.compiler.execution.strategy=in-process
kotlin.incremental=false
PROPS

echo ""
echo "==> Writing local.properties and key.properties"
printf 'sdk.dir=%s\nflutter.sdk=%s\n' "$ANDROID_HOME" "$FLUTTER_HOME" > android/local.properties
# shellcheck source=/dev/null
source ./KEYSTORE-PASSWORD.txt
printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=%s\nstoreFile=%s\n' \
  "$KEYSTORE_PASSWORD" "$KEY_PASSWORD" "$KEY_ALIAS" "$REPO_DIR/upload-keystore.jks" \
  > android/key.properties

# A daemon started under the old JDK would keep failing.
(cd android && ./gradlew --stop >/dev/null 2>&1) || true

echo ""
echo "==> flutter pub get"
flutter pub get

echo ""
echo "==> Building the app bundle (the long step)"
flutter build appbundle --release

AAB="$REPO_DIR/build/app/outputs/bundle/release/app-release.aab"
if [ ! -f "$AAB" ]; then
  echo "Build finished but $AAB is missing. Check the output above."
  exit 1
fi
cp -f "$AAB" "$REPO_DIR/app-release.aab"

echo ""
echo "=================================================="
echo "  SUCCESS - Play Store bundle ready"
echo "=================================================="
ls -lh "$REPO_DIR/app-release.aab"
keytool -printcert -jarfile "$REPO_DIR/app-release.aab" 2>/dev/null | grep -E "Owner:|Valid " | head -2 || true
echo ""
echo "  Download these 3 files before deleting this machine:"
echo "      app-release.aab        <- upload to Play Console"
echo "      upload-keystore.jks    <- required for every future update"
echo "      KEYSTORE-PASSWORD.txt"
echo ""
