# TABI-TABI — Nights 1–7 Visual & Fear Design Bible v1

**Status:** The implementation in this branch is an Android QA standard, not an unconditional release sign-off. Nights 1–2 are the reference chapters. No Night 3 asset, HUD or story production may silently fork these rules.

## Shared look (implementation contract)

- **Visual language:** grounded Philippine storybook/isometric 2.5D with readable perspective, front and side walls, connected roofs, thresholds and terrain, original illustrated actors. No giant flat facade overlays.
- **Touch HUD:** `scripts/ui/shared_hud.gd` is authoritative. Four fixed-position left thumb arrows; fixed right-side ACTION positions, one OPTIONS corner; same dark navy/gold/cream controls and dedicated status panel. Night 1 uses FIELD NOTES; Night 2 uses FIELD NOTES. Chapter-specific interactions may replace labels in a fixed slot, but cannot shift other controls. Always keep the center playfield unobstructed.
- **Status panel:** occupies 37% of reference viewport width at upper left; scale text rather than use absolute giant cards. Objective and nearby prompt must never overlap. Night 2 waypoint lives in its own top-center zone.
- **Atmosphere:** `scripts/visuals/shared_immersive_atmosphere.gd` supplies a subtle peripheral vignette that grows with **actual threat**; no random flashing. Night 1 uses sparse storm/rain and river sound; Night 2 uses low drifting fog, tree creak and night insects. All gameplay controls live in a layer above the atmospheric effects. Reduced-motion setting disables animated motion.
- **Audio:** original offline synthesis, with existing audio preferences respected. Only real in-game fear state drives a quiet low-frequency pressure pulse. Dialogue must not drain player courage.
- **Dialogue/notebook:** legible, scrollable, and modal; releasing every touch/observe input when opened. Scene and HUD remain readable during dialogue.
- **Folklore:** Kapre resident stays hidden by day, preceded by night smoke and ember; then appears perched on ancient mango branch after respectful observation. It is a cultural witness, not a generic boss to kill. Dangerous real-world roots/routes still require expert assessment.
- **Story:** Night 1 Santelmo -> walkable Barrio Lawom northern trail -> Night 2 Old Mango. Preserve separate checkpoint/save schemas and explicit safe-retry/withdrawal. Night 3 must continue the same canonical story, not start an unrelated game.

## No cheap fear tricks

1. Let the player discover an environmental clue before escalating the threat.
2. Give an audible and visual warning (Bantay reaction, smoke, creak, shifting shadows) before any penalty.
3. Use scene timing and real consequences rather than repeated artificial jumpscares.
4. Keep fear readable at phone size, 16:9 and wider, with text-scale and reduced-motion options.
5. Never hide a hazard behind HUD, fog, black grading or a scripted camera shake.
6. An encounter ends with a meaningful decision; safer choices do not require violence.

## Required acceptance before starting Night 3

- All headless Godot import, narrative, interaction, cross-chapter saves and UI tests pass.
- Android APK can be built and signed, installed on emulator, opened, and captured at Night 1 shoreline/night and Night 2 day/dusk/night; no GDScript crash.
- Visual side-by-side review of *actual gameplay* screenshots: HUD placement, silhouette/roof integration, creature feet/branch contact, no clipped text, no popup covering objectives.
- Real-device landscape touch testing and full uncoached playthrough of both nights, including pause/resume, return trail, every ending and performance/thermal observations. CI is not a substitute for this sign-off.
- Once that gate passes, Night 3 **imports the existing shared HUD and suspense layer**, reuses the same art perspective and typography, and only creates new folklore environments, tasks and creatures.

## Known gap

The new perched Kapre SVG is a hand-authored QA sprite, not fully rigged animation. Night 1 native 3D and Night 2 perspective-drawn 2D remain different renderer architectures, though they now share HUD, typography and atmospheric controls. This is not a claim of production-quality photorealism or a complete studio-grade animation pass.
