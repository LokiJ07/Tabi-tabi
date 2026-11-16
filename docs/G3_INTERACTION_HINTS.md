# G3.1 — NPC presence and contextual interaction

- Replace temporary floating sphere witness markers with existing procedural human stand-ins at their established world locations. The MOORING target now appears as a wooden tie post.
- Keep the same canonical interact IDs and story logic, while reducing player confusion about what can be touched.
- The HUD shows a concise **INTERACT • NAME** prompt only when the player is within 3.4 meters (horizontal distance) of the nearest witness or mooring, and hides it during notebook/dialogue overlays.
- Reuse a single deterministic closest-target helper for the prompt and the actual interact action, so an onscreen hint corresponds to what the INTERACT button will select.
- Dedicated regression cases cover nearest selection, mooring proximity, no false distance prompting, and vertical offsets.

The generated person figures are placeholders and this isn't final character art. Actual device testing still required for prompt readability and collision behavior.