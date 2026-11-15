#!/usr/bin/env bash
set -euo pipefail
PKG="org.tabitabi.nightone"
APK="build/tabi-tabi-night1-debug.apk"
mkdir -p build
adb install -r "$APK"
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 12
# Android shows a one-time immersive-mode "Got it" onboarding dialog on first boot.
# Acknowledge it before recording the actual Godot scene.
adb shell input keyevent 66 || true
adb shell input tap 1700 660 || true
adb shell settings put system accelerometer_rotation 0 || true
adb shell settings put system user_rotation 1 || true
sleep 6
adb shell input tap 1700 660 || true
sleep 3
# The first story dialogue is modal. Close it before tapping the right HUD
# notebook shortcut, otherwise the hidden shortcut cannot be activated.
adb shell input tap 1160 948 || true
sleep 2
adb shell wm size > build/android-display.txt || true
adb exec-out screencap -p > build/android-night1-launch.png || true
# Optional visual QA: tap the right-edge Notebook shortcut on the landscape
# emulator and preserve a second screenshot for overlap/readability review.
adb shell input tap 2050 660 || true
sleep 2
adb exec-out screencap -p > build/android-night1-notebook.png || true
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
