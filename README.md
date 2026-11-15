# TABI-TABI

An offline Android isometric 3D folklore mystery-adventure set in the fictional Northern Mindanao-inspired **Barrio Lawom**.

## Current Night 1 QA milestone

**Night 1 — The Light on the River (Santelmo)** is an *installable QA build*, NOT a finished cinematic or production-ready vertical slice. There are seven nights in the approved master script, but the quality-first gate requires a validated Night 1 before creating Night 2 content.

**Direct Night 1 development APK:** [Download the latest GitHub prerelease APK](https://github.com/LokiJ07/Tabi-tabi/releases/download/night1-dev/tabi-tabi-night1-debug.apk)

[Workflow builds and logs](https://github.com/LokiJ07/Tabi-tabi/actions) · [Development PR](https://github.com/LokiJ07/Tabi-tabi/pull/1)

> **Installation warning:** The current CI uses an *ephemeral debug signing key* on every run. New builds might fail to install over a previous APK; uninstalling can erase test saves. Production updates require a stable, privately stored signing key. Use the preview APK for testing only.

## Present in the feature branch

- Procedural Barrio Lawom environment with distinct building details, explorable Lola-hut morning prologue, safe riverbank collision, fishing/market props and an original low-poly banca with shaped hull, bamboo outriggers, seats and paddle (rather than a single placeholder boat cube).
- Isometric camera with actor-targeted cinematic conversation framing; touch movement and independent lantern Focus; distinct 3D NPC silhouettes/outfits for Lola, Dado, Mara and Sabel; original painted four-person bust portrait atlas, speaker-aware cinematic dialogue, blink/speech gestures and reversible reduced-motion transitions.
- Evidence notebook, contextual witness interviews, two clue links and a private revisable theory.
- Four-slot supply preparation; cloth-wrap lantern calming, signal-bell defensive choice, single-use water recovery.
- Reactive Santelmo, reflection puzzle with proximity check, **in-world lantern guiding to the safe shore for Resolve**, Courage pressure, no-fail story assist, safe checkpoint retry.
- Resolve, Drive Away, Partial outcomes; conditional next-morning dialogue, persistent outcome markers.
- Local story saving with backup and independent offline accessibility settings (text scale, contrast, reduced motion, hint detail).
- Godot headless parser/smoke/regression tests, scene-level Night 1 flow tests for all three outcomes and Android APK export.

### Still missing or unverified

- Final cinematic painterly **3D** artwork, fully rigged actor/facial animations, cinematic camera direction, creature VFX and finished voice/sound design. The currently implemented painted *dialogue portraits* are real offline game assets but do not replace these.
- Finished Lola-hut art/cinematics and complete village interactions. Additional visual props and speaker-attributed dialogue overlays exist, but the chapter still needs user-approved production art and pacing.
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

See [development gates](docs/QUALITY_GATES.md) and the [Night 1 go/no-go checklist](docs/NIGHT01_RELEASE_CANDIDATE_CHECKLIST.md) for the master-script test requirements. Android CI additionally attempts a real emulator install-and-launch smoke, which never replaces physical phone tests.

## Canon

Based on **TABI-TABI Final Master Script & Development Plan v1.0**, 24 pages, 14 November 2026. The fixed history separates Mang Celso (the Santelmo boatman) from Sabel's late husband; do not merge these identities or claim Mara witnessed the flood as an adult.

Godot 4.3 · GDScript · Android landscape · offline-first.
