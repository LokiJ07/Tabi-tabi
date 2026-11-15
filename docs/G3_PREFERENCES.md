# G3/Sprint C — Offline accessibility settings (first functional pass)

This pass adds a separate settings panel and persistent preferences independent of canonical Night 1 save data.

Currently functional:
- Text scaling in three steps (100%, 120%, 140%) on key HUD labels, dialogue, notebook and preparation summary.
- High-contrast text with dark outlines on key readable labels.
- Reduced motion: faster camera positioning and removal of animated river color shimmer.
- Three levels of optional **manual** reflection hints (subtle, guided, full); no settings choice changes canonical evidence or ending.
- Settings are saved locally, recovered from backup if primary is corrupted and need no account or internet.

Pending: actual language switching, localized assets, remappable HUD, sound/mute settings once real audio is added, safe-area profiling, actual device testing of enlarged overlays. We must not label unfinished localization controls as working.