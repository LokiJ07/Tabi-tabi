# TABI-TABI master-script delivery gates

This is a non-spoiler implementation matrix aligned with Master Script & Development Plan v1.0, sections 24, 27–30. It is updated to describe **actual repo evidence** as of the Night 1 feature branch, not future promises.

| Gate | Implementation status | Evidence before progression |
| --- | --- | --- |
| G0 Preproduction | Source canon exists; source scene IDs not all in data assets | Freeze Night 1 scene dependency and art bible |
| G1 Engine/input | Android debug export, isometric camera, movement, Focus and user-reported initial functional buttons | Thumb-based control, camera/occlusion and multi-aspect device signoff |
| G2 Living hub | Playable temporary Lola-hut morning interior/prologue plus store/school blockout, ambient residents, Bantay path grid and alerts | Authored/interior and believable NPC activity; navigation QA |
| G3 Story/investigation | Witness dialogue, 3 clues, 2 links, revisable theory, 4-slot preparation, offline save and accessibility prefs | True conditional dialogue, localized line IDs, full UI/learning experience, multi-aspect usability |
| G4 Santelmo | State-driven phases, physical retreat cues, 2 reflected markers, **three-second player-guided lantern route to shore for Resolve**, Courage, cloth/water/bell actions, three outcomes, checkpoint, morning prop | Fair puzzle/gameplay real-device demonstration, cinematic and visibility QA |
| G5 Cinematic/art | Distinct temporary 3D NPC costumes, **actual offline painted head-and-shoulders portrait atlas**, speaker-switching dialogue overlay, richer environmental props, synthesized ambience | Authored rigged models, full facial animation, painterly 3D world, final sound and playable cinematic direction still required |
| G6 Night 1 player validation | Headless full-flow and Android packaging; Android emulator launch smoke is a new CI gate; earlier user screenshot proves an older APK launched | Uncoached testing, bug/pace feedback, stable real thumb controls, save/load and performance |
| G7 Nights 2–5 | Not implemented | Distinct Kapre/Tikbalang/Manananggal/Sigbin gameplay with chapter-specific validation |
| G8 Nights 6–7 + epilogue | Not implemented | Three historical reconstructions, Keeper trial, four endings, independent Lola arc |
| G9 Release qualification | Not started | Full offline test matrix, accessibility/localization, cultural review, stable signing/update and credits |

## Release rule

The master document specifically states: *proceed to Night 2 only after a convincing, complete and Android-tested Night 1*, not merely when CI turns green. No promise of unattended 24/7 work is implied.

## Immediate next engineering priorities

1. Make the apprentice's Lola-hut prologue a real player-controlled interior and improve camera roof occlusion.
2. Improve Santelmo phase 3's actual in-world guiding mechanics, not just dialog buttons.
3. Move prototype world/UI logic out of the monolithic Main.gd toward the modular architecture proposed in the master document.
4. Replace placeholder procedural character art with validated rigged models and animations.
5. Complete language line sheets and mobile accessibility, then real-device validation and G6.

Keep the canonical record distinct from hypotheses. Sabel's husband is not Mang Celso. The Keeper cannot manufacture evidence, cure ordinary illness, force forgiveness, or control independent creatures.
