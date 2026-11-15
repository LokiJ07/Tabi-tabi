# G5 Night 1 — cinematic conversation & visual-identity implementation

This pass implements real Godot features on `feature/night1-foundation`, but it is **not** final movie-quality art.

## Distinct people in the playable world

Each named character now has its own procedural character identity, silhouette, clothing palette, signature headwear/accessories and face details. Lola Pasing has a shawl, skirt and silver bun; Tatay Dado has a woven fishing hat, vest, rope and moustache; Teacher Mara has spectacles, collar, tied hair and a ledger; Aling Sabel has an indigo headwrap, apron and market details; Apprentice retains the salakot and now has a notebook satchel. The Lola interior model uses the same identity as Lola's exterior appearance. All props are named for regression tests and eventual asset replacement.

## Head-to-shoulder cinematic conversations

- Dialogue is no longer only a generic centered text box. A distinct illustrated **bust portrait** is displayed beside the speaker name and text, in a wide on-screen story overlay.
- The bust palette and key features are drawn from the same canonical character identity data as the 3D model, so portrait and in-world NPC do not contradict one another.
- Multiple speakers in one scene are separated into pages. Continue/Interact changes the portrait and name, and the last page closes the overlay.
- Unattributed narrative is identified as Barrio Lawom, rather than incorrectly displaying a random NPC.
- The gameplay world remains visible behind the dialogue (lighter scene shade than full Notebook); movement/Focus remain paused while reading.
- The illustrated portraits breathe very gently; Reduced Motion disables the continuous portrait animation and screen fade.
- Portraits are original drawing commands, offline, and do not require heavyweight extra 3D render passes.

## Visual storytelling details

- Individual roof silhouettes and recognizable features at Lola's home, Sabel's store and Mara's school.
- Safe mooring details, weathered timber/rope, fishing objects, market goods, woven baskets, reed clusters and low-range lantern posts.
- Details are visual-only and do not create collision blockers or change Night 1 puzzle logic.
- Installation is idempotent; repeated setup cannot duplicate props.

## Quality limits before full Night 1 release

The current code assets are still **stylized procedural artwork**, not authored full-resolution rigged GLB characters, motion-captured acting, final painterly textures, or a complete cutscene camera timeline. These should be swapped in and reviewed on an actual Android phone for emotional expressiveness, readability, sound, frame rate and story integrity before Night 2. The newly added tests certify logic/render-tree integration, not that final cinematic standard.
