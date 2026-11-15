# G4 first playable pressure loop — Courage and Safe Retry

This pass introduces an explicit 0–100 Courage state for Night 1 instead of standard character HP.

- Sustained alarm above the telegraphed 60% threshold drains Courage; the player can recover naturally by easing the lamp.
- A prepared water flask is used once per encounter to restore Courage and reduce alarm, and this use persists through offline saves.
- Courage at zero enters a recoverable failure state where the player chooses RETRY (safe checkpoint) or ACCEPT PARTIAL. This does not kill the character or duplicate rewards.
- Offline STORY ASSIST / NO-FAIL prevents Courage dropping below 25 while keeping puzzle interactions.
- The player cannot arbitrarily toggle day/night during active encounter phases to reset pressure.
- Ten-second encounter autosaves preserve progress; checkpoint restore uses an earlier safe snapshot.
- Headless regression tests include failure, save/reload, retry, no-fail assist, water use and old-save migration.

Still missing: believable in-world failure cinematics, detailed Courage audio/visual telegraphs, item animation, real-device validation, and full authored encounter pacing.