# NIGHT 1 — Approved Art Guide Integration Pass

This is a **real repository/game implementation**, not a concept-only render.

## Original art included in shipped game
- `assets/portraits/night01_art_guide_busts.jpg`: verified 1280 × 256 texture atlas, five distinct head/shoulder crops sourced from the user's existing 1672 × 941 Night 1 art guide image. Dado, Mara, Sabel, Lola and Apprentice use distinct 256 × 256 regions, named deterministically in `SpeakerPortrait.atlas_region`.
- The game now draws these textures directly in dialogue overlays with an accent border; narrator, Santelmo and Bantay retain purpose-built illustrations. There is no runtime download and no generic person portrait for objects.
- Original art reference has sufficient quality for dialogue at 225 px per portrait; it is not falsely described as a rigged 3D character replacement.

## The physical Night 1 world
- `scripts/world/mangrove.gd`: shoreline trees replaced with eight **recognizable mangrove** meshes with asymmetric leaf clusters, branches, gnarled stems and six splayed prop-root systems each. Trees remain visual-only, safely placed on the water side of the river safety boundary.
- `scripts/world/barrio_details.gd`: nipa houses/school/store acquire woven bamboo facade strips, roof-thatch layer tiles, open shutters, clearer porch floorboards and culturally grounded shore details already present. These are separate authored scene nodes, not one flattened image in the place of navigation.
- Real boats and evidence placement remain intact and do not alter level collision, saves or story logic.

## Mobile art direction
- Shared navy teal/cream/gold button visual styling from the approved art guide on movement, Focus, interaction, Notebook, options, Save/Retry and story choices. Both pressed and released states remain readable.
- Dialog and large menus share warm-gold borders/contrasts; text is still Godot dynamic text, not baked in a picture.
- Focus pressed indicator retains explicit words and gold active border.

## Limits and QA
- There is **not** a fully rigged GLB replacement for each NPC and the riverside world is still lightweight 3D with 2.5D illustrated portrait UI. The new art is real in-game texture and new scene geometry rather than a Photoshop screenshot background.
- CI gates include exact portrait atlas dimensions, separate NPC art mapping, mangrove and nipa geometry, button style, previously fixed gameplay and save tests, then signed Android APK export.
- Actual in-person Android GPU/FPS, world composition and narrative pacing still require physical device inspection before declaring Night 1 ready for public release and authoring Night 2.
