#!/usr/bin/env bash
# Android emulator runner's script field executes commands individually.
# Always invoke THIS script as a single bash command, so Python heredocs,
# shell conditionals, pipes and redirections execute in the same shell.
set -euo pipefail
: "${GAME_VERSION:?GAME_VERSION is required}"
mkdir -p build
apk="build/Tabi-tabi-v${GAME_VERSION}.apk"
test -s "$apk"
adb install -r "$apk"
adb logcat -c
adb shell monkey -p org.tabitabi.nightone -c android.intent.category.LAUNCHER 1
sleep 18
adb shell pidof org.tabitabi.nightone
adb exec-out screencap -p > build/android-signed-release-title.png
test -s build/android-signed-release-title.png
python3 - <<'PY'
import struct
from pathlib import Path
path = Path("build/android-signed-release-title.png")
data = path.read_bytes()
assert data[:8] == b"\x89PNG\r\n\x1a\n", "Android emulator screenshot isn't a PNG"
width, height = struct.unpack(">II", data[16:24])
assert width >= 700 and height >= 400, (width, height)
assert len(data) >= 30000, "Android screenshot too small to be a plausible real render"
print("PASS: signed-release emulator screenshot", width, height, len(data))
PY
adb logcat -d -v brief > build/android-signed-release-logcat.txt
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR:|ERROR: Failed to load script' build/android-signed-release-logcat.txt; then
  echo "::error::Release APK native crash or game script failure"
  exit 1
fi
echo "PASS: Production-signed Android RELEASE APK installed, launched and rendered title"
