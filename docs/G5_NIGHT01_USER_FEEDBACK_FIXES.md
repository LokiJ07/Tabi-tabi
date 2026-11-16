# Night 1 — Android playtest corrections: 15 November 2026

Triggered by on-device feedback after Phase 3 had already reached GUIDE 100%. The action bar still showed REMEMBER but pressing it displayed the old guidance tutorial. Focus hold looked identical to release. Reused AI-looking painted portraits confused witness identities. The blue notebook lay visibly in the aisle while the narrator described it as on a desk.

## Root cause and code fixes
- `NightModel.guide_to_landing` used to **decay guide_progress when Focus was released even after reaching 100%**. The choice-button label was only refreshed on the 100% crossing, so it could read REMEMBER while the model had silently fallen below the actual 99.9% threshold. Once reached, 100% is now latched, persisted through existing save serialization, and checked through one `can_remember()` helper for both the button label and commit eligibility.
- Focus is a true hold action. The button now changes between `HOLD FOCUS` (muted) and `FOCUS HELD` (bright teal outlined), with status text for holding, aim correction, closeness to the green landing, and when REMEMBER is available. Keyboard focus and modal closures update the same state. Style objects are not reallocated on every physics frame.
- Removed the runtime dependency on the repetitive AI-generated four-person portrait collage. The portrait component now draws **deterministic, role-specific illustrated busts**, with recognizable face proportions, palette and headwear/accessories grounded in the same NPC `FolkActors.identity` data used by 3D world actors. This is a deliberate stylized interim presentation, not a claim of finished professional portrait art.
- `ConversationPages` resolves untagged dialogue using explicit witness context; object and narrator interactions show no generic human face. NPC names and role-specific busts remain stable across interactions.
- Lola's interior now includes a proper writing desk beside the wall. The blue notebook book mesh, page edge and interact target are aligned on the tabletop; cup remains on the breakfast table. New prologue narration explicitly says what surface the object occupies.

## Regression evidence required
- Night 1 model & full scene outcome tests: reached 100%, released Focus, continued for 1.25–2 seconds, pressed displayed REMEMBER and committed resolve.
- Stage 3 touch button-down/up events and distinct pressed/released styles + status display.
- Source-aligned furniture positioning and interaction positions.
- Distinct named portraits, correct fallback narrator hiding and no painted atlas usage.
- Complete Godot parser/smoke, Android APK signed export, emulator launch, physical-phone read/play test.

## Important limitations
This fixes **specific real user-reported bugs** and makes source-aligned art changes, but still does not provide final rigged character models, a cinematic production master art package, or full physical-device QA sign-off. Existing canonical saves, outcomes and mechanics remain compatible.
