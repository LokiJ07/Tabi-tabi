# Tabi-Tabi Nights 1–3 — Shared 2.5D production rendering pass

Branch: `feature/nights1-3-dimensional-art-pass`, based on a verified green Night 3 CI commit.

## Actual game integration

- Night 1 native: authored SVG characters are mounted in the true 3D world as Y-axis billboard planes. A separate darker 3D silhouette plane and horizontal mesh contact shadow now give actors depth while preserving character collision, animation, and save identity.
- Night 1 software renderer: the existing live scene, not a video or static concept screenshot, now uses the shared ground-shadow/silhouette renderer for moving NPCs, Bantay, flora and village props.
- Night 2 Kapre: grove trees, mango, lantern, Kapre, moving hero and Bantay use one CanvasItem 2.5D renderer, with ground occlusion and shallow relief. Time-of-day grade occurs *before* visible actors, so faces are readable; the supporting branch remains in front of the Kapre.
- Night 3 Tikbalang: bamboo clusters, physical watchpost, lantern, Tikbalang and following characters use the same system. The verified ridge encounter framing is kept.
- Character movement has a subtle non-blocking foot-grounded bob; Reduced Motion disables bob. No HUD coordinates, evidence zones, routes or story flags changed.
- Existing original SVG sprite identities remain consistent between all chapters.

## Limitations and acceptance

The three generated cinematic screenshots are visual direction references, **not** runtime frames or imported interactive sprite layers. This pass improves dimensionality of existing authored game art; a scene-by-scene paint-over / rigged character art production pass is still needed to reach the cinematic concept look. Do not present this as a fully rigged 3D game.

A green CI validates import, gameplay state, scene logic, APK export and emulator launch, not texture quality on every phone. Inspect actual emulator screenshots and do a physical landscape Android playtest before production merging.
