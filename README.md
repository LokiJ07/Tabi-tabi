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
| **Night 7 — Ancient Keeper / The Promise of Remembrance** | Balete Grounds, physically connected from river hill road | Original 2.5D Balete art; four grounded evidence stations; source-based final deduction; three community/safety preparations; three HOLD OBSERVE Keeper trials with safe retry; story-aware community ending; consent-sensitive memorial and playable morning epilogue; independent save |

All seven are chapters of **one connected story** with the same Apprentice and Bantay and a shared, protected connected-world ledger. The final Balete road only opens after an actual saved Night 6 outcome; no QA preview or manual menu click is a canonical unlock.

## Shared experience

- Shared navy / antique-gold / cream gameplay HUD, fixed left D-pad and right action anchors, status panel and field notebook — see scripts/ui/shared_hud.gd.
- Grounded illustrated 2.5D perspective, sprites with contact shadows, depth and raised architecture; native Night 1 uses physical 3D village meshes with a fallback renderer — see scripts/visuals/layered_25d.gd.
- Consistent speaker transitions and readable dialogue — see scripts/ui/shared_dialogue_motion.gd.
- After dark, fewer villagers outside and warm window glow, curtains and low intensity light spill — see scripts/visuals/nighttime_windows.gd.
- Threat-led subtle atmospheric pressure; Reduced Motion and offline original sound — see scripts/visuals/shared_immersive_atmosphere.gd.
- Night 4 original wake props, 3-layer hinged Manananggal wings, encounter camera bounds and safe indoor mourner transitions.
- Night 5 farm has clear world signs, genuinely fenced pen and receiving paddock, a single livestock-only gate, a visibly marked safe observation spot, amber lantern routes, jointed backwards-walking Sigbin, and subtle offline audio synced to movement. Existing saved animals remain safe at the gate after reload.

### Final art, animation and mobile HUD polish (seven-night branch)

- **Connected-world cinematic crossings:** all seven region-to-region roads and title/menu transitions use the same persistent twilight-navy fade curtain, destination name and soft incoming reveal. The curtain survives scene replacement and blocks accidental touch input, while Reduced Motion and headless tests retain immediate transitions. The unchanged story ledger still controls which road is legally open; this is visual continuity, not a level-select workaround. See `scripts/core/scene_transit.gd` and `tests/shared_scene_transit_test.gd`.
- **Night 1's HUD remains canonical.** The right-hand HOLD OBSERVE control on Nights 2–7 now shows **OBSERVING...** in the same antique-gold pressed state as Night 1's FOCUS HELD control. Every left-hand D-pad and held action releases on finger drag-out or when a modal hides gameplay. All existing positions, action sizes and touch anchors remain unchanged.
- The shared LOOK AROUND pad has a drawn two-axis guide and thumb indicator; its central deadzone resets the actual aim instead of leaving a previous direction stuck. Reduced Motion remains supported.
- Nights 2–7 use one shared grounded actor motion painter for the apprentice and Bantay: consistent paired step contact shadows, subtle gait compression and a smooth return to both feet at idle, without changing collisions or rewriting any chapter's authored poses.
- Night 7's live Balete camera now fits more of the original tree canopy while retaining the walking apprentice and unmodified fixed-screen HUD; restrained fireflies add life to the root canopy.
- The postgame settlement has **four independently illustrated identities** (archive, farming, repairs and school) in addition to existing fishing/market/trail workers. Morning tasks now use consistent small movements; Reduced Motion freezes decorative movement.
- Night 1's postgame 3D village adds an actual slatted reed market canopy, animated drying nets and more distinct role-specific worker portraits. Visual-only assets never close public paths or grant fake story rewards.

This is a **targeted in-engine asset and movement polish pass**, not yet a production-grade skeletal-animation remake. Do not mistake static concept sheets for actual frame-captured Android scenes. Every merge must pass new `tests/final_polish_all_nights_test.gd`, the complete old playthroughs, and APK + emulator smoke. Android handset feel, screen-size readability and detailed face quality still require human acceptance.

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

Night 6's farm checkpoint now unlocks after the **genuine Night 5 outcome** is stored in the connected-world ledger. The same uninterrupted footpath streams into the real Night 6 river-terrace scene and supports a save-safe return to the farm. The canonical coordinate remains `scripts/core/connected_world.gd` (`TRAIL_FARM_NIGHT06`). After an actual Night 6 conclusion, the hill path continues physically into the playable Night 7 Balete area; otherwise it is clearly gated.

### Night 6 player route (source-backed and nonfatal)

1. Collect the cancelled launch order, water gauge, evacuation register and alternative-route log. Dado may decline to testify.
2. Reconstruct why the second official rescue was stopped: real danger **and** unequal decisions. An independent private rescue does not prove officials could safely cross.
3. Plot the returning boat's dock → stranded far bank → shelter route. Verify two separate sources before identifying the brave rescuer as Sabel's husband (distinct from Mang Celso).
4. Respect Sabel's private/public remembrance choice and examine Lola's limited-refuge promise and withheld records.
5. Secure the rope anchor, lantern beacon and marked stones; use the **same Night 1 touch HUD** with HOLD OBSERVE at three different river surges. Retrying never loses lives or earlier evidence.
6. Record a truthful Resolve, Contain or Partial/Retreat outcome. This saves the authentic River ledger and opens the Night 7 Balete trail.

### Night 7 player route — Ancient Keeper and the conclusion

1. From the real Night 6 hill path, arrive on the same connected footpath at Balete Grounds. The street is never a dead-end level select.
2. Inspect four evidence stations: changed rescue waymark, Balete's limited refuge, memorial stone and Lola's flood oath. Wrong historical guesses are revisable, not rewarded.
3. At the Keeper's Pact, distinguish documented human responsibility from the guardian's limited supernatural protection.
4. Prepare the safe footpath, protect witness privacy, and arrange a respectful offering; Aling Sabel's public-remembrance consent from Night 6 **cannot be overridden**.
5. Approach three physically marked root stones. HOLD OBSERVE, then answer each of the Keeper's meaningful memory/consent/community trials, with a safe retry for mistakes.
6. Select Renewal (only when the true earlier river evidence permits), Repair, or Guarded aftermath. All outcomes acknowledge lost people and survivor agency rather than a magical reset.
7. Play the final dawn/Memory Stone epilogue. Only after selecting **COMPLETE EPILOGUE • ENTER LIVING WORLD** are all seven saved chapter outcomes verified and the automatic world clock unlocked. Return across all seven connected regions to see people living and working by time of day.

## Post-finale automatic day/night (implemented across seven regions)

Only **after the full Night 7 epilogue** is completed and all seven actual chapter outcomes are saved does post-game free roam unlock. The shared `PostgameClock` autoload then advances one full in-game day every **24 minutes of active runtime** and saves the clock into the connected-world ledger (every 15 seconds and on app pause). Re-entering streamed regions keeps the same time rather than restarting each region at day or night.

- Pre-finale Nights 1–7 keep their authored story lighting and quests. A Night 1 standalone resolution does **not** unlock free-roam time.
- After the finale, Night 1's DAY / NIGHT control becomes a disabled AUTO CYCLE status; the day/night logic is automatically shared by the Barrio and Nights 2–7 scenes through their existing art and sound stage handlers.
- Completed players may walk adjacent implemented routes without replaying each chapter's original progression gate; the connected paths and save outcomes are never rewritten.
### Living world layer

After the final epilogue, the currently implemented areas gain a repeatable 24-minute world schedule. This is *not* used during scripted investigations. Newly illustrated 2.5D workers perform visible jobs and can be approached for fresh dialogue in every existing connected area: mango-grove trail and school stewardship (Night 2), waymark and bamboo upkeep (Night 3), wake-house community care and repairs (Night 4), crops and livestock work outside the unsafe barn (Night 5), and the riverside/archival repairs or fishing, depending on ending safety (Night 6). Night 7 has memorial-care and trail-maintenance NPCs. Night 1 has a second animated river banca, real dock nets/baskets, market garden produce, working residents, and named Dado/Sabel/Mara/Lola daytime routines. Workers withdraw by night and the real residential windows glow. Three new illustrated resident sprites avoid reusing the principal witness faces for ambient workers.

Postgame revisits no longer reopen old ending popups. All Night 1–6 touch action placements remain unchanged. Named witnesses' postgame dialogue respects Dado's choice to decline testimony and Sabel's public-remembrance consent from the Night 6 save. A partial/retreat/contain outcome keeps the settlement in a *healing* state: the river boat remains moored, dangerous crossing work stays cautious, and unfinished repair jobs remain visible. Visual props are non-colliding and cannot cut the public path.

Test coverage: `tests/postgame_clock_test.gd`, `tests/postgame_residents_test.gd`, `tests/night07_state_test.gd`, `tests/night07_scene_test.gd`, and `tests/night07_connected_playthrough_test.gd`, plus previous chapter regressions. **QA status depends on the latest GitHub Actions commit.** Automated tests do not prove detailed phone-performance, visual approval, or commercial release readiness.

- The definitive Night 7 epilogue calls `ConnectedWorld.note_outcome(7, final_outcome)`, then `ConnectedWorld.finish_epilogue()`, then `PostgameClock.refresh()`. Intermediate trial stones and outcomes **do not** start the automatic clock.
- Visual QA, performance and the full spectrum of seven-night player choices still need physical-phone evaluation. The basic postgame world/activity system is playable but not a promise of a finished commercial art release.

## Test and release status

Nights 1–7 form an **engineering QA baseline**, not a finished commercial release. The newest Night 7 adds real-scene, story-state, connected-travel and epilogue tests. Android debug APK export and emulator launch remain mandatory checks before merging to main. Check the latest relevant Godot validation and Android emulator runs in GitHub Actions before calling a change release-ready.

**Official signed Android release workflow is now prepared**, separate from the temporary-signed QA builds. Real-device comfort/performance/heat, all endings played by humans, and final character-art approval remain acceptance checks before marking a broad commercial release. Do not call a GitHub debug artifact an official release. A production APK is emitted only after the permanent signing Secrets are configured and the signed-APK emulator gate passes. Earlier temporary debug signing cannot be upgraded in place using the new release key; back up saves before uninstalling.

## Development direction

Build each night on a separate PR, following Final Master Script & Development Plan v1.0 (14 November 2026). Do not change canon, previous outcomes, shared touch controls, or the established art/HUD system. Night 5 uses Sigbin's shadow logic, missing goats and a rescue of farm animals without turning the folklore witness into a generic enemy. Night 6 implementation is a connected and source-backed river history chapter, not a generic monster duel. Finish Night 7 mobile, readability, accessibility and all-outcome reviews before marking the game release-ready.

CI: https://github.com/LokiJ07/Tabi-tabi/actions


## Official signed Android release (no debug APK)

- The only official pipeline is [Signed Android release APK](.github/workflows/android-release.yml), launched via **GitHub Actions → Signed Android release APK → Run workflow**, on the **main** branch.
- The branch `main` includes the verified Night 3 physical bridges, mobile touch/joystick fixes, named NPC/object prompts and improved walking motion from PR #27. Real seven-night Android evidence and 72 Godot checks passed before integration.
- The release workflow strictly uses `godot --headless --export-release`, confirms an Android signature via `apksigner`, rejects `application-debuggable`, verifies ARM64 support and the preserved Android ID `org.tabitabi.nightone`, installs the exact signed APK on Android 35 emulator, and **only after that** publishes a tagged GitHub Release with APK and SHA256 checksum.
- The signing key must remain **permanent** and **private**. Never commit a keystore (JKS/PKCS12), base64 key or signing password. Keep secure offline backups so that later signed APKs update in place.

### One-time GitHub secrets (required before the workflow can publish)

Open repository **Settings → Secrets and variables → Actions → New repository secret**, and create these three names with the private values from the release signing kit:
  1. `TABITABI_KEYSTORE_BASE64` — exact base64 of the dedicated Tabi-tabi PKCS12 release keystore, with no extra whitespace.
  2. `TABITABI_KEYSTORE_PASSWORD` — permanent keystore password.
  3. `TABITABI_KEY_ALIAS` — key alias `tabitabi`.

No signing passwords or keystore contents belong in this repository. The job intentionally fails if ANY secret is missing; it never invents or falls back to a throwaway signature.

After configuring the secrets, choose version `1.0.0-rc.1` for the first production-signed release candidate, with `publish=true`. GitHub Actions produces the genuine **non-debuggable, release-signed APK** and the GitHub Release entry only after APK verification and live Android startup smoke pass. Once real-phone acceptance is complete, choose `1.0.0` with the **same** signing key. Never reuse a version to overwrite the issued APK.

**Existing saves and updates:** the package ID stays `org.tabitabi.nightone`, but previously delivered CI debug APKs are each signed with *different temporary keys*. Android will not let the first official APK replace them as an update. Back up important saves before uninstalling the debug build. All later official releases reuse the one permanent release key.
