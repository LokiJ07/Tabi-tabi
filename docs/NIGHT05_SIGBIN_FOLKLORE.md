# Night 5 Sigbin — regional folklore and game adaptation

**Interpretive warning:** The Sigbin is a folklore figure, not an established animal or supernatural fact. Cebuano, Hiligaynon, Leyte and Capiz accounts vary; do not collapse them into one unquestionable story.

## Source notes
- John U. Wolff, *A Dictionary of Cebuano Visayan* (1972), entry "sigbin": long hind legs, backward gaze/locomotion, concealment, inherited attachment to an owner. https://www.gutenberg.ph/previews/wolff/WCED-complete.pdf
- Maximo Ramos, *Creatures of Philippine Lower Mythology* (1990 ed.), descriptions of Visayan **segben**, cited in The Aswang Project sourced compendium: goatlike and hornless with huge clapping ears and a pungent odor; a Leyte recollection includes bleating and squash flowers. Related variants, NOT one universal Sigbin description. https://www.aswangproject.com/creatures-mythical-beings-philippine-folklore-mythology/
- Herminia Meñez (1996), José S. Buenconsejo (2002), and other regional narratives are listed in https://pantheon.org/articles/s/sigbin.html
- Folklore comparison and warning against accusing real families: https://www.ditosapilipinas.com/visayas/lifestyle-features/article/10/02/2026/sigbin-backward-walking-beast-visayan-folklore/3368

## Implemented interpretation
- Disproportionate hind legs, bent smaller forelegs, lowered head; articulated original ear SVG sprites.
- In-world backward retreat, reverse footprints, ear flaps, intermittent night concealment, Reduced Motion freeze.
- Scent notice / paired ear-claps / travel-direction evidence; quiet offline audio and sensory log in field notebook.
- Observe three sensory signals from the stable perimeter, then use original three lamps to help animals escape.
- Former caretaker's bond is only the game's narrative interpretation. Shadow danger is a fair *game puzzle*, not verified supernatural behavior.
- Never punish actual households, never accuse a resident of being aswang, never add child-harm imagery.

Godot checks and Android emulator actual screenshots are mandatory before approval. Physical-phone gameplay and visual sign-off remain required before Night 5 main merge.

## Visual iteration 2 — anatomical gait and ground contact

- Replaced upright rabbitlike ears with wide sideways creased ear folds and
  independent skull hinges. These are original game textures.
- The Sigbin torso SVG now excludes its former baked-in legs. Two near and two
  far limbs have animated knees, alternating hooves, subtle body movement and
  accurate depth layering in the Godot world.
- Backward walking follows a bounded, eased retreat, with a deliberate, slower
  forward scouting return. Reduced Motion freezes walking and clapping.
- Deterministic grass, soil flecks and the barn's cast shadow enrich the existing
  live farm without changing collision, evidence, saves, or HUD.
- Green CI verifies compilation and gameplay logic; actual Android screenshots
  plus physical-device visual feedback are required for quality sign-off.
