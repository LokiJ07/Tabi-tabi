# Tabi-tabi — Night 1 Final Polish Gate
> Updated 2026-11-15 · Work on `feature/night1-foundation` only. No merge to `main` and **no Night 2 production** before the acceptance criteria below are evidenced in actual Android gameplay.

## Mission and art direction
**Original 2.5D illustrated Philippine coastal barangay**. Recognizably a living Visayan waterside village, not generic tropical RPG scenery and not a handful of procedural boxes. Maintain a consistent isometric camera and one believable coordinate system across real Godot geometry and the SwiftShader CanvasItem fallback. The main experience should be investigative, atmospheric and readable on a mid-range phone.

**Design pillars:** coherent nipa architecture; a lived-in brackish river estuary with only genuine mangroves at the water; intimate human-scale village paths; warm daylight and lantern-lit folklore night; clear investigative cues; modestly expressive Apprentice/Bantay/witnesses; unobstructed interactive controls. Do not produce standalone concept art as a substitute for integrating source assets into live Godot scenes.

## Current engineering fixes (implemented, must still be visually reviewed)
- **Retired three opaque blockout houses and flat roof meshes** while preserving existing tested colliders: `scripts/main.gd::_house`; authored nipa/store/school structures are in `scripts/world/barrio_details.gd`.
- **Dock connects shore to water:** the extension covers x about -12.05 to -5.05 around z=9; visible planks, rails and vertical supports, with no altered witness or mooring interaction points.
- **Banca really floats in the river** at roughly (-13, 0.15, 9), both outriggers west of the dry-land boundary; the fallback projects the actual craft node.
- **Tidal transition** uses three irregular terrain strips, not a ruler-straight green/teal seam; both native and software scenes agree on the edge profile.
- **Lola hut cutaway** keeps its walls/exit physics but opens the camera side; bamboo floor, sawali panels, mat, desk, notebook, breakfast table, family portrait and steps correspond to the same world positions.
- **Game options** now contain safe, confirmable **SAVE & MAIN MENU** and **QUIT GAME**, both save before navigation; save failure retains gameplay.
- Existing role-specific portrait/sprite assets, title, loading state, local saves, narrator/cinematic camera and the Santelmo encounter remain; don't remove tested gameplay to prettify screenshots.

## A. Riverside estuary / boat landing — REQUIRED
- [ ] Visible coherent water → mud flats → sandy bank → village land gradient along the full reachable shoreline; no straight rectangle transition, floating strips, gaps or surface flicker.
- [ ] Mangroves genuinely rooted at brackish tidal positions, with visible prop roots; no ordinary mainland trees placed directly in tidal water or on investigation paths.
- [ ] Connected timber dock can be identified from above and visibly reaches the banca. Fishing gear and old mooring belong to the landing; boat and outriggers must sit in water.
- [ ] No shore art covers Dado, mooring clue, safe route marker, Santelmo puzzle sightline, village path, or player's character.
- [ ] Daylight and Night 1 lantern lighting make the same locations readable; no fully flat blank backdrop, popups or cloud of duplicate trees.

## B. Three village landmarks — REQUIRED
- [ ] Lola's home, Sabel's store and Mara's school each have one believable roof silhouette and their own recognizable door/window/porch features.
- [ ] No opaque prototype cube, duplicate false front or roof plane pokes through any illustrated facade.
- [ ] Character eye-line, footing and location markers agree with the building's visual door and steps.
- [ ] Main path has a natural bend but remains comfortably walkable; no NPCs, floating signs or screen-space labels obstruct gameplay.
- [ ] Furniture, baskets, woven fences and vegetation must follow a coherent scale; no large unrelated stock art pasted above roofs.

## C. Lola hut inside and outside — REQUIRED
- [ ] Room is a **single readable cutaway**: rear/side walls and bamboo floor, open camera-facing edges, real steps and a plausible exit. No brown floating box in cyan sky.
- [ ] Blue notebook visibly placed on the **writing desk**, warm cup on the **breakfast table**, photo on rear wall. Touch/nearby interaction target matches the displayed object.
- [ ] Lola, Apprentice and Bantay remain distinguishable on a small phone; no characters buried in props or hidden by walls.
- [ ] The dialogue camera can move in, then restore a stable whole-room exploration view.
- [ ] Player can inspect the two mandatory prologue objects, interact with Lola, leave, and reenter without softlock or story loss.

## D. UI, navigation, dialogue and accessibility — REQUIRED
- [ ] Title screen has usable Start / Continue / Settings / Credits / Exit; continue disabled only when no save exists.
- [ ] In-game **SAVE & MAIN MENU** and **QUIT GAME** are findable without scrolling past settings, confirm actions, save safely, and allow cancellation.
- [ ] Objective, dialogue, Choices and right-side action controls remain readable from 100–140% text size, across common landscape aspect ratios, and never cover essential interactions.
- [ ] Buttons have matching imported icons and large tap targets; large text is wrapped deliberately and never silently clipped.
- [ ] Notebook, preparation, story choices and settings are mutually exclusive overlays. Returning from modal restores touch movement without stuck Focus.
- [ ] Loading screen appears on transition and does not remain indefinitely or block the game.

## E. Technical QA gates — REQUIRED
- [x] Godot headless source import & full Night 1 gameplay regressions in `.github/workflows/godot-validation.yml`.
- [x] Android signed debug APK export and isolated emulator launch job in `.github/workflows/android-debug.yml`.
- [x] Structural test `tests/night01_world_cohesion_test.gd` verifies missing old house meshes, location of boat, shore strips, dock and intact collisions.
- [x] `tests/night01_navigation_test.gd` tests save/return and quit confirmation.
- [ ] Real-world screenshot validation after latest changes in **at least 6 distinct views**: daylight village, connected dock with boat, mangrove shore, Lola room, Night 1 river encounter, title/options.
- [ ] Actual Android hardware playthrough on mid-range hardware: Start → Lola notebook/cup → leave hut → witnesses/evidence → night Santelmo puzzle → one of three outcomes → morning/Continue.
- [ ] Confirm no fatal errors, missing imported textures, clipping, background cyan, shader fallback mismatch, inaccessible targets or obvious collision leaks.
- [ ] Compare each location visually to its expected composition; a *green CI status alone is not visual approval*. If screenshots are poor, hold the branch rather than declaring art complete.

## Production boundaries / next milestone
Do not start a broad Night 2 build until Night 1 has **(1) functional CI, (2) clear six-view Android evidence, (3) confirmed playable story loop, and (4) explicit visual signoff**. If issues remain, file them against these categories and fix them in the Night 1 branch. Only then merge to `main`, branch for Night 2, and preserve all story/evidence/save invariants.

### Direct code map
| Concern | Source |
|---|---|
| World placement / house blockouts / dock / boat | `scripts/main.gd` |
| Native nipa houses, store, school and props | `scripts/world/barrio_details.gd` |
| Native irregular shoreline, vegetation and path | `scripts/world/illustrated_barrio.gd` |
| Actual banca mesh | `scripts/world/river_banca.gd` |
| SwiftShader live 2.5D fallback | `scripts/visuals/software_world_fallback.gd` |
| Lola hut cutaway / clue targets | `scripts/world/lola_hut_interior.gd` |
| World composition regression | `tests/night01_world_cohesion_test.gd` |
| Save/quit regression | `tests/night01_navigation_test.gd` |
| Pixel-based Android smoke test | `.github/scripts/assert_gameplay_visible.py` |

**Definition of done:** A person seeing six actual, clean, coherent Android screenshots and playing Night 1 can independently understand the village geography and interact with every core clue. Art quality, not asset count, determines whether we proceed.
