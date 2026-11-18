extends RefCounted
const FinalState = preload("res://scripts/narrative/night07_state.gd")
const FinalSave = preload("res://scripts/core/night07_save.gd")
## ONE seven-night historical conclusion; four persistent, visibly different
## community futures. Never invent proof, kill Lola by ending choice, expose
## private witnesses, or turn the seven folklore beings into one boss's minions.
const ENDINGS := ["true","good","bittersweet","dark"]
const REGIONS := [
	"barrio_lawom","old_mango","night03","night04","night05","night06","night07"
]
const CHAPTERS := {
	"barrio_lawom":"NIGHT 1 • SANTELMO / MANG CELSO",
	"old_mango":"NIGHT 2 • KAPRE / THE OLD MANGO",
	"night03":"NIGHT 3 • TIKBALANG / THE FALSE TRAIL",
	"night04":"NIGHT 4 • MANANANGGAL / THE WAKE",
	"night05":"NIGHT 5 • SIGBIN / THE ABANDONED FARM",
	"night06":"NIGHT 6 • THE GREAT FLOOD / RIVER CROSSING",
	"night07":"NIGHT 7 • BALETE / THE KEEPER'S TRIAL"
}
const HISTORY := {
	"barrio_lawom":"Mang Celso's mooring and the Santelmo light reminded the village of people left waiting. Mang Celso the boatman is NOT Sabel's missing husband.",
	"old_mango":"The Kapre's great tree marks an old refuge route. A broken promise did not make a fallen branch safe: the community must maintain the detour and assess the roots.",
	"night03":"The Tikbalang's false signs could send walkers toward the ravine. The original three shelter waypoints, not supernatural accusations, tell the safe route.",
	"night04":"The Manananggal threatened a living family during a wake. The mourners survived because people stayed together. No grieving guest was proven guilty.",
	"night05":"The Sigbin guarded an old caretaker's promise near the farm. The livestock pen is a real enclosure, not a passage for the apprentice; the barn still needs repair.",
	"night06":"The Great Flood's surviving records describe the stopped official second rescue, dangerous water and families not listed for evacuation. The separately returning boat must be corroborated from survivor and family sources.",
	"night07":"The Balete Keeper could protect only the high refuge. It could not stop the flood, identify every human decision, or order the other six creatures. The final promise is human: preserve evidence, protect witnesses, and do work."
}
const PALETTE := {
	"true":"#d5bd74",
	"good":"#b3c3a1",
	"bittersweet":"#9faeb9",
	"dark":"#a58eaa"
}

static func saved_ending() -> String:
	var finished = FinalState.new()
	if not FinalSave.read(finished) or not finished.finished:
		return ""
	return finished.outcome if valid(finished.outcome) else ""

static func valid(result: String) -> bool:
	return ENDINGS.has(result)

static func character_from_save(person: String) -> String:
	var finale = FinalState.new()
	if not FinalSave.read(finale) or not finale.finished:
		return ""
	return character_after(finale.outcome,person,finale.sabel_privacy,
		finale.lola_is_living,finale.commitments.has("family_memorial"),
		finale.previous_facts.get("returning_boat",false) == true)

static func mood(result: String) -> String:
	match result:
		"true": return "PEACEFUL • HOPEFUL • REBUILDING"
		"good": return "QUIET • SAFE TODAY • UNFINISHED"
		"bittersweet": return "SAD • TRUTHFUL • SLOWLY HEALING"
		"dark": return "UNEASY • DIVIDED • NOT WITHOUT HOPE"
	return "STORY STILL UNFOLDING"

static func ending_title(result: String) -> String:
	match result:
		"true": return "TRUE • THE PROMISE REMEMBERED"
		"good": return "GOOD • THE QUIET BARRIO"
		"bittersweet": return "BITTERSWEET • WHAT REMAINS"
		"dark": return "DARK • THE DOOR LEFT OPEN"
	return "THE COMMUNITY RECORD"

static func outcome_message(result: String) -> String:
	match result:
		"true":
			return "The Balete roots settle, windows glow, neighbours return to work, and the first small memorial is tended. There is laughter again, but the missing are not forgotten. Peace was earned by the village's records, witness protection and real promises."
		"good":
			return "The dangerous night passes. Homes reopen, Bantay sleeps by the doorway, and people can walk the roads again. Yet some names are missing from the public record; repairs and community promises are unfinished. The peace is real but fragile."
		"bittersweet":
			return "The truth is spoken, but people do not suddenly forgive each other. The streets grow quieter; the memorial and archive stand incomplete. Sabel may mourn in private, Lola faces her silence, and the neighbours must learn to work together again."
		"dark":
			return "The flood's evidence was deliberately denied. The Keeper withdraws without a settled covenant. Lanterns stay lit longer, families are wary, and the roots remain restless at the forest boundary. Nobody is automatically killed; the choice leaves hard work for another day."
	return "The valley is still waiting for the story to end."

static func seven_night_revelation(verified: Dictionary) -> String:
	var facts: Array[String] = []
	if verified.get("cancelled_rescue",false) == true:
		facts.append("The water was genuinely dangerous; nevertheless the official second launch was stopped after some households had been prioritised. Families on the far bank were left out of the evacuation roll. The former captain is dead; Kapitan Ruben must correct the surviving record.")
	else:
		facts.append("The official cancellation and unequal evacuation are still partly disputed; no one may invent certainty without surviving records.")
	if verified.get("returning_boat",false) == true:
		facts.append("A separate boat returned toward the far bank after the official cancellation. Corroborated survivor and family evidence connects its rescuer to Sabel's missing husband. His final crossing saved others but he never came home; neither his loss nor his courage excuses the cancelled public rescue.")
	else:
		facts.append("The independent rescue boat and its rescuer still need corroboration. Sabel's grief cannot be used as a public confession without her consent.")
	if verified.get("limited_refuge",false) == true:
		facts.append("The Keeper guarded the elevated Balete refuge, not the entire river. Lola knew part of the limited covenant and must answer for keeping it quiet; the Keeper did not choose the evacuation list or command the earlier creatures.")
	else:
		facts.append("The limit of the refuge remains uncertain. The Keeper cannot magically reveal documents or decide whom the village must forgive.")
	return "\n\n".join(facts)

static func long_conclusion(result: String, verified: Dictionary, prior: Dictionary) -> String:
	var record := "SEVEN NIGHTS • ONE BARRIO LAWOM\n\n"
	for region in REGIONS:
		record += CHAPTERS[region]+"\n"+HISTORY[region]+"\n\n"
	record += "WHAT WE CAN ACTUALLY SAY ABOUT THE FLOOD\n\n"
	record += seven_night_revelation(verified)
	record += "\n\nEARLIER OUTCOMES (THEY REMAIN CANON)\n"
	for n in range(1,7):
		record += "Night %d: %s\n" % [n,str(prior.get("night%02d" % n,"unrecorded"))]
	record += "\nFINAL MOOD: "+mood(result)+"\n"+outcome_message(result)
	record += "\n\nNo automatic forgiveness, no forced public testimony, no resurrection, and no mandatory character death. The roads remain physically connected for Free Roam."
	return record

static func character_after(result: String, person: String, privacy: String = "private",
		lola_living: bool = true, memorial: bool = false, rescue_verified: bool = false) -> String:
	var context := outcome_message(result)
	match person:
		"mara":
			return "Mara keeps the rescued evacuation records at school. "+(
				"The corrected ledger is taught openly, with private names redacted." if result == "true"
				else "She keeps asking which families are missing from the ledger and refuses to publish guesses." if result == "good"
				else "Some neighbours refuse to sit at the same table, but she will preserve the evidence." if result == "bittersweet"
				else "The council has rejected the record. She hides safe copies so a future generation can ask again.")
		"sabel":
			var personal := "The rescued boat and Sabel's husband's final crossing are corroborated; he did not come home. Mang Celso was a different boatman. " if rescue_verified else "Sabel's husband disappeared amid the rescue; her family history is still missing independently verified details. Mang Celso was a different boatman. "
			personal += "She may remember him privately; her choice is "+privacy+". "
			if result == "true": return personal+"The family's approved memorial is tended with respect, not turned into a public spectacle."
			if result == "good": return personal+"She is safe, but asks when the promises of the living will be carried out."
			if result == "bittersweet": return personal+"Knowing the truth has not made the grief smaller; no one asks her to forgive."
			return personal+"She keeps her door open for the people she trusts, not for those demanding her silence."
		"dado":
			return "Dado can show the real river-stone trail without giving away protected identities. "+(
				"The corrected map is on the public school board." if result == "true"
				else "Some warnings still need checking and repairing." if result == "good"
				else "He remembers the route quietly while neighbours argue over responsibility." if result == "bittersweet"
				else "He keeps the original map in a safe place despite the council's denial.")
		"lola":
			if not lola_living:
				return "Lola's life ended in her own separate human story, not as a punishment or prize for the Keeper trial. Her evidence remains available with care."
			return "Lola Pasing is alive, still accountable for how long she kept the covenant's limits to herself. "+(
				"She visits the memorial and helps teach children to question even their elders." if result == "true"
				else "She works with Mara on the missing pages; forgiveness is not owed to her." if result == "good"
				else "Some relatives are not ready to speak with her. She keeps showing up without demanding absolution." if result == "bittersweet"
				else "She keeps a written copy of the truth in case another keeper must be heard.")
		"river":
			return "The river remains a real place that needs safe banks, warning markers and care. "+(
				"Its morning waterline is calm, but the memorial reminds everyone to prepare for the next flood." if result == "true"
				else "The waterline steadies for now; upstream reinforcement remains unfinished." if result == "good"
				else "The river is quiet, though the families on opposite banks still disagree." if result == "bittersweet"
				else "A cold mist clings to the old crossing. The water carries no verdict, only a warning.")
		"memorial":
			if result == "true" and memorial: return "Families approved a small memorial. Visitors leave flowers; private names remain private. It records both the lost and those who helped."
			if result == "bittersweet": return "The plaque records the known history, but the village is divided over how to tend it. An incomplete memorial is not a finished promise."
			if result == "dark": return "The notice board is half-empty where testimony was rejected. Someone still leaves fresh flowers without asking permission."
			return "The memorial is still being planned with the families. Safety today is not the same as every promise being fulfilled."
		"bantay":
			return "Bantay stays beside the Apprentice. "+(
				"Children have started waving at him on the way to school again." if result == "true"
				else "The paths are quiet enough for him to rest, but he still watches the river." if result == "good"
				else "He sits beside people who need company without asking them to speak." if result == "bittersweet"
				else "He keeps watch at the unlit corners. Even here, someone can choose to care.")
	return context

static func region_after(result: String, region: String, old_outcome: String = "") -> String:
	if not valid(result) or not CHAPTERS.has(region): return ""
	var local: String = str(HISTORY[region])
	var responsibility := ""
	match region:
		"barrio_lawom":
			responsibility="The school, mooring, Lola's home and Sabel's store remain part of the same world. The village does not forget Mang Celso."
		"old_mango":
			responsibility="The fallen branch is still a real hazard. The detour stays marked until a safe assessment is done."
		"night03":
			responsibility="The shelter waypoints stay marked. Old false signs are not allowed to mislead the next traveller."
		"night04":
			responsibility="Neighbours still tend the wake house and check the latches. Aling Nena was never blamed without evidence."
		"night05":
			responsibility="The goats and chickens remain at the safe receiving pen; the collapsing barn is not suddenly safe because the story ended."
		"night06":
			responsibility="Mara checks the flood records and Dado maintains the real safe crossing. Sabel's name is never posted without permission."
		"night07":
			responsibility="The glade can be visited again, but the Keeper does not resolve human responsibility by magic."
	var local_result := ""
	if old_outcome != "":
		local_result="Your recorded chapter outcome remains %s. " % old_outcome.to_upper()
	return CHAPTERS[region]+"\n\n"+local+"\n\n"+local_result+responsibility+"\n\n"+outcome_message(result)

static func notice_color(result: String) -> Color:
	return Color(str(PALETTE.get(result,"#c3b8a4")))

static func paint_region_2d(canvas: CanvasItem, bounds: Rect2, marker: Vector2,
		result: String, player: Vector2) -> void:
	if not valid(result): return
	var tone := notice_color(result)
	# Small, branch-specific atmospheric wash, applied in WORLD SPACE.
	# All gameplay controls are CanvasLayer UI and keep Night 1 positions.
	var wash := Color(tone.r,tone.g,tone.b,.055 if result=="true" else .045)
	if result=="dark": wash=Color(.22,.16,.30,.11)
	if result=="bittersweet": wash=Color(.33,.38,.46,.064)
	canvas.draw_rect(bounds,wash)
	var base := marker
	canvas.draw_circle(base+Vector2(7,7),41,Color(.02,.04,.03,.22))
	# Hand-dressed wooden remembrance board, tied into the actual path.
	canvas.draw_line(base+Vector2(-31,17),base+Vector2(-31,-52),Color("#735b43"),8.0,true)
	canvas.draw_line(base+Vector2(32,17),base+Vector2(32,-52),Color("#735b43"),8.0,true)
	canvas.draw_rect(Rect2(base+Vector2(-58,-109),Vector2(121,66)),Color("#6c5947"))
	canvas.draw_rect(Rect2(base+Vector2(-50,-101),Vector2(105,50)),Color("#dbcba2"))
	canvas.draw_line(base+Vector2(-43,-85),base+Vector2(47,-85),tone,5.0,true)
	canvas.draw_line(base+Vector2(-43,-72),base+Vector2(19,-72),Color("#807c67"),3.0,true)
	# True: fresh blossoms; Good: a few new leaves; Bittersweet: wilting
	# flowers and candle; Dark: one stubborn remaining flame.
	for i in range(5 if result=="true" else 3 if result=="good" else 2 if result=="bittersweet" else 1):
		var n := float(i)
		var at := base+Vector2(-74+n*27,25+sin(n*1.7)*9)
		canvas.draw_line(at,at+Vector2(0,-19),Color("#64816c"),3.0,true)
		canvas.draw_circle(at+Vector2(0,-22),5.8,tone)
	if result=="dark" or result=="bittersweet":
		canvas.draw_rect(Rect2(base+Vector2(47,12),Vector2(7,15)),Color("#ede0b9"))
		canvas.draw_circle(base+Vector2(50,-5),6.0,Color("#eed18c",.62))
	if player.distance_to(base)<228.0:
		canvas.draw_string(ThemeDB.fallback_font,base+Vector2(-91,-122),
			"SEVEN-NIGHT RECORD • INTERACT",HORIZONTAL_ALIGNMENT_CENTER,285,
			16,Color("#f3e4c5"))
		canvas.draw_string(ThemeDB.fallback_font,base+Vector2(-78,69),
			mood(result),HORIZONTAL_ALIGNMENT_CENTER,275,14,Color("#f0d9ab"))
