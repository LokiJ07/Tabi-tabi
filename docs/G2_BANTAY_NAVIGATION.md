# G2.1 — Bantay navigation and collision safety

This iteration replaces Bantay's obstacle-ignoring positional follow with a collision-aware **CharacterBody3D**, a conservative route grid and waypoint steering. The guide avoids the three house footprints and several trunks, and never treats river cells as walkable. A low-frequency route recomputation helps mobile performance.

The physical riverbank fence spans the full playfield, while collision-only perimeter walls stop accidental exits from the current blockout. Bantay has a physical capsule, so solid geometry can prevent it from stepping through obstacles. There are no teleport shortcuts or scripted no-clip recovery moves.

## Safety and testing

- An automated test checks all three buildings, river exclusion, tree avoidance and a navigable route around Lola's house and toward the mooring.
- Conservatively blocked goal points are projected to the nearest safe grid cell. Far out-of-bounds targets are rejected.
- Route pathfinding is an early blockout-specific grid, **not production navmesh**.
- Re-path frequency: 0.45 seconds; future development should add stuck detection, richer local avoidance, door handling, accessible bridge/landing paths, dog sit/wait commands, and real device tests.
- The existing three-stage Santelmo encounter and prototype story-state tests remain separate checks.
