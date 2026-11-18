# Tabi-tabi — Pre-finalization QA audit (2026-11-18)

This is a **pre-final engineering checkpoint, not a public release sign-off**. Review seven connected Godot Android chapters using actual Android emulator screenshot archives, Night 1 shared HUD contract, world ledger and all individual scene/state tests. Do not present AI concept/mockup images as actual screenshots.

## Per-night audit

| Night | Regression target | Pre-final changes |
| --- | --- | --- |
| 1 Santelmo | Actual shore, dock, light, investigation notebook, day/night, save | Standardized displayed heading to NIGHT 1 / SANTELMO; protected Night 1 HUD contract |
| 2 Kapre | Mango tree/hut, witness path, route and physical return | Retain successful environment, scene and HUD regressions, no arbitrary redesign |
| 3 Tikbalang | Ridge/watchpost, clues, encounter, return path | Retain tested scene, physical path and dialogue |
| 4 The Wake | Family witness/privacy, night lighting, NPC retreat indoors, connected gate | Retain wake scene tests, motion and shared controls |
| 5 Sigbin | Animal fence, safe receiving pen, farm road, Sigbin behavior | Relocated gate sign away from right-side HUD; only show gate and receiving score when near their physical destinations |
| 6 River's Grief | Three historical reconstructions, privacy, safe stones, rising river, reversible findings | Preserve story, save, scene, bridge and regression tests |
| 7 Balete Grounds | Final notebook, community memory, Keeper root/truth phases, four endings, voluntary epilogue | Replaced radial spokes/mannequin with branching buttress roots and bark/aerial canopy; disallowed unrevealed root shortcuts; secured Keeper gate before reveal; recover off-path older saves |

## Automatic evidence versus actual gameplay

- Green Godot CI covers code, state, scripted interactions, save files and ledgers. Android emulator CI opens and captures individual chapter scenes with DEBUG QA camera keys, not a human's unbroken seven-night playthrough.
- Known emulator issue: x86_64 SwiftShader OpenGL Compatibility logs "SceneShaderGLES3: Program linking failed: Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)". Captured gameplay continues to render. See https://github.com/godotengine/godot/issues/109550 for maintainers' discussion of this SwiftShader implementation issue. Do not claim a fully error-free renderer or presume a physical handset shares it.
- Not verified yet: real-device performance and FPS, heat, cross-version debug/production signing, font scaling on small screens, actual player traversal and cultural usability review. Debug APK signatures can prevent upgrades and threaten save preservation if users uninstall first.

## Required gate for finalization

1. At least two successful Godot validation runs on the exact head commit, plus a successful Android APK export AND full Nights 1–7 emulator screenshots for that commit.
2. Manually inspect latest screenshots: Night 5 sign text does not sit behind SAVE/RETRY/LOOK; Night 7 roots no longer resemble straight wheel spokes, Keeper is visible, no dark terrain wedge, roads look contiguous.
3. Prove that Night 1–6 saves remain unchanged by entering Night 7; preserve older saves on updates and check JSON backup fallbacks and failed writes.
4. Perform one organic seven-night story playthrough on a real Android phone without DEBUG camera shortcuts. Review checkpoints, player choices, return roads, fair root timing and all four finale outcomes.
5. Verify full-screen touch usability, text scaling, reduced-motion, options, sound and no floating NPCs at midnight.
6. Validate stable APK signing, update path and portable backup before a public release.
7. Keep Night 7 PR #16 in DRAFT pending latest CI screenshots and real-phone sign-off. Current work should be followed by final visual/gameplay QA rather than another redesign.

## Status

All code changes are applied on the Night 7 feature branch, not main. The final merge/release decision remains separate from this pre-final audit.
