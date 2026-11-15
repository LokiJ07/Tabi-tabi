#!/usr/bin/env bash
set -euo pipefail
PKG="org.tabitabi.nightone"
APK="build/tabi-tabi-night1-debug.apk"
mkdir -p build
adb install -r "$APK"
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 16
adb exec-out screencap -p > build/android-night1-launch.png || true
adb logcat -d -s AndroidRuntime:E Godot:E GodotEngine:E > build/android-night1-launch-log.txt || true
if ! adb shell pidof "$PKG"; then
  echo "ERROR: Android game process is not alive after launch"
  cat build/android-night1-launch-log.txt
  exit 1
fi
if grep -q "FATAL EXCEPTION" build/android-night1-launch-log.txt; then
  echo "ERROR: Android fatal exception during launch"
  cat build/android-night1-launch-log.txt
  exit 1
fi
echo "PASS: Night 1 QA APK launched and remained alive on Android emulator"
