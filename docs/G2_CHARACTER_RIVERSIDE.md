# G2 Character and Riverside Iteration

## Included (temporary original procedural stand-ins)
- Apprentice has a salakot silhouette, head, clothes, arms and legs with simple walk/idle limb motion.
- Bantay has a recognizable quadruped body, ears, nose and moving tail; these are not final rigged animations.
- Three ambient villagers follow different small daytime routines and disappear from the visible road at night.
- Riverside adds low-cost reeds, shimmering color variation, a boat hull and landing planks.
- Sun intensity now responds to the night transition, improving atmosphere while keeping a low ambient fill.
- Automated smoke tests assert that player/dog parts exist and their simple animation updates.

## Incomplete quality requirements
- These are mesh-primitive figures, not final painterly 3D characters. No finished face animation, true dog gait, contact-aware foot placement or convincing cloth physics.
- No navmesh or avoidance for Bantay yet; the follower can intersect solid obstacles.
- The river is a visual surface, not fluid simulation. More importantly, the player collision/unsafe shoreline and reflection world-space puzzle must be verified interactively on a real phone.
- NPC schedules are still very short and require authored dialogue/behavior, traversal and reactions.
- Android headless export confirms packaging only, not whether player thumb controls feel good.
