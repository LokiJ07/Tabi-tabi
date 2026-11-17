# Nights 1–4 — lived-in nighttime villages

Branch: feature/nighttime-lived-in-village-nights1-4. Based on Night 4 draft, not merged to main.

One shared module at scripts/visuals/nighttime_windows.gd supplies deterministic amber window glow, subtle fixed/reduced-motion candle shading, inner curtain silhouettes and low-alpha light spill. Schools are dimmer than occupied homes; a watchpost is a small shelter, not a whole village.

- Night 1: physical 3D window meshes emit light with two unshadowed Omni lamps. Software Android renders those same coordinates over the dark landscape. Idle villagers and named exterior people visually go indoors; original interaction markers remain.
- Night 2: refuge / school side-wall windows illuminate at night. Daytime Dado and Mara outdoor sprites disappear from late-night observation; hero, Bantay and Kapre encounter stay intact.
- Night 3: safe watchpost has warm lampara light at night. The ridge remains isolated; no invented villagers or new blockers.
- Night 4: the wake's front windows glow with inner silhouettes and soft amber ground reflections. Nena, Sabel and Mara are indoors at night; their dialogue, defense, clue states and saves remain. Dim rear window reinforces the unsafe entrance.

This code does not modify progression schema, collisions, shared gold/navy HUD positions, save files or Night 1–4 story outcomes. Green CI is a technical checkpoint only; final visual approval and real-phone playtest remain separate.
