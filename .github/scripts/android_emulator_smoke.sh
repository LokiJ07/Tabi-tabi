#!/usr/bin/env bash
set -euo pipefail

PKG="org.tabitabi.nightone"
APK="build/tabi-tabi-night1-debug.apk"
mkdir -p build
adb install -r "$APK"
adb logcat -c
adb shell settings put system accelerometer_rotation 0 || true
adb shell settings put system user_rotation 1 || true
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
sleep 13

# Software-rendered AVDs may hang Pixel Launcher or show immersive onboarding.
# Do not send ordinary menu clicks: earlier smoke tests landed in SETTINGS and
# falsely counted that textured popup as visible "gameplay".
dismiss_system_anr() {
  # Never tap fixed screen coordinates to dismiss launcher ANRs:
  # (780, 555) was the game's SETTINGS button on the test device.
  # Also do not press BACK blindly: Android might exit the game.
  adb shell am force-stop com.google.android.apps.nexuslauncher >/dev/null 2>&1 || true
}
dismiss_system_anr
sleep 2
adb exec-out screencap -p > build/android-night1-title.png

# Debug APK only: trigger the QA triple tap at the upper-right corner. This is
# NOT the Start/Settings control, so no device-dependent hitbox assumptions.
# Verify the exact message printed by the REAL gameplay scene after _ready().
scene_ready=0
for attempt in 1 2 3; do
  adb shell input tap 2230 85
  adb shell input tap 2230 85
  adb shell input tap 2230 85
  sleep 8
  if adb logcat -d -v brief | grep -q "NIGHT1_QA_GAMEPLAY_SCENE_READY"; then
    scene_ready=1
    break
  fi
  echo "Game scene not ready on attempt $attempt; clearing system dialog"
  dismiss_system_anr
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 || true
  sleep 4
done
if [ "$scene_ready" -ne 1 ]; then
  echo "ERROR: real Night 1 gameplay scene never opened; title/settings is not gameplay"
  adb logcat -d | grep -E 'NIGHT1_QA|Godot|AndroidRuntime' | tail -n 90 || true
  exit 1
fi

# The starting Lola prologue is a real gameplay scene even if the dialogue
# overlay is initially visible. Close dialogue (never press title SETTINGS).
adb shell input keyevent 4 || true
sleep 2
adb exec-out screencap -p > build/android-night1-launch.png
adb shell wm size > build/android-display.txt || true
adb logcat -d -v brief | grep -Ei 'Godot|EGL|OpenGL|Vulkan|swiftshader|Renderer|SceneShaderGLES3|NIGHT1_QA' | tail -n 300 > build/android-godot-renderer-log.txt || true

# Game must BOTH be in the actual scene and have a visibly varied playfield.
python3 .github/scripts/assert_gameplay_visible.py build/android-night1-launch.png
if ! adb shell pidof "$PKG"; then
  echo "ERROR: Android game process is not alive after real scene launch"
  exit 1
fi

# These are supplemental captures, not gameplay acceptance tests.
adb shell input tap 2050 660 || true
sleep 2
adb exec-out screencap -p > build/android-night1-notebook.png || true
adb shell input swipe 1390 775 1390 360 450 || true
sleep 1
adb exec-out screencap -p > build/android-night1-notebook-scrolled.png || true
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

adb logcat -d -s AndroidRuntime:E Godot:E GodotEngine:E > build/android-night1-launch-log.txt || true
if grep -q "FATAL EXCEPTION" build/android-night1-launch-log.txt; then
  cat build/android-night1-launch-log.txt
  exit 1
fi
echo "PASS: real Night 1 gameplay scene visible and Android game process alive"
