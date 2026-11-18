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
| **Night 6 — What the Water Took** | Uphill farm road to old flood crossing and river terrace | Four historical sources, ordered cancellation / rescue-route / rescuer-identity reconstructions, private Sabel and Lola testimony, three marked-stone river surges, separate offline save and safe aftermath |
| **Night 7 — The Ancient Keeper's Trial** | Connected Balete Grounds, remembrance plaza and village sunrise | Explicit evidence-readiness checkpoint; privacy-safe public gathering and practical commitments; root-path and source-backed truth trials; awakened environmental defense; four endings and player-paced epilogue |

All seven are chapters of **one story** with Apprentice, Bantay and a connected-world ledger. Completing Night 6—any genuine recorded ending—opens the last physically connected path.

## Shared experience

- Shared navy / antique-gold / cream gameplay HUD, fixed left D-pad and right action anchors, status panel and field notebook — see scripts/ui/shared_hud.gd.
- Grounded illustrated 2.5D perspective, sprites with contact shadows, depth and raised architecture; native Night 1 uses physical 3D village meshes with a fallback renderer — see scripts/visuals/layered_25d.gd.
- Consistent speaker transitions and readable dialogue — see scripts/ui/shared_dialogue_motion.gd.
- After dark, fewer villagers outside and warm window glow, curtains and low intensity light spill — see scripts/visuals/nighttime_windows.gd.
- Threat-led subtle atmospheric pressure; Reduced Motion and offline original sound — see scripts/visuals/shared_immersive_atmosphere.gd.
- Night 4 original wake props, 3-layer hinged Manananggal wings, encounter camera bounds and safe indoor mourner transitions.
- Night 5 farm has clear world signs, genuinely fenced pen and receiving paddock, a single livestock-only gate, a visibly marked safe observation spot, amber lantern routes, jointed backwards-walking Sigbin, and subtle offline audio synced to movement. Existing saved animals remain safe at the gate after reload.

### Night 5 player route (no barn shortcuts)

1. Speak to the farmer and inspect four clues **outside** the unsafe raised barn and fenced livestock pen. The goats and chickens are missing during the initial investigation, not inexplicably visible from the start.
2. At the marked `OBSERVE HERE` area, interpret evidence without blaming an actual family; identify the creature's guardian role.
3. Prepare the stable perimeter, animal-only safe gate and west/north/east lanterns.
4. Stand at `OBSERVE HERE` and hold `HOLD OBSERVE` to identify one real shadow, then select which lantern interrupts it.
5. After a correct choice, watch one animal group **walk through the physical pen gate** into the **separate safe holding paddock**. Repeat for all three. A wrong lamp does not rescue an animal; the safe retry preserves already-earned progress.
6. Record the actual aftermath at dawn; the game keeps its Night 1–5 story continuity and schema-v5 save.

The player may approach and prepare the gate from outside; they **cannot enter** the penned animals' enclosure or unstable barn. The gate is an exit **for the rescued animals**, not a hidden player entrance.

### One uninterrupted world road into Night 6

The MAIN footpath **does not end at the animal gate or the far side of the farm**. It continues from the Night 4 wake, through the Night 5 observation area, branches off a narrow gate spur, winds north-east uphill between (but never through) the two farm enclosures, and reaches the visibly signed **NIGHT 6 TRAIL**. The road itself carries on beyond the sign into the hillside so it never resembles a cut-off texture. The receiving paddock has been placed far enough downhill to leave clearance for the road and raised wooden posts. Animal rescue uses a separate west-side receiving opening, not the public path.

Night 6's farm checkpoint now unlocks after the **genuine Night 5 outcome** is stored in the connected-world ledger. The same uninterrupted footpath streams into the real Night 6 river-terrace scene and supports a save-safe return to the farm. The canonical coordinate remains `scripts/core/connected_world.gd` (`TRAIL_FARM_NIGHT06`). Night 7 unlocks only after a genuine Night 6 outcome; the road and return route are physically authored.

### Post-story Free Roam — seven connected maps

After completing the Night 7 morning epilogue, choose **COMPLETE STORY • EXPLORE ALL 7 MAPS**. A genuinely saved completed finale unlocks permanent offline Free Roam. Walk through the existing physical connected roads in either direction: **Barrio Lawom ↔ Old Mango ↔ Tikbalang Ridge ↔ The Wake ↔ Sigbin Farm ↔ River Crossing ↔ Balete Grounds**. Past chapter endings no longer repeatedly block the roads, and prior consequences and chapter saves remain intact. The title's **FREE ROAM • ALL 7 MAPS** option resumes the most recently visited region. Chapter selections from the title can optionally jump to a visited region once the ending is completed, but walking inside the game always requires adjacent paths. Starting a new seven-night story requires explicit confirmation and clears all prior chapter saves and exploration status.

### Night 6 player route (source-backed and nonfatal)

1. Collect the cancelled launch order, water gauge, evacuation register and alternative-route log. Dado may decline to testify.
2. Reconstruct why the second official rescue was stopped: real danger **and** unequal decisions. An independent private rescue does not prove officials could safely cross.
3. Plot the returning boat's dock → stranded far bank → shelter route. Verify two separate sources before identifying the brave rescuer as Sabel's husband (distinct from Mang Celso).
4. Respect Sabel's private/public remembrance choice and examine Lola's limited-refuge promise and withheld records.
5. Secure the rope anchor, lantern beacon and marked stones; use the **same Night 1 touch HUD** with HOLD OBSERVE at three different river surges. Retrying never loses lives or earlier evidence.
6. Record a truthful Resolve, Contain or Partial/Retreat outcome. The Night 7 Balete route is still intentionally locked.

## Test and release status

Nights 1–7 form an **engineering QA baseline**, not an approved public release. Night 6 has headless real-scene/evidence-state tests and dedicated Android emulator capture, in addition to previous farm and Sigbin regression checks. Check the latest relevant Godot validation and Android emulator runs in GitHub Actions before calling a change release-ready.

Still needed for production: actual phone comfort/performance/heat, all outcomes played by humans, detailed art approval, and a stable signing key. CI-generated QA APKs use temporary signing, and uninstalling old builds can erase saves.

## Development direction

Build each night on a separate PR, following Final Master Script & Development Plan v1.0 (14 November 2026). Do not change canon, previous outcomes, shared touch controls, or the established art/HUD system. Night 5 uses Sigbin's shadow logic, missing goats and a rescue of farm animals without turning the folklore witness into a generic enemy. Night 6 implementation is a connected and source-backed river history chapter, not a generic monster duel. Night 7 follows with readiness, consent-safe gathering, environmental root/Truth trials and replayable four-ending epilogue. Public release still requires human playtests and real-phone compatibility.

CI: https://github.com/LokiJ07/Tabi-tabi/actions
