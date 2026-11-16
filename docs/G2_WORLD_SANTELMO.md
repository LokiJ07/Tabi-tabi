# Night 1 G2 — World interaction and Santelmo visual iteration

This is an early **interactive encounter** iteration, still not a full vertical slice.

- Santelmo now physically drifts toward an authored safe retreat point when direct Focus is sustained, with color/brightness warnings. It calms when the beam is lowered.
- The reflection encounter now exposes two in-world, visible light markers. Players must move near a marker and choose INSPECT instead of selecting a known answer label. The correct reflection moves gently with the river; the false one jitters faster. Hint is optional.
- Two ambient residents have a lightweight, authored daytime walking rhythm and disappear for night. These are temporary non-rigged prototypes, not final believable NPC routines.
- Encounter phases now synchronize Santelmo's reflection visuals on transition, retry, and loading.
- Stage progress is automatically saved at encounter checkpoints; all committed outcomes still save exactly once.
- Santelmo model tests verify correct/false marker proximity, phase visibility and alarm behavior.

## Remaining

- Replace every prototype marker, resident and player capsule with artist-approved models and animations.
- Implement real river flow geometry, proper mooring/accessibility signage, finished reflection visuals, and reliable mobile camera/lantern presentation.
- The current near-reflection check is intentionally generous for touch; physical safe-route layout and position on the landing still need real-device playtesting.
- Add responsive environmental activity, Bantay navigation, production dialogue and sound, and actual cinematic pacing.
