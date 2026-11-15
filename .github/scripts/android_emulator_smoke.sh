#!/usr/bin/env bash
set -euo pipefail
PKG="org.tabitabi.nightone"
APK="build/tabi-tabi-night1-debug.apk"
mkdir -p build
# Pixel Launcher can ANR under CPU-only SwiftShader even while Godot is healthy.
# The Android system dialog is NOT a game renderer failure. Clear it before
# taking captures; never waive the actual screenshot acceptance check.
dismiss_launcher_anr() {
  adb shell am force-stop com.google.android.apps.nexuslauncher >/dev/null 2>&1 || true
  # Android 35 "Close app" row (outside any title/menu button on our landscape UI).
  adb shell input tap 780 555 >/dev/null 2>&1 || true
}
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
dismiss_launcher_anr
sleep 2
# The Android app now opens a functional title scene instead of auto-starting.
# Capture it separately, then enter the actual playable chapter.
adb exec-out screencap -p > build/android-night1-title.png || true
adb shell input tap 540 370 || true
sleep 7
dismiss_launcher_anr
# A second tap is safe in gameplay, but starts the chapter if Launcher ANR
# swallowed the first Start Game tap on the title screen.
adb shell input tap 540 370 || true
sleep 4
# The first story dialogue is modal. Close it before tapping the right HUD
# notebook shortcut, otherwise the hidden shortcut cannot be activated.
adb shell input tap 1160 948 || true
sleep 2
adb shell wm size > build/android-display.txt || true
# Visual acceptance checks actual pixels, not only "process alive".
# Retry system popups/blocked tap, but do NOT suppress persistent cyan worlds.
visible=0
for attempt in 1 2 3; do
  adb exec-out screencap -p > build/android-night1-launch.png
  adb logcat -d -v brief | grep -Ei 'Godot|EGL|OpenGL|Vulkan|swiftshader|Renderer|SceneShaderGLES3' | tail -n 300 > build/android-godot-renderer-log.txt || true
  if python3 .github/scripts/assert_gameplay_visible.py build/android-night1-launch.png; then
    visible=1
    break
  fi
  if [ "$attempt" -eq 3 ]; then
    echo "ERROR: Actual playable world still not visible after retries"
    exit 1
  fi
  echo "Visual check failed on attempt $attempt; dismissing possible Android Launcher ANR and retrying"
  dismiss_launcher_anr
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 || true
  sleep 4
  adb shell input tap 540 370 || true
  sleep 7
  adb shell input tap 1160 948 || true
  sleep 3
done
test "$visible" -eq 1
# Optional visual QA: tap the right-edge Notebook shortcut on the landscape
# emulator and preserve a second screenshot for overlap/readability review.
adb shell input tap 2050 660 || true
sleep 2
adb exec-out screencap -p > build/android-night1-notebook.png || true
# Inspect scrolling and the bottom of the Notebook as rendered by Android.
adb shell input swipe 1390 775 1390 360 450 || true
sleep 1
adb exec-out screencap -p > build/android-night1-notebook-scrolled.png || true
# Fixed-footer Close Notebook; then capture the actual Preparation and Options UIs.
adb shell input tap 1160 965 || true
sleep 1
adb shell input tap 1900 460 || true
sleep 2
adb exec-out screencap -p > build/android-night1-preparation.png || true
adb shell input tap 1160 965 || true
sleep 1
adb shell input tap 1940 60 || true
sleep 2
adb exec-out screencap -p > build/android-night1-options.png || true
# Gather rendering warnings as well as fatal errors; silent GL failures may not crash.
adb logcat -d -v brief | grep -Ei 'Godot|EGL|OpenGL|Vulkan|swiftshader|Renderer' | tail -n 250 > build/android-godot-renderer-log.txt || true
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
