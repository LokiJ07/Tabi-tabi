# Night 4 — creature presentation QA

Target: show the full creature clearly **while keeping the player, Bantay, house, warning cues and gameplay HUD in view**. The chapter remains on its own draft branch.

- Enlarged original 2.5D vector three-piece creature (382 × 314 world pixels).
- Draws more vein/rib texture on the independent wing layers; slightly asymmetric flapping, subtle torso banking, translucent wind traces and moving wing shadow. All procedural effects freeze under Reduced Motion.
- Rooftop approach descends towards the front roof edge, closer to the protected courtyard. Rear-window and courtyard warning directions are unchanged.
- World camera retains automatic fitting using the actual Godot logical viewport, including a more conservative allowance for rotated outer wing tips.
- Added Godot screenshot-bound and wing-phase unit assertions, and **two live Android emulator frames** of the creature, separated by two seconds.

Not altered: all seven-night planned canon, investigative clues, private witness dignity, 3 group-defense phases, night ambient windows, in-game HUD/save schema and main branch. CI checks parse, gameplay, signed Android build, actual scene launch and frame progression. Physical handset validation is still required before main release.
