# G5 visual screenshot QA — Nov 15, 2026

Downloaded and inspected original Android emulator screenshots from GitHub Actions, not just the Godot source or engine tests.

## Verified rendered UI

- **Field Notebook**: Full-width opaque panel, legible journal at default size, fixed Close button, correct vertical scroll and unobscured game controls.
- **Preparation**: Six item rows are visibly readable, selected equipment clearly separated by green border and fill, fixed Close.
- **Options**: All six settings are clearly readable and distinctly clickable, fixed Close.
- **Scrolled Notebook** revealed a real design issue: without collected clues, the "CONNECT EVIDENCE" heading was displayed directly above the GUIDE GENTLY / CHASE AWAY **private theory** buttons, misleading the player into treating interpretations as evidence.
- Corrected by displaying "CONNECT EVIDENCE" only when an actual clue pair can be linked; introducing independent "PRIVATE THEORY | NOT VERIFIED" heading and highlighting chosen interpretation separately.
- Added HUD regression checks for absent/present heading and the theory selection emphasis.

## Graphics limitation verified from Android emulator log

The initial game scene screenshot showed an empty cyan background while the 2D HUD worked. Logcat explicitly contained:

`SceneShaderGLES3: Program linking failed: Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`

This is emitted by Android Emulator SwiftShader OpenGL ES 3.0. Because the user's real physical phone screenshots showed barrio geometry, do **not** conclude this is a universal game renderer failure. Treat rendering through this emulator GPU as a separate graphics-compatibility gate and look for a GPU backend that can render 3D. The Android APK installation, activity launch, in-engine state, UI and crash check pass.

## Remaining

Run a physical phone check at all three text scales (100/120/140%). Verify no clipping in dense late-game journal, readable modal footer and live movement Focus behind closed menus. These screenshots do not prove cinematic content or full game G5/G6.
