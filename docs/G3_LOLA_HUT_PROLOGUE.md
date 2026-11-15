# Night 1 P00_S01 — first playable Lola-hut prologue

New games start INSIDE an authored temporary hut interior in a separate room from the street blockout. A teleport interaction connects the hut to the existing collidable exterior; the player cannot walk through the solid exterior walls. The interior contains a woven floor and walls, a breakfast table with pottery cup, a BLUE NOTEBOOK, a family river photo, Lola Pasing as a temporary NPC visual, a sleeping mat and warm light.

Prologue objective: explore and interact with the notebook and warm breakfast cup, then use HUT EXIT to reach the barrio. The family river photo and two morning dialogue tones are optional. Completing the prologue stores `prologue_flags` locally, and the exit does not open until the required notebook and cup are seen.

Controls: existing left-thumb movement and INTERACT still operate. All item prompts use the same deterministic horizontal proximity helper as the exterior witnesses. Bantay and camera move with the player on room transitions. Entry and exit never erase save, clues, or chapter outcome.

Backward compatibility: earlier prototype saves without `prologue_flags` are treated as having completed the introductory interaction, so existing players are not forced back to the morning tutorial.

**Prototype limitations:** separated room pocket, simple geometry, no rigged gesture/voice, no seamless walk-through door animation or roof fading; still requires a quality-first art/cinematic and real-phone validation pass.
