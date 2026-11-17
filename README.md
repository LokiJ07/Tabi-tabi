# TABI-TABI — Barrio Lawom (Android)

**One continuous seven-night Philippine folklore mystery.** Godot 4.3, offline-first, landscape Android, illustrated/isometric 2.5D, tactile touch HUD, named companions and witnesses, investigations, meaningful non-lethal outcomes, and local saves.

## Current playable chapters

| Chapter | Location and folklore | Implemented play |
| --- | --- | --- |
| **Night 1 — Santelmo** | Barrio Lawom riverside and mangrove shore | Lola's morning prologue, Apprentice/Bantay, interactive witnesses, weather/light, clues, Focus/lantern, safety choices and independent outcomes/save |
| **Night 2 — Kapre** | Ancient mango grove | Connected trail, original Kapre/tree assets, observation, five clues, environmental hazards, negotiation and local save |
| **Night 3 — Tikbalang** | Bamboo flood ridge and watchpost | Connected hillside route, true-versus-false trail evidence, ordered safety markers, guardian, witness, fair outcomes and separate save |
| **Night 4 — Manananggal: The Wake** | Wake-house compound | Investigation and caretaker protection; Aling Nena is the vulnerable target, NOT the creature. Four preparations, three group defenses, fair retries, original animated winged creature, and independent outcome/save |
| **Night 5 — Sigbin: The Abandoned Farm** | Connected old farm, barn and livestock pen | Four tangible clues, nonviolent guardian deduction, marked observation point, five preparations, three connected lantern-shadow routes, actual fenced livestock pen and gate, animated rescue into a fenced safe holding area, meaningful outcomes and offline save |

All five are chapters of **one story** with the same Apprentice and Bantay and a connected-world ledger. Night 6 and Night 7 are future chapters and are **not implemented** in this baseline.

## Shared experience

- Shared navy / antique-gold / cream gameplay HUD, fixed left D-pad and right action anchors, status panel and field notebook — see scripts/ui/shared_hud.gd.
- Grounded illustrated 2.5D perspective, sprites with contact shadows, depth and raised architecture; native Night 1 uses physical 3D village meshes with a fallback renderer — see scripts/visuals/layered_25d.gd.
- Consistent speaker transitions and readable dialogue — see scripts/ui/shared_dialogue_motion.gd.
- After dark, fewer villagers outside and warm window glow, curtains and low intensity light spill — see scripts/visuals/nighttime_windows.gd.
- Threat-led subtle atmospheric pressure; Reduced Motion and offline original sound — see scripts/visuals/shared_immersive_atmosphere.gd.
- Night 4 original wake props, 3-layer hinged Manananggal wings, encounter camera bounds and safe indoor mourner transitions.
- Night 5 farm has clear world signs, genuinely fenced pen and receiving paddock, a single livestock-only gate, a visibly marked safe observation spot, amber lantern routes, jointed backwards-walking Sigbin, and subtle offline audio synced to movement. Existing saved animals remain safe at the gate after reload.

### Night 5 player route (no barn shortcuts)

1. Speak to the farmer and inspect four clues **outside** the unsafe raised barn and fenced livestock pen.
2. At the marked `OBSERVE HERE` area, interpret evidence without blaming an actual family; identify the creature's guardian role.
3. Prepare the stable perimeter, animal-only safe gate and west/north/east lanterns.
4. Stand at `OBSERVE HERE` and hold `HOLD OBSERVE` to identify one real shadow, then select which lantern interrupts it.
5. After a correct choice, watch one animal group **walk through the physical pen gate** into the **separate safe holding paddock**. Repeat for all three. A wrong lamp does not rescue an animal; the safe retry preserves already-earned progress.
6. Record the actual aftermath at dawn; the game keeps its Night 1–5 story continuity and schema-v5 save.

The player may approach and prepare the gate from outside; they **cannot enter** the penned animals' enclosure or unstable barn. The gate is an exit **for the rescued animals**, not a hidden player entrance.

## Test and release status

Nights 1–5 form an **engineering-ready Android QA baseline**, not a finished public seven-night release. Night 5 has real Godot scene/state tests plus Android emulator chapter and rescued-animal crossing captures. Check the latest relevant Godot validation and Android emulator runs in GitHub Actions before calling a change release-ready.

Still needed for production: actual phone comfort/performance/heat, all outcomes played by humans, detailed art approval, and a stable signing key. CI-generated QA APKs use temporary signing, and uninstalling old builds can erase saves.

## Development direction

Build each night on a separate PR, following Final Master Script & Development Plan v1.0 (14 November 2026). Do not change canon, previous outcomes, shared touch controls, or the established art/HUD system. Night 5 uses Sigbin's shadow logic, missing goats and a rescue of farm animals without turning the folklore witness into a generic enemy. Night 6 must be developed as a new connected chapter/PR after the Night 5 merge and its explicit QA gate.

CI: https://github.com/LokiJ07/Tabi-tabi/actions
