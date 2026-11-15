# TABI-TABI — Night 1 QA / Go–No-Go sheet

Based on the 14 November 2026 **Final Master Story Script & Development Plan v1.0**, pages 19–24. This is a release-candidate **engineering test plan**, not an assertion of final readiness.

## Automated engineering checks (required to pass)

- [x] Godot 4.3 resource import / parser validation and 20-frame scene smoke
- [x] Full in-engine scene test: hut prologue → witnesses → notebook links → Santelmo → each of the three outcomes → save/reload
- [x] Nonviolent guidance requires real world-space lantern aim and safe landing
- [x] Evidence confidence/source rules and one canonical bestiary entry
- [x] Four-slot equipment, Courage, finite-use items, safe checkpoint retry, older save migration and backup recovery
- [x] Keyboard/touch-blocking menus, scrollable notebook/dialogue/settings, subtitle size settings
- [x] Original low-cost offline sound generation plus Off / Quiet / Normal
- [x] Android debug APK export and signed package generation (previous CI)
- [ ] **NEW** Android manifest/signature/dual ABI verification and actual emulator APK launch (check latest workflow result)
- [ ] Stable release signing for updates without uninstalling — requires developer-kept credentials, not an exposed public key

## Mandatory actual Android quality signoff (not automated)

- [ ] Fresh install on a phone; no load failure or black screen
- [ ] Play P00_S01 hut, inspect notebook/cup/photo; exit house and return; camera does not clip walls
- [ ] Visit Dado, Mara, Sabel and mooring, revise one wrong private theory and link clues; can start night
- [ ] Select exactly four supplies; reach Santelmo; sustained Focus visibly warns and retreats; lower light to calm
- [ ] Solve false reflections without precision tapping; safely guide light to mooring; confirm no approach into river required
- [ ] Reach **Resolve**, then reload independent test saves for **Drive Away** and **Partial**; distinct aftermaths and no duplicate reward
- [ ] Interrupt/kill app and reload before/after encounter checkpoints; one canonical Bestiary result
- [ ] Test 100/120/140% text, contrast, no-fail, hint levels, audio OFF, narrow/wide landscape viewports
- [ ] Observe frame rate, heat, memory, camera and input responsivity for sustained play on a low/mid Android device
- [ ] At least one uncoached player completes Night 1; record confusion, puzzle fairness and emotional pacing
- [ ] Final animation, painterly scene/character models, creature VFX, cinematic sound and culturally reviewed dialogue replace placeholders

## Decision

**NO-GO to Night 2 unless all mandatory G5 and G6 gates above pass.** Passing the Android emulator launch is **not** the same as completing the chapter on a real phone. The master asks for actual animated gameplay capture, not screenshots alone.

## User playtest report (copy into GitHub issue or chat)

- Device / Android version / screen resolution:
- Install / open / offline behavior:
- Lola hut flow (works, problem, unclear moment):
- NPC interactions and Notebook readability:
- Lantern Focus / false reflections / guidance:
- Ending tested (Resolve / Drive Away / Partial):
- FPS or stutter / battery heat:
- Exact issue screenshot or timestamp / what you expected:
- Overall fun and pacing (1–10):
