# Night 1 mobile readability and modal interaction gate

This pass addresses a real-device usability gap identified from the early screenshot and master script acceptance criteria:

- The Notebook, Preparation and Settings panels now use viewport-relative vertical anchors and scroll containers instead of fixed-size content surfaces. Each allows its buttons and explanations to remain reachable at 140% text scale.
- Opening dialogue or another menu clears stale touch axes, ongoing Focus and aim gestures. While any blocking panel is visible, player motion input is suppressed so the avatar cannot inadvertently walk into a hazard while the user reads.
- Objective labels wrap instead of remaining one very long single line.
- The accessible interaction and keyboard escape behavior remains intact.
- Automated scene-level UI checks verify usable scroll parents, non-overlapping modal state, release of held movement input and text scaling.

Still requires visual verification on actual 16:9 and extra-wide Android screens. This is an engineering safety improvement, not the finished art direction or a substitute for real-device thumb testing.
