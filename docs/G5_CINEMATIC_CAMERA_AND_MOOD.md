# G5 — Cinematic camera, actor acting and visual mood (Night 1)

This phase builds directly on the existing distinct NPC silhouettes, painted four-character bust atlas and cinematic dialogue UI.

## What actually changed
- New `scripts/visuals/cinematic_camera.gd`: reversible, speaker-aware in-world camera framing. Dialogue still uses the illustrated bust overlay but now also focuses the *actual 3D actor* in Barrio Lawom. Lola interior dialogue targets the Lola interior model; other witness conversations target their village markers. Narration during the Santelmo encounter frames the spirit. Apprentice and Bantay have their own focus target.
- Story shots tighten orthographic size while keeping the world visible behind the dialogue; the camera smoothly returns to the original isometric framing once the final line closes.
- In Reduced Motion, camera transitions snap rather than animate. Camera moves never teleport the player, change world state or modify the save file.
- New inexpensive procedural speaking mouth and eye blink (each of the four witnesses and Apprentice), plus a subtle arm gesture while speaking. Reduced Motion suppresses blinks / dynamic lip motion.
- `scripts/visuals/barrio_lighting.gd`: warm daylight key/ambient, blue-toned night/moon ambience and readable amber lantern beam. It is GL Compatibility friendly and creates no extra shadow cascades or screen-space passes.
- Added camera/acting and day/night lighting CI tests, including the Android export regression gate.

## Not yet achieved / release caveats
These are cinematography and *intermediate* facial performance, not fully rigged high-fidelity 3D acting, 3D facial skinning, lip-synced voice acting or polished cinematic camera blocking at every possible terrain obstruction. All named characters still use distinct procedural meshes. The Android emulator uses SwiftShader and has shown a GL shader-uniform failure resulting in a blank 3D background; successful install/smoke does not certify rendered world on a physical GPU.

## Production gate
Check actual physical phone: dialogue transitions for Apprentice/Lola, Dado by landing, Mara outside school, Sabel store, resolved/partial Santelmo; camera collision/occlusion by hut roof, visible portraits, no input leakage, 100–140% dialogue fonts, stable FPS, day/night balance and color/accessibility. Do not merge to main or start Night 2 until G5/G6 acceptance.
