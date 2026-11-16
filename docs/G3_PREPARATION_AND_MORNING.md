# G3/Sprint C — Four-slot night preparation

This pass implements four selectable active supplies (six available) for Night 1 and persists them with canonical state.

- Items: cloth wrap, signal bell, water flask, rope, spare wick and Bantay snack.
- Equipment is changed only during day/preparation, never mid-encounter. Four items must be equipped to switch into night.
- Default four selections preserve playable migration from earlier saves, while the player can customize four slots at any time before night.
- Cloth wrap gives one finite calm-use in the first Santelmo phase; the engine's reactive creature alarm is kept in sync.
- A prepared signal bell is required for Drive Away. Players lacking it may still achieve Resolve or Partial, so there is no irreversible softlock.
- Equipment choices and one-use state survive save/reload. Checkpoint retry restores the last legitimate snapshot.
- Dado and Sabel have outcome-aware morning lines to make the chosen encounter resolution visible in human testimony.

Quality note: additional equipment utility, authored visual props, inventory icon art, Courage, preparation tutorial and device acceptance are still missing. These are safe, nonmagical placeholder supplies pending cultural review.
