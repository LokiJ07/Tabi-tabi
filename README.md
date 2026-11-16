# TABI-TABI — Barrio Lawom (Android)

Offline-first, connected Philippine folklore investigation built with **Godot 4.3** for Android landscape. This README describes the **experimental Nights 1–3 2.5D art branch**, not the repository's still-minimal `main` branch.

## Current playable chapters

| Chapter | Region / encounter | Actual gameplay |
| --- | --- | --- |
| Night 1 — Santelmo | Barrio Lawom riverside | 3D isometric neighborhood with Android software-rendered 2.5D fallback, Apprentice/Bantay, lantern/Focus, clues, conversations, notebook, meaningful outcomes and save |
| Night 2 — Kapre | Old mango grove | Connected traversable trail, original Kapre and mango art, five evidence clues, safety barriers, protected observation, negotiations, endings and independent save |
| Night 3 — Tikbalang | Flood ridge | Connected ridge gate, watchpost, bamboo and equine-headed ridge guardian, four clues, ordered safety markers, route-verification puzzle, witness account, endings and independent save |

**One story, not three unrelated games:** Night 1 → Night 2 → Night 3 are connected through the original Great Flood mystery, persistent outcome ledger and physical world transitions. Night 4–7 are **planned, locked and not playable**.

## Shared visual identity

Nights 1–3 use the same navy/gold gameplay HUD grammar, button positions, dialogue transition controller and original Apprentice/Bantay identities. The shared layered renderer is at `scripts/visuals/layered_25d.gd`.

- Native Night 1: additional 3D silhouette plane, actual horizontal contact shadow meshes and existing volume-built homes; emulator fallback paints live actors, objects and reflections from the same world coordinates.
- Nights 2–3: depth-backed imported SVG sprites, contact shadows, weather-aware lanterns and environment darkness drawn *behind* readable characters.
- Walking bob returns to zero when stopped; Reduced Motion disables animation.
- Night 3 horse muzzle and shore water-reflection pass added after review of **actual emulator screenshots**. Static AI concept images are **not** gameplay screenshots or runtime sprite layers.

This pass makes the current illustrated game art more dimensional. It does **not** imply that fully rigged models, painterly concept-quality environments, cinematic lighting or all performance optimizations are complete.

## Validation and Android QA

- **Godot validation:** import/parser, state/endings, scene integration, connected trails, touch HUD, save/restore and chapter consistency checks.
- **Android CI:** debug APK build and emulator smoke that launches actual Night 1–3 Godot scenes on this art branch. Artifacts include original 2340×1080 screenshots and crash logs.
- CI run page: https://github.com/LokiJ07/Tabi-tabi/actions
- Work-in-progress art pull request: https://github.com/LokiJ07/Tabi-tabi/pull/5

**Not a public release.** A green CI job proves automated coverage, not physically verified controls, smooth FPS on all phones, or the quality of every sprite. Production merging requires screenshot review plus real-device playthrough of the latest signed build, saved-progress recovery, full encounter pacing and image-quality approval.

### Installing test APKs

CI signs debug APKs with a temporary key; different runs can reject install-over. **Back up or preserve important saves before uninstalling** because local data may be erased. A stable release signing key must be configured for future updates.

## Development boundaries

Use separate feature branches and PRs. Preserve the seven-night narrative canon and character identities. Keep screen-space UI anchored consistently, avoid oversized labels and ensure keyboard/touch movement and dialogue input remain valid when editing scenes. No production merge without current green tests and real-device approval.

Canon: *TABI-TABI Final Master Script & Development Plan v1.0* (14 November 2026). Mang Celso and Sabel's late husband remain different people; Mara's Great Flood knowledge is not a fabricated adult eyewitness account.
