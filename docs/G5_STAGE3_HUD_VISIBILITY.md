# G5 — Night 1 Stage 3 Screenshot Fix (2026-11-15)

## Reported on Android

The supplied real-phone image shows objective text physically overlapping Santelmo alarm, CLUES/PHASE/GUIDE and Courage counters in the top-left. The independent interaction prompt `INTERACT • OLD MOORING` collides with that text block. The small green landing ring is hard to identify at night; `GUIDE TO SHORE` looks like a one-tap action although actual gameplay requires staying near the ring while holding Focus toward shore.

## Implemented
- A consolidated, high-contrast translucent top-left `QuestStatusCard` with a vertical `StatusRows` container replaces hard-coded Y slots. Status rows reflow with the accessibility font sizes. Empty alarm / courage / dog-warning entries hide instead of leaving gaps.
- Interaction prompt is assigned its own top-right zone, safely separated from the quest card and Options button.
- Stage 1/2/3 objectives are shorter but preserve the actual clue and guiding requirements. Stage 3 uses the clear sequence `GREEN ring → HOLD FOCUS → aim toward SHORE`.
- The misleading Stage 3 action label changes from `GUIDE TO SHORE` (looks like an action) to `HOW TO GUIDE` (an explanation). `REMEMBER` still appears when in-world guidance reaches 100%.
- Enlarged bright green landing disk, elevated pulsing marker and low-range green light. This is a visual-only accessibility aid, remains hidden until Stage 3, and does **not** alter encounter logic, success requirements or save data.
- Added automated scene-level HUD regression for exactly these labels, panel hierarchy, top-right prompt separation, text scaling, and safe marker visibility.

## Remaining verification

Godot headless test and Android APK export establish functional integration, not readability on every physical phone. Verify on the test phone with 100/120/140% text and confirm the player can see GREEN target against night illumination. Do not infer GPU compatibility from SwiftShader emulator's blank 3D surface.
