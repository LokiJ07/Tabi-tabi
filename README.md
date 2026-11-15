# TABI-TABI

An offline Android isometric 3D folklore mystery-adventure set in the fictional Northern Mindanao-inspired **Barrio Lawom**.

## Current playable development target

**Night 1 — The Light on the River (Santelmo)** is an *installable engineering prototype*, NOT a finished cinematic or production-ready vertical slice. There are seven nights in the approved master script, but the quality-first gate requires a validated Night 1 before creating Night 2 content.

**Direct Night 1 development APK:** [Download the latest GitHub prerelease APK](https://github.com/LokiJ07/Tabi-tabi/releases/download/night1-dev/tabi-tabi-night1-debug.apk)

[Workflow builds and logs](https://github.com/LokiJ07/Tabi-tabi/actions) · [Development PR](https://github.com/LokiJ07/Tabi-tabi/pull/1)

> **Installation warning:** The current CI uses an *ephemeral debug signing key* on every run. New builds might fail to install over a previous APK; uninstalling can erase test saves. Production updates require a stable, privately stored signing key. Use the preview APK for testing only.

## Present in the feature branch

- Procedural Barrio Lawom blockout, explorable morning interior of Lola’s hut with interactive notebook/cup/photo and physical door transition, safe riverbank collision, store/school/landing, a boat and simple resident routines.
- Isometric camera; touch movement and independent lantern Focus; temporary Apprentice/Bantay silhouettes, gait and awareness.
- Evidence notebook, contextual witness interviews, two clue links and a private revisable theory.
- Four-slot supply preparation; cloth-wrap lantern calming, signal-bell defensive choice, single-use water recovery.
- Reactive Santelmo, reflection puzzle with proximity check, **in-world lantern guiding to the safe shore for Resolve**, Courage pressure, no-fail story assist, safe checkpoint retry.
- Resolve, Drive Away, Partial outcomes; conditional next-morning dialogue, persistent outcome markers.
- Local story saving with backup and independent offline accessibility settings (text scale, contrast, reduced motion, hint detail).
- Godot headless parser/smoke/regression tests, scene-level Night 1 flow tests for all three outcomes and Android APK export.

### Still missing or unverified

- Final cinematic painterly 3D artwork, full NPC and Bantay rigs/animations, creature VFX and sound.
- Finished Lola-hut art/cinematics, richer village interactions, polished HUD and fully authored subtitles; a basic interactive morning hut prologue is implemented in the feature branch.
- Complete Cebuano/Filipino/English localization, sound preferences, HUD remapping, story cinematics, comprehensive performance presets.
- Actual phone gameplay validation of the **latest** build, end-to-end uncoached tests, safe-area and FPS/thermal profiling.
- Night 2–7 gameplay implementation, historical reconstruction, Keeper trial, all endings and full epilogue.

**Do not interpret green CI or the installable APK as a complete Night 1 sign-off.**

## Development process

1. Implement on `feature/night1-foundation`, not directly on `main`.
2. Run GDScript import, scene smoke, story state and UI/encounter regression tests.
3. Run scene-level automated Night 1 flow through Resolve/Drive Away/Partial and verify save/reload.
4. Export Android debug APK; upload artifact and update rolling development prerelease if checks pass.
5. After the planned production art/features, request uncoached real-device feedback and resolve blockers **before** advancing to Night 2.

See [development gates](docs/QUALITY_GATES.md) for the master-script roadmap and remaining work.

## Canon

Based on **TABI-TABI Final Master Script & Development Plan v1.0**, 24 pages, 14 November 2026. The fixed history separates Mang Celso (the Santelmo boatman) from Sabel's late husband; do not merge these identities or claim Mara witnessed the flood as an adult.

Godot 4.3 · GDScript · Android landscape · offline-first.
