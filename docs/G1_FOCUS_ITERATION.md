# Night 1 G1.1 — Focus and mobile HUD iteration

This branch remains a **prototype**, not a finished encounter or Android release.

## Implemented in this increment
- Added an on-screen hold-to-focus control and desktop Tab key handling.
- Movement direction and lamp aiming are independent while Focus is held.
- Santelmo visual placeholder now reacts deterministically to sustained close directional attention; alarm builds and decays, with a visible warning.
- Directional, Focus, Interact, and Day/Night controls anchor to bottom screen corners for wider landscape viewports.
- Dialogue anchors near the bottom center.

## Explicit remaining limitations
- Focus currently automatically tracks Santelmo when held; independent right-thumb free-angle aim still needs an actual drag pad.
- The alarm does not yet drive retreat, failure or the three-stage encounter.
- No validated Android export, no run-time mobile device verification, no notebook or saving.
- The stage still uses primitive meshes, fixed text sizes, placeholder NPC interactions and a non-navigating Bantay follower.
- Different notched phone safe areas and unusually narrow aspect ratios need validation.

## CI
GitHub headless resource import and runtime smoke test must pass on this commit before calling even this prototype valid.
