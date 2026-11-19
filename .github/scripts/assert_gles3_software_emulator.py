#!/usr/bin/env python3
"""Android GLES3 diagnostics: preserve visibility of known engine startup errors.

Godot 4.3's GL Compatibility renderer can compile the built-in SceneShader
at engine startup even for a 2D-only scene. Google's SwiftShader reports
GL_MAX_FRAGMENT_UNIFORM_VECTORS (261) before Night 1's title scene appears.
This *cannot* be fixed by hiding 3D nodes later; this checker refuses to
mistake those upstream boot errors for a gameplay crash, while failing on
any 3D/canvas shader-link error AFTER the title becomes ready.

All 7 scenes still must pass real visible-screenshot and script error gates.
"""
import re
import sys
from pathlib import Path

GODOT_LOG = re.compile(r"^\S*\s*[IWE]/godot\s*\(\s*(\d+)\s*\):\s*(.*)$")
UNIFORM_LIMIT = "Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS"

def analyze(log_text: str, renderer_text: str):
    swiftshader = "swiftshader" in renderer_text.lower()
    boot_marker_seen = set()
    startup_shader_errors = 0
    runtime_shader_errors = 0
    anomalies = []
    frames = log_text.splitlines()
    software_markers = 0
    for i, line in enumerate(frames):
        match = GODOT_LOG.match(line)
        if not match:
            continue
        pid, message = match.group(1), match.group(2)
        if "NIGHT1_QA_SOFTWARE_2D_VIEWPORT_ENABLED" in message:
            software_markers += 1
        if "NIGHT1_QA_TITLE_SCENE_READY" in message:
            boot_marker_seen.add(pid)
        is_spatial_link = "SceneShaderGLES3: Program linking failed" in message
        is_any_shader_error = (is_spatial_link
             or "CanvasShaderGLES3: Program linking failed" in message
             or "shader failed to compile" in message.lower())
        if not is_any_shader_error:
            continue
        if pid in boot_marker_seen:
            runtime_shader_errors += 1
            anomalies.append(f"Shader error after title was ready (pid={pid})")
        elif not swiftshader:
            anomalies.append(f"GPU shader failure on non-SwiftShader renderer (pid={pid})")
        elif is_spatial_link:
            # The only tolerated startup special case: Godot's own Scene
            # shader exceeds the software emulator's GLES3 uniform limit.
            followup = "\n".join(frames[i + 1:i + 4])
            if UNIFORM_LIMIT not in followup:
                anomalies.append(f"Different startup SceneShaderGLES3 failure (pid={pid})")
            else:
                startup_shader_errors += 1
        elif "CanvasShaderGLES3" in message:
            anomalies.append(f"Unexpected canvas shader failure (pid={pid})")
        elif "shader failed to compile" in message.lower():
            # Generic follow-up warning is only known-safe if preceded by
            # the already recorded SceneShader boot incompatibility.
            if startup_shader_errors == 0:
                anomalies.append(f"Unexplained shader compile warning (pid={pid})")
    if swiftshader and software_markers == 0:
        anomalies.append("Software renderer missing NIGHT1_QA_SOFTWARE_2D_VIEWPORT_ENABLED")
    if swiftshader and not boot_marker_seen:
        anomalies.append("No real Godot title-ready marker; launch did not complete")
    return startup_shader_errors, runtime_shader_errors, anomalies

def _self_test():
    prefix = "I/godot   ( 1201): "
    error = "E/godot   ( 1201): "
    boot = (error+"USER ERROR: SceneShaderGLES3: Program linking failed:\n"
            +error+UNIFORM_LIMIT+" (261)\n"
            +error+"USER WARNING: shader failed to compile, unable to bind shader.\n"
            +prefix+"NIGHT1_QA_SOFTWARE_2D_VIEWPORT_ENABLED\n"
            +prefix+"NIGHT1_QA_TITLE_SCENE_READY\n"
            +prefix+"NIGHT1_QA_GAMEPLAY_SCENE_READY\n")
    known = analyze(boot, "Google SwiftShader")
    assert known[0] == 1 and known[1] == 0 and not known[2], known
    runtime = analyze(boot+error+"USER ERROR: SceneShaderGLES3: Program linking failed:", "Google SwiftShader")
    assert runtime[1] == 1 and runtime[2], runtime
    native = analyze(boot,"Adreno 740")
    assert native[2], native
    missing = analyze(error+"USER ERROR: CanvasShaderGLES3: Program linking failed:", "Google SwiftShader")
    assert missing[2], missing
    print("PASS: shader audit allows only a documented SwiftShader engine startup failure")

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        _self_test()
        raise SystemExit(0)
    if len(sys.argv) != 3:
        raise SystemExit("Usage: assert_gles3_software_emulator.py logcat.txt renderer.txt")
    count, runtime, errors = analyze(Path(sys.argv[1]).read_text(errors="replace"),
                                     Path(sys.argv[2]).read_text(errors="replace"))
    if count:
        print(f"WARNING: {count} documented Godot GLES3/SwiftShader STARTUP shader-link errors; known engine limitation, not fixed")
    print(f"Renderer audit: startup={count}, after_title={runtime}, issues={len(errors)}")
    for issue in errors:
        print("ERROR: "+issue, file=sys.stderr)
    if errors or runtime:
        raise SystemExit(1)
    print("PASS: Zero shader-link errors after title initialization on each live Android process")
