#!/usr/bin/env bash
set -euo pipefail

PKG="org.tabitabi.nightone"
APK="build/tabi-tabi-night1-debug.apk"
mkdir -p build
adb install -r "$APK"
# Android's immersive-mode first-run warning is a SYSTEM overlay. On a fresh
# emulator it blocks every tap on the Night 1 dialogue and persisted even
# after the previous fixed-coordinate "Got it" tap. Confirm immersive mode
# through Android's secure settings before starting the game activity.
adb shell settings put secure immersive_mode_confirmations confirmed || true
adb logcat -c
# Some fresh Android 35 AVDs ignore the first rotation request because the
# launcher is still foreground during first-run Godot activity startup.
# Retry the actual game activity and the window manager's user-rotation lock;
# never spoof screenshot dimensions or treat the Android home screen as a game.
landscape_ready=0
for attempt in 1 2 3; do
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
  sleep 8
  adb shell settings put system accelerometer_rotation 0 || true
  adb shell settings put system user_rotation 1 || true
  adb shell wm user-rotation lock 1 || true
  sleep 4
  adb exec-out screencap -p > build/android-orientation.png
  if python3 -c 'import struct,sys; d=open(sys.argv[1],"rb").read(24); w,h=struct.unpack(">II",d[16:24]); print("Android screenshot resolution: %sx%s"%(w,h)); sys.exit(0 if w>h else 1)' build/android-orientation.png; then
    landscape_ready=1
    break
  fi
  echo "Landscape activity not ready (attempt $attempt); relaunching game"
  adb shell am force-stop "$PKG" || true
done
if [ "$landscape_ready" -ne 1 ]; then
  echo "ERROR: Android game activity failed landscape after real launch retries"
  adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' | head -n 10 || true
  adb logcat -d | grep -E 'NIGHT1_QA|ActivityTaskManager|Godot|AndroidRuntime' | tail -n 100 || true
  exit 1
fi

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
# Godot may still be importing its first-run SVG cache on SwiftShader even
# after Android has switched into landscape. The prior CI snapshot captured
# the genuine Godot splash screen, then prematurely failed after two seconds.
# Wait for the exact in-engine title log, not an arbitrary time or screenshot.
title_ready=0
for attempt in $(seq 1 20); do
  if adb logcat -d -v brief | grep -q "NIGHT1_QA_TITLE_SCENE_READY"; then
    title_ready=1
    break
  fi
  sleep 3
done
adb exec-out screencap -p > build/android-night1-title.png

# Never count Godot's splash logo or system launcher as the real title.
if [ "$title_ready" -ne 1 ]; then
  echo "ERROR: Godot title screen did not start"
  adb logcat -d | grep -E 'Godot|AndroidRuntime|NIGHT1_QA' | tail -n 70 || true
  exit 1
fi

# The real START GAME button occupies this location on our 2340x1080 landscape
# emulator. The previous fixed (780, 555) recovery tap opened SETTINGS instead.
adb shell input tap 520 370
sleep 7
scene_ready=0
if adb logcat -d -v brief | grep -q "NIGHT1_QA_GAMEPLAY_SCENE_READY"; then
  scene_ready=1
fi
# Backup: the debug triple-corner gesture avoids menu coordinate dependence.
if [ "$scene_ready" -ne 1 ]; then
  echo "START GAME button did not open scene; invoking debug-only QA entry"
  for attempt in 1 2; do
    adb shell input tap 2230 85
    adb shell input tap 2230 85
    adb shell input tap 2230 85
    sleep 6
    if adb logcat -d -v brief | grep -q "NIGHT1_QA_GAMEPLAY_SCENE_READY"; then
      scene_ready=1
      break
    fi
    echo "Gameplay not ready; retrying title launch ($attempt)"
    dismiss_system_anr
    adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 || true
    sleep 4
  done
fi
if [ "$scene_ready" -ne 1 ]; then
  echo "ERROR: real Night 1 gameplay scene never opened; title/settings is not gameplay"
  adb logcat -d | grep -E 'NIGHT1_QA|Godot|AndroidRuntime' | tail -n 90 || true
  exit 1
fi

# Android 35 displays a one-time immersive onboarding sheet on the first
# landscape launch. The actual "Got it" button is at (1690,520) on the
# 2340x1080 emulator, NOT at the old (1700,660) coordinate. That old tap
# left a white SYSTEM popup over the correctly-rendering Lola dialogue.
adb shell input tap 1690 520 || true
sleep 2
# Use ONLY the in-game dialogue footer to advance Lola's prologue.
# Android's physical BACK key exited Godot to the launcher, so the old visual
# checker captured the phone home screen rather than the playable world.
for i in 1 2 3; do
  adb shell input tap 1160 956 || true
  sleep 1
done
# Assert the game is still foreground before any screenshot acceptance.
# On emulators where dumpsys text formats differ, the pixel check below
# remains the mandatory visual gate.
adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' | tail -n 4 > build/android-foreground.txt || true
adb exec-out screencap -p > build/android-night1-launch.png
adb shell wm size > build/android-display.txt || true
adb logcat -d -v brief | grep -Ei 'Godot|EGL|OpenGL|Vulkan|swiftshader|Renderer|SceneShaderGLES3|NIGHT1_QA' | tail -n 300 > build/android-godot-renderer-log.txt || true

# Game must BOTH be in the actual scene and have a visibly varied playfield.
# The Lola prologue can span multiple pages. A retry is permitted only after
# dismissing a known Android onboarding sheet or advancing that dialogue.
# Persistent solid/blank gameplay remains a hard failure.
visible=0
for attempt in 1 2 3 4; do
  if python3 .github/scripts/assert_gameplay_visible.py build/android-night1-launch.png; then
    visible=1
    break
  fi
  echo "Visual check blocked on attempt $attempt; advancing dialogue/dismissing OS onboarding"
  adb shell input tap 1690 520 || true
  adb shell input tap 1160 956 || true
  sleep 2
  adb exec-out screencap -p > build/android-night1-launch.png
done
if [ "$visible" -ne 1 ]; then
  echo "ERROR: real gameplay playfield remains blank or obscured"
  exit 1
fi
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

# Real QA screenshots from the running Night 1 game scene, captured by
# debug-only F6/F7/F8 location keys (not generated illustrations).
capture_live_view() {
  local key="$1" label="$2" filename="$3"
  # On SwiftShader/Android 35, a hardware F-key can be dropped while the
  # Godot viewport releases an earlier focused menu or camera movement.
  # Retry the REAL key and require its in-engine log marker; do not weaken
  # the gameplay evidence condition or accept a static fallback picture.
  local activated=0
  for attempt in 1 2 3; do
    adb shell input keyevent "$key"
    sleep 4
    if adb logcat -d -v brief | grep -q "NIGHT1_QA_VIEW_$label"; then
      activated=1
      break
    fi
    echo "QA camera key $key for $label not acknowledged (attempt $attempt)"
  done
  if [ "$activated" -ne 1 ]; then
    echo "ERROR: Night 1 QA view $label was not activated after 3 real key attempts"
    adb exec-out screencap -p > "build/android-night1-qa-failed-$label.png" || true
    adb logcat -d -v brief | grep -E 'NIGHT1_QA|Godot|AndroidRuntime' | tail -n 100 || true
    exit 1
  fi
  adb exec-out screencap -p > "build/$filename"
  python3 .github/scripts/assert_gameplay_visible.py "build/$filename"
}
capture_live_view 135 NORTH_TRAIL android-night1-connected-trail.png
python3 .github/scripts/assert_north_trail_terrain.py build/android-night1-connected-trail.png
capture_live_view 136 VILLAGE android-night1-village.png
capture_live_view 137 SHORE android-night1-shore-dock.png
capture_live_view 138 NIGHT android-night1-night-river.png
python3 .github/scripts/assert_night_atmosphere.py build/android-night1-shore-dock.png build/android-night1-night-river.png

# On the Night 2 development branch, launch the REAL new chapter through
# its debug-only title shortcut. Never silently treat Night 1 screenshots as
# Kapre evidence; verify the new scene's exact engine log marker first.
if [ "${GITHUB_REF:-}" = "refs/heads/feature/night2-kapre" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/hud-house-depth-fix" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night03-tikbalang-connected" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/nights1-3-dimensional-art-pass" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-manananggal-the-wake" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/nighttime-lived-in-village-nights1-4" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-wake-immersive-vigil" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-final-character-animation" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-cinematic-creature-presence" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-sigbin-abandoned-farm" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-clear-farm-road" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-visible-night06-road-connection" ] || [ "${GITHUB_REF:-}" = "refs/heads/fix/shared-hud-night04-night05-consistency-20261117" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night06-rivers-unfinished-memory" ]; then
  adb shell am force-stop "$PKG" || true
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
  sleep 7
  adb shell input keyevent 140  # Android F10, QA only: enter Night 2 scene
  sleep 7
  if ! adb logcat -d -v brief | grep -q "NIGHT2_QA_SCENE_READY"; then
    echo "ERROR: Night 2 Kapre scene did not actually launch"
    adb logcat -d | grep -E 'NIGHT2_QA|Godot|AndroidRuntime' | tail -n 100 || true
    exit 1
  fi
  adb exec-out screencap -p > build/android-night2-intro.png
  # Night 2 correctly opens with Lola's modal dialogue. Android may send
  # F3 to the focused dialogue button rather than the world. Dismiss it
  # through the real visible user-facing CTA before doing camera QA.
  adb shell input tap 1160 956 || true
  sleep 2
  # Same exact camera for folklore correctness: daylight tree must be empty.
  night2_mango_ready=0
  for attempt in 1 2 3; do
    adb shell input keyevent 133  # F3, daytime mango on the LIVE Godot scene
    sleep 3
    if adb logcat -d -v brief | grep -q "NIGHT2_QA_MANGO_DAY_VIEW"; then
      night2_mango_ready=1
      break
    fi
    # Retry the dialogue footer, not a reboot or fake rendered screenshot.
    adb shell input tap 1160 956 || true
    sleep 2
  done
  if [ "$night2_mango_ready" -ne 1 ]; then
    echo "ERROR: Night 2 daytime reference did not render after dismissing Lola dialogue"
    adb logcat -d | grep -E 'NIGHT2_QA|Godot|AndroidRuntime' | tail -n 100 || true
    exit 1
  fi
  adb exec-out screencap -p > build/android-night2-mango-day.png
  python3 .github/scripts/assert_gameplay_visible.py build/android-night2-mango-day.png
  for item in "137 WITNESS witness" "138 ROUTE shelter-route" "139 MANGO kapre-tree"; do
    set -- $item
    adb shell input keyevent "$1"
    sleep 4
    if ! adb logcat -d -v brief | grep -q "NIGHT2_QA_${2}_VIEW"; then
      echo "ERROR: Chapter 2 ${2} viewport not drawn from live gameplay"
      exit 1
    fi
    adb exec-out screencap -p > "build/android-night2-${3}.png"
    python3 .github/scripts/assert_gameplay_visible.py "build/android-night2-${3}.png"
  done
  adb shell input keyevent 136  # F6: in-engine twilight/lantern art preview
  sleep 3
  if ! adb logcat -d -v brief | grep -q "NIGHT2_QA_DUSK_VIEW"; then
    echo "ERROR: Kapre twilight view did not render from actual Godot gameplay"
    exit 1
  fi
  adb exec-out screencap -p > build/android-night2-dusk.png
  python3 .github/scripts/assert_gameplay_visible.py build/android-night2-dusk.png
  # A second REAL night camera at the refuge verifies warm windows AND
  # absence of abandoned daytime villagers; mango tree view cannot prove it.
  adb shell input keyevent 134 # F4: actual shelter window at deep night
  sleep 4
  if ! adb logcat -d -v brief | grep -q "NIGHT2_QA_SHELTER_NIGHT_VIEW"; then
    echo "ERROR: Night 2 occupied refuge window nighttime capture not reached"
    exit 1
  fi
  adb exec-out screencap -p > build/android-night2-shelter-night.png
  python3 .github/scripts/assert_gameplay_visible.py build/android-night2-shelter-night.png
  # These are two distinct *live* render states with the same camera. A
  # screenshot with the giant visible in daylight invalidates this milestone.
  test -s build/android-night2-mango-day.png
  test -s build/android-night2-kapre-tree.png
  test -s build/android-night2-dusk.png
  if cmp -s build/android-night2-mango-day.png build/android-night2-kapre-tree.png; then
    echo "ERROR: Kapre daytime and nighttime captures were identical"
    exit 1
  fi
  adb shell input keyevent 135  # F5: view live walkable road back to Barrio
  sleep 4
  if ! adb logcat -d -v brief | grep -q "NIGHT2_QA_RETURN_TRAIL_VIEW"; then
    echo "ERROR: Kapre return-to-Barrio trail is not in the running game"
    exit 1
  fi
  adb exec-out screencap -p > build/android-night2-return-trail.png
  python3 .github/scripts/assert_gameplay_visible.py build/android-night2-return-trail.png
  adb logcat -d -v brief | grep -Ei 'NIGHT2_QA|Godot|AndroidRuntime' | tail -n 160 > build/android-night2-log.txt || true
  echo "PASS: actual Kapre intro, witness area, shelter and mango tree run on Android"
fi

# Night 3 uses the SAME running Godot APK, original ridge artwork, and
# actual scene title debug shortcut. These captures are never concept art.
if [ "${GITHUB_REF:-}" = "refs/heads/feature/night03-tikbalang-connected" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/nights1-3-dimensional-art-pass" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-manananggal-the-wake" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/nighttime-lived-in-village-nights1-4" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-wake-immersive-vigil" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-final-character-animation" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-cinematic-creature-presence" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-sigbin-abandoned-farm" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-clear-farm-road" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-visible-night06-road-connection" ] || [ "${GITHUB_REF:-}" = "refs/heads/fix/shared-hud-night04-night05-consistency-20261117" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night06-rivers-unfinished-memory" ]; then
  adb shell am force-stop "$PKG" || true
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
  sleep 7
  adb shell input keyevent 141  # F11: development-only REAL Night 3 entry
  sleep 8
  if ! adb logcat -d -v brief | grep -q "NIGHT3_QA_SCENE_READY"; then
    echo "ERROR: authentic Night 3 Tikbalang scene did not launch"
    adb logcat -d | grep -E 'NIGHT3_QA|Godot|AndroidRuntime' | tail -n 100 || true
    exit 1
  fi
  adb exec-out screencap -p > build/android-night3-intro.png
  for item in "133 RIDGE_DAY ridge-day" "136 WATCHPOST watchpost" "139 TIKBALANG_NIGHT tikbalang-night" "135 BACK_TRAIL back-trail"; do
    set -- $item
    adb shell input keyevent "$1"
    sleep 4
    if ! adb logcat -d -v brief | grep -q "NIGHT3_QA_$2"; then
      echo "ERROR: authentic Night 3 $2 camera state not reached"
      exit 1
    fi
    adb exec-out screencap -p > "build/android-night3-$3.png"
    python3 .github/scripts/assert_gameplay_visible.py "build/android-night3-$3.png"
  done
  # Night 3's remote ridge creature reveal does not show the watchpost;
  # independently verify the living night light at the real watchpost.
  adb shell input keyevent 137 # F7: real night camera at lookout
  sleep 4
  if ! adb logcat -d -v brief | grep -q "NIGHT3_QA_LOOKOUT_NIGHT"; then
    echo "ERROR: Night 3 night watchpost window view was not reached"
    exit 1
  fi
  adb exec-out screencap -p > build/android-night3-watchpost-night.png
  python3 .github/scripts/assert_gameplay_visible.py build/android-night3-watchpost-night.png
  if cmp -s build/android-night3-ridge-day.png build/android-night3-tikbalang-night.png; then
    echo "ERROR: Night 3 daytime and nocturnal Tikbalang are identical"
    exit 1
  fi
  echo "PASS: actual Tikbalang Night 3 intro, bamboo ridge, safe lookout, night reveal and connected trail"
fi

# Wake is a REAL Godot scene entered by a debug-only title key.
if [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-manananggal-the-wake" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/nighttime-lived-in-village-nights1-4" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-wake-immersive-vigil" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-final-character-animation" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night04-cinematic-creature-presence" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-sigbin-abandoned-farm" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-clear-farm-road" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-visible-night06-road-connection" ] || [ "${GITHUB_REF:-}" = "refs/heads/fix/shared-hud-night04-night05-consistency-20261117" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night06-rivers-unfinished-memory" ]; then
  adb shell am force-stop "$PKG" || true
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
  sleep 7
  adb shell input keyevent 142 # F12 QA-only authentic Night 4 entry
  sleep 8
  if ! adb logcat -d -v brief | grep -q "NIGHT4_QA_SCENE_READY"; then
    echo "ERROR: authentic Night 4 scene not entered"
    adb logcat -d | grep -E 'NIGHT4_QA|Godot|AndroidRuntime' | tail -n 120 || true
    exit 1
  fi
  adb exec-out screencap -p > build/android-night4-intro.png
  for item in "133 WAKE_DAY wake-day" "136 COURTYARD courtyard" "139 MANANANGGAL_NIGHT manananggal-night" "135 RIDGE_RETURN ridge-return"; do
    set -- $item
    adb shell input keyevent "$1"
    sleep 4
    if ! adb logcat -d -v brief | grep -q "NIGHT4_QA_$2"; then
      echo "ERROR: Night 4 $2 live gameplay camera did not render"
      exit 1
    fi
    adb exec-out screencap -p > "build/android-night4-$3.png"
    python3 .github/scripts/assert_gameplay_visible.py "build/android-night4-$3.png"
    if [ "$2" = "MANANANGGAL_NIGHT" ]; then
      # Capture a SECOND actual in-game frame after one full wing stroke:
      # this is not a mock illustration or a duplicated still image.
      sleep 2
      adb exec-out screencap -p > build/android-night4-wingbeat-followup.png
      python3 .github/scripts/assert_gameplay_visible.py build/android-night4-wingbeat-followup.png
      if cmp -s build/android-night4-manananggal-night.png build/android-night4-wingbeat-followup.png; then
        echo "ERROR: live night scene stopped advancing after Manananggal reveal"
        exit 1
      fi
    fi
  done
  if cmp -s build/android-night4-wake-day.png build/android-night4-manananggal-night.png; then
    echo "ERROR: Night 4 daytime and Manananggal night are identical"
    exit 1
  fi
  adb logcat -d -v brief | grep -Ei 'NIGHT4_QA|Godot|AndroidRuntime' | tail -n 180 > build/android-night4-log.txt || true
  echo "PASS: actual Night 4 wake, roof predator, courtyard and trail"
fi

# Night 5 authentic Old Farm is unlocked through the actual connected Night 4
# route in production; F8 enters this specific scene ONLY on Android DEBUG CI.
if [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-sigbin-abandoned-farm" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-clear-farm-road" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night05-visible-night06-road-connection" ] || [ "${GITHUB_REF:-}" = "refs/heads/fix/shared-hud-night04-night05-consistency-20261117" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/night06-rivers-unfinished-memory" ]; then
  adb shell am force-stop "$PKG" || true
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
  sleep 8
  adb shell input keyevent 138 # F8, debug-only Sigbin farm entry
  sleep 8
  if ! adb logcat -d -v brief | grep -q "NIGHT5_QA_SCENE_READY"; then
    echo "ERROR: Night 5 original Sigbin farm never entered from real title"
    adb logcat -d | grep -E 'NIGHT5_QA|Godot|AndroidRuntime' | tail -n 100 || true
    exit 1
  fi
  adb exec-out screencap -p > build/android-night5-intro.png
  # The opening story dialogue is intentionally opaque and fills most of the
  # central sampling region. The gameplay-pixel test must run AFTER its
  # dismissal (F3 closes it and moves to the real farm), or it falsely reports
  # a flat renderer even when the world renders correctly behind the panel.
  # Keep the unaltered intro screenshot for actual visual review.
  echo "Night 5 intro captured; world visibility is gated on subsequent LIVE farm frames."
  for item in "133 TRACKS_DAY tracks-day" "135 SAFE_GATE safe-gate" "136 BARN_COURTYARD courtyard" "139 SIGBIN_NIGHT sigbin-night"; do
    set -- $item
    adb shell input keyevent "$1"
    sleep 4
    if ! adb logcat -d -v brief | grep -q "NIGHT5_QA_$2"; then
      echo "ERROR: Night 5 $2 actual in-game shot not reachable"
      adb logcat -d | grep -E 'NIGHT5_QA|Godot|AndroidRuntime' | tail -n 80 || true
      exit 1
    fi
    adb exec-out screencap -p > "build/android-night5-$3.png"
    python3 .github/scripts/assert_gameplay_visible.py "build/android-night5-$3.png"
  done
  # Separate REAL live frame demonstrates the backward movement / hinged
  # ears. Do not pass off an unchanged character cutout as an animation.
  sleep 2
  adb exec-out screencap -p > build/android-night5-sigbin-motion.png
  python3 .github/scripts/assert_gameplay_visible.py build/android-night5-sigbin-motion.png
  if cmp -s build/android-night5-sigbin-night.png build/android-night5-sigbin-motion.png; then
    echo "ERROR: Night 5 Sigbin midnight frame stopped updating"
    exit 1
  fi
  if cmp -s build/android-night5-tracks-day.png build/android-night5-sigbin-night.png; then
    echo "ERROR: farm daylight and shadow-linked Sigbin night are identical"
    exit 1
  fi
  # Inspect the TRUE future chapter entrance on the live Android farm.
  # F11 returns the farm to daylight and frames the fully drawn road past
  # the livestock branch and the physical locked Night 6 rope. Never accept
  # a disconnected prop or a title screenshot as continuous map evidence.
  adb shell input keyevent 141  # Android F11
  sleep 4
  if ! adb logcat -d -v brief | grep -q "NIGHT5_QA_CONNECTED_NIGHT06_TRAIL"; then
    echo "ERROR: Night 6 physically connected farm trail was not reached"
    exit 1
  fi
  adb exec-out screencap -p > build/android-night5-night06-road-connected.png
  python3 .github/scripts/assert_gameplay_visible.py build/android-night5-night06-road-connected.png
  if cmp -s build/android-night5-safe-gate.png build/android-night5-night06-road-connected.png; then
    echo "ERROR: Night 6 route camera remained stuck on the animal gate"
    exit 1
  fi
  # F10 drives the REAL state-machine inspection -> deduction -> safety prep
  # -> observe -> first correct lamp; only the Android DEBUG binary exposes it.
  # This captures an actual goat in motion and its settled destination.
  rescue_ready=0
  for attempt in 1 2 3; do
    adb shell input keyevent 140 # F10, first canonical successful rescue
    sleep 2
    if adb logcat -d -v brief | grep -q "NIGHT5_QA_FIRST_RESCUE_ACTIVE"; then
      rescue_ready=1
      break
    fi
    echo "Sigbin first-rescue QA key not acknowledged (attempt $attempt)"
  done
  if [ "$rescue_ready" -ne 1 ]; then
    echo "ERROR: first Sigbin lantern rescue did not reach actual gameplay state"
    adb logcat -d -v brief | grep -E 'NIGHT5_QA|Godot|SCRIPT ERROR' | tail -n 90 || true
    exit 1
  fi
  adb exec-out screencap -p > build/android-night5-first-rescue-crossing.png
  python3 .github/scripts/assert_gameplay_visible.py build/android-night5-first-rescue-crossing.png
  sleep 4
  adb exec-out screencap -p > build/android-night5-first-rescue-settled.png
  python3 .github/scripts/assert_gameplay_visible.py build/android-night5-first-rescue-settled.png
  if cmp -s build/android-night5-first-rescue-crossing.png build/android-night5-first-rescue-settled.png; then
    echo "ERROR: saved livestock crossing did not produce two distinct gameplay frames"
    exit 1
  fi
  adb logcat -d -v brief | grep -Ei 'NIGHT5_QA|Godot|AndroidRuntime' | tail -n 180 > build/android-night5-log.txt || true
  echo "PASS: actual Night 5 abandoned barn, safe livestock gate, Sigbin shadow reveal"
fi


# Night 6 is a real Godot scene. F7 enters it on Android DEBUG CI only,
# without forging a completed Night 5 save or changing production story.
if [ "${GITHUB_REF:-}" = "refs/heads/feature/night06-rivers-unfinished-memory" ]; then
  adb shell am force-stop "$PKG" || true
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
  sleep 8
  adb shell input keyevent 137 # F7 Night 6 QA entry
  sleep 8
  if ! adb logcat -d -v brief | grep -q "NIGHT6_QA_SCENE_READY"; then
    echo "ERROR: Night 6 river chapter not entered from Android title"
    adb logcat -d -v brief | grep -Ei 'NIGHT6|Godot|AndroidRuntime' | tail -n 100 || true
    exit 1
  fi
  adb exec-out screencap -p > build/android-night6-intro.png
  for item in "133 ARCHIVE_DAY archive-day" "136 RECONSTRUCTION_BOARD reconstruction-board" "139 RIVER_MEMORY_NIGHT river-memory-night" "141 FARM_RETURN_TRAIL farm-return-trail"; do
    set -- $item
    adb shell input keyevent "$1"
    sleep 5
    if ! adb logcat -d -v brief | grep -q "NIGHT6_QA_$2"; then
      echo "ERROR: Night 6 $2 actual in-game scene missing"
      exit 1
    fi
    adb exec-out screencap -p > "build/android-night6-$3.png"
    python3 .github/scripts/assert_gameplay_visible.py "build/android-night6-$3.png"
  done
  if cmp -s build/android-night6-archive-day.png build/android-night6-river-memory-night.png; then
    echo "ERROR: Night 6 river daylight and night are identical"
    exit 1
  fi
  adb logcat -d -v brief | grep -Ei 'NIGHT6_QA|Godot|AndroidRuntime' | tail -n 180 > build/android-night6-log.txt || true
  echo "PASS: real Night 6 river, archives, reconstruction board and living current"
fi

# Exact Night 7 QA branch: capture the actual Android-rendered Balete,
# final root challenge and memorial in the live Godot scene. These are
# DEBUG ONLY key positions and do not mutate the canonical story/save.
if [ "${GITHUB_REF:-}" = "refs/heads/feature/night07-balete-finale" ] || [ "${GITHUB_REF:-}" = "refs/heads/feature/rendered-gallery-nights1-7" ]; then
  adb shell am force-stop "$PKG" || true
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
  sleep 8
  adb shell input keyevent 139 # F9, actual Night 7 title QA entry
  sleep 8
  if ! adb logcat -d -v brief | grep -q "NIGHT7_QA_SCENE_READY"; then
    echo "ERROR: Night 7 actual Balete scene did not launch on Android"
    adb logcat -d -v brief | grep -Ei 'NIGHT7|SCRIPT ERROR|Godot|AndroidRuntime' | tail -n 100 || true
    exit 1
  fi
  adb exec-out screencap -p > build/android-night7-intro.png
  for item in "133 ROAD_DUSK connected-road" "136 BALETE_DAY balete-day" "139 KEEPER_NIGHT keeper-night" "141 MEMORIAL_DAWN memorial-dawn"; do
    set -- $item
    adb shell input keyevent "$1"
    sleep 5
    if ! adb logcat -d -v brief | grep -q "NIGHT7_QA_$2"; then
      echo "ERROR: Night 7 live scene missing $2 view"
      adb logcat -d -v brief | grep -Ei 'NIGHT7|SCRIPT ERROR|Godot' | tail -n 95 || true
      exit 1
    fi
    adb exec-out screencap -p > "build/android-night7-$3.png"
    python3 .github/scripts/assert_gameplay_visible.py "build/android-night7-$3.png"
  done
  if cmp -s build/android-night7-balete-day.png build/android-night7-keeper-night.png; then
    echo "ERROR: Balete day/night views are identical on emulator"
    exit 1
  fi
  adb logcat -d -v brief | grep -Ei 'NIGHT7_QA|Godot|AndroidRuntime' | tail -n 160 > build/android-night7-log.txt || true
  echo "PASS: real Android Night 7 Balete, connected road and ancient Keeper rendered"
fi


# Screenshot-only QA fixtures to show the actual postgame renderer at day and
# night without claiming a tester completed all seven chapters. These frames
# are SYNTHETIC COMPLETED-SAVE PREVIEWS; the canonical gameplay and main
# branch are unchanged.
if [ "${GITHUB_REF:-}" = "refs/heads/feature/rendered-gallery-nights1-7" ]; then
  for entry in "133 DAY day" "134 NIGHT night"; do
    set -- $entry
    adb shell am force-stop "$PKG" || true
    adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
    sleep 8
    adb shell input keyevent "$1" # Debug title F3=day / F4=night fixture
    sleep 7
    if ! adb logcat -d -v brief | grep -q "POSTGAME_QA_SYNTHETIC_$2_SCENE_READY"; then
      echo "ERROR: missing synthetic postgame QA marker $2"
      adb logcat -d -v brief | grep -Ei 'POSTGAME|SCRIPT ERROR|Godot' | tail -n 120 || true
      exit 1
    fi
    adb shell input keyevent 136 # F6 Night1 QA camera: actual central barrio
    sleep 5
    adb exec-out screencap -p > "build/android-postgame-synthetic-$3.png"
    python3 .github/scripts/assert_gameplay_visible.py "build/android-postgame-synthetic-$3.png"
  done
  if cmp -s build/android-postgame-synthetic-day.png build/android-postgame-synthetic-night.png; then
    echo "ERROR: postgame day and night QA frames are identical"
    exit 1
  fi
  echo "PASS: emulator rendered postgame populated village at two simulated times"
fi

adb logcat -d -s AndroidRuntime:E Godot:E GodotEngine:E > build/android-night1-launch-log.txt || true
# An emulator "launch PASS" must never conceal a GDScript exception. Godot
# software renderers can log shader link errors on SwiftShader (handled by the
# live 2.5D fallback); only genuine script/runtime failures are fatal here.
adb logcat -d -v brief > build/android-entire-run-log.txt || true
if grep -E "USER SCRIPT ERROR:|SCRIPT ERROR:|Invalid call\. Nonexistent function" build/android-entire-run-log.txt; then
  echo "ERROR: Android gameplay contains Godot script exceptions"
  exit 1
fi
if grep -q "FATAL EXCEPTION" build/android-night1-launch-log.txt; then
  cat build/android-night1-launch-log.txt
  exit 1
fi
echo "PASS: real Night 1 gameplay scene visible and Android game process alive"
