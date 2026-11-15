# G4 end-to-end Night 1 integration contract

Automated flow from a clean offline save:

1. Spawn the actual main scene and validate all interactive objects were instantiated.
2. Visit Lola, Dado, the old mooring and Mara at their actual positions.
3. Connect both required notebook clues.
4. Enter night with four active items, begin phase 1.
5. In phase 2, use the correct world-space reflection location.
6. Commit Resolve or Drive Away, and separately take Partial from phase 1.
7. Confirm a unique visible morning-world artifact, exactly one committed event and persistence through offline save/reload.
8. Wipe isolated test save between outcomes.

These automated steps are a regression gate; they do not prove realistic thumb controls, balanced pacing, collision-safe walking, beautiful animation or fun. The master script still requires real-device and uncoached player testing before Night 2.
