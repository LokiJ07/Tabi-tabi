# Night 1 mobile readability polish — device screenshots Nov 15 2026

User device screenshots showed the overlay collision fixed, but remaining severe usability issues:
- Preparation equipment text rendered very small, and completed chapter's disabled items looked almost invisible.
- Options rows were dim, small, and easy to mistake for static labels instead of actionable settings.
- Many dark rows were visually indistinct and the close footer had little emphasis.
- Notebook evidence and deductions were still quite small at default 100% scale.

## Changes
- Explicit Godot Button normal/hover/pressed/focus/disabled styles for notebook links, theories, preparation equipment, settings, water, and fixed footer buttons.
- Larger default button text (27 logical pixels, 25 footer), minimum 63 logical pixel touch-target height, and an accessible disabled font color.
- Left-aligned interactive settings/equipment text rather than small centered labels. Selected equipment/deductions have distinct green-bordered highlighting.
- Larger journal text (27 logical pixels), clear 30px modal headings and larger preparation status. All styles scale with existing 100/120/140% preference.
- Completed Night 1 explicitly labels equipment as LOCKED, making read-only behavior intentional rather than looking broken.
- Regression tests assert font sizes, minimum touch targets, disabled-state contrast, chapter lock messaging, and scale behavior.

## Validation boundary
Headless Godot tests and successful Android APK export are engineering gates. The physical Android screenshots must be retested for visually readable buttons and no clipping at 100–140%, especially for the longest equipment labels.
