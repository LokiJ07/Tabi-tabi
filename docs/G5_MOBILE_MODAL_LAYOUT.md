# Night 1 mobile modal overlap fix

Reported from the actual Android screenshot (2026-11-15): the Field Notebook covered the walking controls and morning dialogue choices, with journal text spilling beyond a narrow panel; the Close Notebook button was buried below scrollable text.

## Applied UI changes
- A single topmost, viewport-relative modal layer darkens the 3D scene and catches touches.
- Opening any modal hides the entire gameplay HUD, including movement arrows, lantern Focus, action shortcuts, status text and narrative choice buttons. Closing restores the HUD without changing the saved story.
- Notebook occupies 80% of the viewport width and 89% of its height with an opaque high-contrast panel, readable margins, a fixed title, **bounded vertical scrolling**, and a **fixed, always reachable Close Notebook button outside the scroll**.
- Preparation and Settings use the same fixed footer and bounded scroll approach.
- Dialogue has a wide high-contrast panel, bounded scrolling, and a visible **Continue / Close** button so touch users never need to hit a now-hidden gameplay Interact button.
- Opening and closing any modal clears Focus and movement axes. All controls are restored only when no modal remains.
- Headless UI test covers modal states, nested scrolling, fixed footer buttons, hidden choice controls, input lock and restoring the ordinary HUD.

## Unverified until Android screenshot / playtesting
Readable text at 100/120/140%, button access on multiple landscape aspect ratios, and thumb feel must be verified in the next APK. No Night 1 G5/G6 signoff is implied.
