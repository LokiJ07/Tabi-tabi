# TABI-TABI — Barrio Lawom (Android)

**One continuous seven-night Philippine folklore mystery.** Godot 4.3, offline-first, landscape Android, illustrated/isometric 2.5D, tactile touch HUD, named companions and witnesses, investigations, meaningful non-lethal outcomes, and local saves.

## Current playable chapters

| Chapter | Location and folklore | Implemented play |
| --- | --- | --- |
| **Night 1 — Santelmo** | Barrio Lawom riverside and mangrove shore | Lola's morning prologue, Apprentice/Bantay, interactive witnesses, weather/light, clues, Focus/lantern, safety choices and independent outcomes/save |
| **Night 2 — Kapre** | Ancient mango grove | Connected trail, original Kapre/tree assets, observation, five clues, environmental hazards, negotiation and local save |
| **Night 3 — Tikbalang** | Bamboo flood ridge and watchpost | Connected hillside route, true-versus-false trail evidence, ordered safety markers, guardian, witness, fair outcomes and separate save |
| **Night 4 — Manananggal: The Wake** | Wake-house compound | Investigation and caretaker protection; Aling Nena is the vulnerable target, NOT the creature. Four preparations, three group defenses, fair retries, original animated winged creature, and independent outcome/save |

All four are chapters of **one story** with the same Apprentice and Bantay and a connected-world ledger. **Night 5 — Sigbin: The Abandoned Farm** is the next chapter. Nights 5–7 are not on this main baseline yet.

## Shared experience

- Shared navy / antique-gold / cream gameplay HUD, fixed left D-pad and right action anchors, status panel and field notebook — see scripts/ui/shared_hud.gd.
- Grounded illustrated 2.5D perspective, sprites with contact shadows, depth and raised architecture; native Night 1 uses physical 3D village meshes with a fallback renderer — see scripts/visuals/layered_25d.gd.
- Consistent speaker transitions and readable dialogue — see scripts/ui/shared_dialogue_motion.gd.
- After dark, fewer villagers outside and warm window glow, curtains and low intensity light spill — see scripts/visuals/nighttime_windows.gd.
- Threat-led subtle atmospheric pressure; Reduced Motion and offline original sound — see scripts/visuals/shared_immersive_atmosphere.gd.
- Night 4 original wake props, 3-layer hinged Manananggal wings, encounter camera bounds and safe indoor mourner transitions.

## Test and release status

Nights 1–4 are an **engineering-ready playable Android QA baseline**, not a public seven-night release. Last integrated Night 4 commit 9504380 passed Godot validation and debug APK/emulator on GitHub (runs 44019758812, 44019765437, 44019758762). Actual Android screenshots include the four night scenes and two wingbeat frames.

Still needed for production: actual phone comfort/performance/heat, all outcomes played by humans, detailed art approval, and a stable signing key. CI-generated QA APKs use temporary signing, and uninstalling old builds can erase saves.

## Development direction

Build each night on a separate PR, following Final Master Script & Development Plan v1.0 (14 November 2026). Do not change canon, previous outcomes, shared touch controls, or the established art/HUD system. Night 5 uses Sigbin's shadow logic, missing goats and a rescue of farm animals without turning the folklore witness into a generic enemy.

CI: https://github.com/LokiJ07/Tabi-tabi/actions
