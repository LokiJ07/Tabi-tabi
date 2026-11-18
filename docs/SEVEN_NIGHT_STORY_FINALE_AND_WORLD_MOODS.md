# Tabi-tabi: Seven Nights, One Conclusion — Narrative Canon and World Aftermath

**Final story premise.** Each night is a connected investigation of a living community, not seven unrelated monster fights. The player starts as an ordinary apprentice with Bantay and gathers evidence on the road to the Ancient Balete Keeper. The seven folkloric beings are **not all controlled by the Keeper**. They are separate encounters with different ethical and physical dangers; the common thread is the village's unfinished promises and the Great Flood.

## What actually happened during the Great Flood
1. The river really was dangerous. The former captain prioritised some households, stopped the official second rescue and left others out of the evacuation list. He has since died. Kapitan Ruben is the current official who must face the existing public archive and correct it, not retroactively pretend he signed the order.
2. Independent survivors and family evidence, when corroborated, identify a separate returning boat and connect the final rescuer to **Aling Sabel's missing husband**. He helped bring others toward safety, never came home, and is remembered with consent, not exploited as a prop for automatic forgiveness. **Mang Celso, the boatman linked to the Santelmo's mooring in Night 1, is a different person.**
3. The Balete Keeper protected the *high refuge only*. It could not control the river, choose the captain's evacuation decisions or reveal unwritten history. Lola Pasing knew part of the limited covenant and kept silent too long; she is accountable, but she does not automatically die in any ending and nobody owes forgiveness.
4. The documentary trail is visible across Nights 1–6: light and mooring, an unstable flood refuge tree, misleading ridge signs, a vulnerable grieving household, a caretaker's farm and a dangerous real river reconstruction. Specific earlier choices are retained in the final notebook. If a player did not corroborate something, the finale presents it as unresolved rather than injecting perfect knowledge.

## The **four distinct final world moods**

| Ending | Actual postgame emotion | Consequence and Free Roam |
| --- | --- | --- |
| **TRUE — The Promise Remembered** | **Peaceful, hopeful, gently happy** | Corroborated public records, protected witness identities, a family-approved memorial and practical work make the village feel alive again. Golden morning warmth, more flowered records, brighter paths and softer character responses. Some families are still mourning; this is not magically perfect happiness. |
| **GOOD — The Quiet Barrio** | **Calm and safe, but cautiously incomplete** | The Keeper's immediate danger subsides. Residents work and Bantay rests, but missing records, route safety and promises still need follow-up. Pale, muted morning light and a smaller remembrance board signal unfinished obligations. |
| **BITTERSWEET — What Remains** | **Sad, truthful and slowly healing** | The village publicly acknowledges credible history but cooperation breaks down. No automatic forgiveness. Cool blue-grey skies, few flowers, lone memorial flame, quieter neighbours and hard conversations reflect the unfinished relationships. |
| **DARK — The Door Left Open** | **Unsettling and sorrowful, but not hopeless** | The player *deliberately* denies verified history after a second warning. Roots remain restless, neighbours guard their records and older obligations fester. Overcast violet-blue dawn, minimal blossoms and solitary lantern. Nobody automatically dies; the player still has all seven connected maps to visit and consider the consequences. |

These outcomes are persistent, not a one-screen color-swap. Each of the **seven maps** contains an original physical *Seven-night Record* marker in the same world space, with ending-specific visuals and a contextual interaction. Night 1 uses a real 3D bulletin sign and adjusted sunlight/sky; Nights 2–7 use a grounded 2.5D wooden notice and subtle environment lighting. Interaction provides *that chapter's* historical place in the seven-night story, previously saved outcomes and the actual selected village aftermath. Chapter controls and authored roads never move.

## Resident conclusions
- **Mara**: maintains the school archive; records are corrected in True, delayed in Good, disputed in Bittersweet, protected from denial in Dark.
- **Sabel**: may keep her family's private memory. A verified boat identity is disclosed only if actually corroborated. Her grief is never a required public speech.
- **Dado**: maintains safe flood waypoints and protects surviving testimony.
- **Lola**: personally accountable for silence, living unless her own separate character story says otherwise; never a compulsory sacrifice to finish Night 7.
- **Bantay**: survives and accompanies the apprentice in every ending; no surprise animal death.
- **The community**: the memorial, school, family safety, riverbank, farm and grove change in credible human ways, never via instant supernatural reset.

## In-game conclusion order
1. Keeper trial ends with one of four explicitly chosen outcomes; dramatic summary states the **emotion and concrete state of Barrio Lawom**, not simply “You Won”.
2. **PLAY THE MORNING AFTER** opens three optional narrative revelation scenes: **Mara and the official decision; Sabel's corroborated/uncorroborated rescue boat; Lola and the refuge's limit**. The text adapts to *actually known* evidence. “Unknown” remains an honest answer.
3. The player walks around the morning glade, speaks to living neighbours and visits the memorial or river. The final notebook includes **all seven locations, the six earlier outcomes, documentary truth and witness consent**.
4. Only when the player voluntarily completes the epilogue does **FREE ROAM • ALL 7 MAPS** unlock. The current world tone, save progress and original chapter paths persist through every physical adjacent map.
5. Returning to the title resumes the actual last location rather than replaying the ending or erasing the records. New Story remains a separately confirmed reset.

## Release verification
- `tests/postgame_story_conclusion_test.gd` freezes seven-night chronology, four distinct moods, true/partial fact handling, Sabel consent and Lola's independent fate.
- `tests/postgame_free_roam_test.gd` exercises the real completed save, **12 directed adjacent journeys**, last-map resume and completed chapter scenes. It also checks physical aftermath boards where available.
- Existing complete Night 7 story and scene tests, all Nights 1–6 regressions, the fixed shared HUD and Android APK/emulator pipeline must remain GREEN on the exact merge commit.
- Full on-phone human story playthrough, production signing/save migration, performance, text readability and cultural sensitivity remain separate release requirements. This development branch is not automatically public release sign-off.
