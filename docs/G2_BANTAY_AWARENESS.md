# G2.2 — Bantay situational awareness

Bantay now gives short cooldown-protected warnings near the riverside and when the Santelmo becomes alarmed during Night 1. These warnings are visually communicated without sound and do not interrupt control, trigger repeated rewards or change canonical evidence flags.

Implemented as a testable deterministic awareness model, separate from the obstacle-aware route follower. A small on-screen cue appears for a few seconds when a new warning fires. It is intentionally modest, not a substitute for finished audio, dog animation, authored environmental cues, or accessibility options.

Android gameplay still requires real-device testing.