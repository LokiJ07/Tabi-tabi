# TABI-TABI Development Status

## G0 / G1 — Early prototype

**Implemented (not yet run on real Android):** Godot 4 project, initial 3D blockout of Barrio Lawom, third-person orthographic isometric camera, keyboard and prototype touch button movement, static world collisions, a following Bantay placeholder, two NPC interactions, daytime/nighttime toggle, lantern light and Santelmo visual placeholder. CI workflow added for import/scene smoke checks.

**Not implemented:** authored character models and animation, actual Santelmo encounter AI and deterministic puzzles, notebook/evidence linking, save/profile system, narrative branching/outcomes, polished NPC schedules, localization, in-game audio, Android export templates/signing, performance validation and any completed vertical slice.

### Scope discipline

This prototype uses primitives intentionally as a temporary engineering spike; they are not the approved Cinematic Painterly 3D art. It is not a claim of G1 completion until CI, Android deployment, and touch feel are verified. Do not mark Night 1 complete or proceed to Night 2 until G6's real-device and gameplay criteria pass.

### Controls

Desktop: Arrow keys to move; Enter to interact/close dialogue; Escape to dismiss. Android prototype: on-screen directional buttons, INTERACT, DAY / NIGHT. Buttons currently use fixed 1280x720 layout and must be made adaptive before G1 acceptance.

### Next engineering priorities

- Confirm Godot resource import and runtime in GitHub Actions.
- Improve mobile HUD anchoring, Focus lantern and movement fidelity.
- Implement collision-safe riverbank/navigation and Bantay pathfinding.
- Replace placeholder environment and NPCs with approved rigged/animated art.
- Implement clue notebook and save contracts for the complete Night 1 vertical slice.
