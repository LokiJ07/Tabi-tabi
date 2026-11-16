# HUD + 2.5D houses — visual quality gate

This branch is based on `feature/night2-kapre`; it does not change the seven-night master story, travel trigger, checkpoint schema, or collision boundaries.

## Root causes corrected

- Night 2 used a separate percent-based HUD with different thumb and action locations. Both Night 1 and Night 2 now read `scripts/ui/shared_hud.gd` for the same gold/navy action theme and bottom-corner placements.
- Night 2's previous houses drew a standalone facade rectangle beneath a triangular roof (flat front pasted on the scene). `_building_at` now constructs an isometric footprint, front/side walls, correct roof planes, supports, stairs, window, door, and special detail. Imported bamboo and thatch art is UV-mapped to the *angled architectural faces*.
- Night 1's 3D building roofs were sloping down towards the ridge (the rotation sign was backwards); the slopes now rise to the central ridge, with a dedicated ridge beam and ground-connected steps.
- Night 1's old full-size flat facade Sprite3Ds were covering its real doors, windows, and structural walls. The decorative world no longer attaches them.
- Software fallback retains the same 3D-projected door/window surfaces, with no full-size pasted facade.
- Night 2's gameplay controls are hidden while reading dialogue or opening menus, and held movement/observe input is cleared.

## Validation requirements

1. Import scripts in Godot 4.3 without parse errors, run regression tests from `godot-validation.yml`, including `tests/night01_illustrated_art_test.gd`, `tests/night01_world_cohesion_test.gd` and `tests/night02_scene_test.gd`.
2. Export the Android debug APK with `android-debug.yml`; inspect emulator screenshots from the first chapter and old mango chapter, not merely build success.
3. Inspect actual Android landscape play: corner controls keep the same location, readable sizes and no input leakage under notebook/dialogue.
4. Confirm Lola/Sabel/Mara's houses have connected roof/wall/porch silhouettes in native and fallback renderers; confirm Night 2's school and shelter have visible front/side wall depth.
5. Night 2 continues using an isometric *CanvasItem* scene for renderer compatibility, but the buildings themselves are geometry-based 2.5D drawings rather than flat sprites. This does not claim the chapter has been ported to a true 3D camera.

**Merge gate:** CI passing is necessary but not proof of visual quality. Review screenshots and physical device results before merging into a shared release branch.
