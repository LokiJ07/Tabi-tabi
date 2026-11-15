extends RefCounted
const NightKit = preload("res://scripts/items/night01_inventory.gd")
## Night 1 canonical outcome / evidence model.
## No scene nodes, UI or mutable global autoload dependencies.

const REQUIRED := ["light_retreat", "old_mooring", "boatman_name"]
const RESULTS := ["resolve", "drive_away", "partial"]
var clues: Dictionary = {}
var kit = NightKit.new()
var evidence_links: Dictionary = {}
var hypothesis := ""
var phase := 0
var outcome := ""
var committed_events: Dictionary = {}
var bestiary: Dictionary = {}
var seen_people: Dictionary = {}
var prologue_flags: Dictionary = {}
var alarm := 0.0
var courage := 100.0
var guide_progress := 0.0
var encounter_failed := false
var checkpoint: Dictionary = {}
var revision_count := 0


func inspect_prologue(id: String) -> bool:
	if not ["blue_notebook", "warm_cup", "river_photo"].has(id) or prologue_flags.has(id):
		return false
	prologue_flags[id] = true
	return true


func prologue_ready() -> bool:
	return prologue_flags.has("blue_notebook") and prologue_flags.has("warm_cup")


func observe_clue(id: String) -> bool:
	if not REQUIRED.has(id) or clues.has(id):
		return false
	clues[id] = true
	return true


func choose_hypothesis(value: String) -> void:
	if hypothesis != "" and hypothesis != value:
		revision_count += 1
	hypothesis = value


func link_evidence(id: String) -> bool:
	if phase != 0 or outcome != "" or evidence_links.has(id):
		return false
	match id:
		"light_mooring":
			if not clues.has("light_retreat") or not clues.has("old_mooring"):
				return false
		"ledger_mooring":
			if not clues.has("old_mooring") or not clues.has("boatman_name"):
				return false
		_:
			return false
	evidence_links[id] = true
	return true


func has_linked_evidence() -> bool:
	return evidence_links.has("light_mooring") and evidence_links.has("ledger_mooring")


func has_complete_evidence() -> bool:
	for id in REQUIRED:
		if not clues.has(id):
			return false
	return true


func can_begin() -> bool:
	return outcome == "" and phase == 0 and has_complete_evidence() and has_linked_evidence() and kit.is_ready()


func begin() -> bool:
	if not can_begin():
		return false
	phase = 1
	checkpoint = to_dict()
	return true


func advance_observation() -> bool:
	if phase != 1 or encounter_failed:
		return false
	# Releasing sustained direct light leaves the spirit calm enough to observe.
	if alarm > 0.45:
		return false
	phase = 2
	checkpoint = to_dict()
	return true


func choose_reflection(id: String) -> bool:
	if phase != 2 or encounter_failed:
		return false
	if id != "current_aligned":
		alarm = minf(1.0, alarm + 0.22)
		return false
	phase = 3
	checkpoint = to_dict()
	return true


func guide_to_landing(delta: float, close_to_landing: bool, focusing: bool, aim_aligned: bool) -> bool:
	# Holding a softened beam toward the SAFE landing (away from the spirit)
	# leads Santelmo ashore. Only this progress is continuous; not canonical truth.
	if phase != 3 or outcome != "" or encounter_failed:
		return false
	var good: bool = close_to_landing and focusing and aim_aligned and alarm < 0.55 and clues.has("boatman_name")
	if good:
		guide_progress = minf(1.0, guide_progress + maxf(0.0, delta) / 3.0)
	else:
		guide_progress = maxf(0.0, guide_progress - maxf(0.0, delta) * 0.10)
	return guide_progress >= 0.999


func commit_result(result: String) -> bool:
	if result == "resolve" and guide_progress < 0.999:
		return false
	if encounter_failed and result != "partial":
		return false
	if result == "drive_away" and not kit.has("signal_bell"):
		return false
	if phase != 3 or outcome != "" or not RESULTS.has(result):
		return false
	outcome = result
	committed_events["n1_santelmo_" + result] = true
	# A single observation entry, NOT a supernatural assertion that the boatman became the light.
	bestiary["santelmo"] = {
		"result": result,
		"observed": ["light_retreat", "old_mooring", "river_reflection"],
		"interpretation": "A wandering light near the old mooring. Mang Celso's name is a historical lead, not proven identity."
	}
	phase = 4
	return true


func tick_courage(delta: float, story_assist: bool = false) -> bool:
	if outcome != "" or phase < 1 or phase > 3 or encounter_failed:
		return false
	# Only a clearly alarmed spirit produces pressure; calm moments recover courage.
	if alarm > 0.60:
		courage -= (alarm - 0.60) * 25.0 * delta
	else:
		courage += 4.0 * delta
	courage = clampf(courage, 0.0, 100.0)
	if story_assist:
		courage = maxf(25.0, courage)
	if courage <= 0.0:
		encounter_failed = true
		return true
	return false


func drink_water() -> bool:
	if outcome != "" or phase < 1 or phase > 3 or encounter_failed or not kit.consume("water_flask"):
		return false
	courage = minf(100.0, courage + 35.0)
	alarm = maxf(0.0, alarm - 0.12)
	return true


func shade_lantern() -> bool:
	if phase != 1 or outcome != "" or encounter_failed or not kit.consume("cloth_wrap"):
		return false
	alarm = maxf(0.0, alarm - 0.34)
	return true


func accept_partial() -> bool:
	# A safe exit is explicitly available from any encounter phase.
	if phase < 1 or phase > 3:
		return false
	phase = 3
	return commit_result("partial")


func retry_from_checkpoint() -> bool:
	if checkpoint.is_empty() or outcome != "":
		return false
	var saved: Dictionary = checkpoint.duplicate(true)
	if not from_dict(saved):
		return false
	checkpoint = saved
	return true


func to_dict() -> Dictionary:
	return {
		"schema": 1,
		"clues": clues.duplicate(true),
		"kit": kit.to_dict(),
		"evidence_links": evidence_links.duplicate(true),
		"hypothesis": hypothesis,
		"phase": phase,
		"outcome": outcome,
		"committed_events": committed_events.duplicate(true),
		"bestiary": bestiary.duplicate(true),
		"seen_people": seen_people.duplicate(true),
		"prologue_flags": prologue_flags.duplicate(true),
		"alarm": alarm,
		"courage": courage,
		"guide_progress": guide_progress,
		"encounter_failed": encounter_failed,
		"revision_count": revision_count,
		"checkpoint": checkpoint.duplicate(true)
	}


func from_dict(raw: Dictionary) -> bool:
	if int(raw.get("schema", -1)) != 1:
		return false
	var restored_phase := int(raw.get("phase", -1))
	var restored_result := str(raw.get("outcome", ""))
	if restored_phase < 0 or restored_phase > 4:
		return false
	if restored_result != "" and not RESULTS.has(restored_result):
		return false
	if restored_result != "" and restored_phase != 4:
		return false
	var input_clues: Variant = raw.get("clues", {})
	var input_people: Variant = raw.get("seen_people", {})
	if typeof(input_clues) != TYPE_DICTIONARY or typeof(input_people) != TYPE_DICTIONARY:
		return false
	clues.clear()
	for id in REQUIRED:
		if input_clues.get(id, false) == true:
			clues[id] = true
	evidence_links = {}
	var raw_links: Variant = raw.get("evidence_links", {})
	if typeof(raw_links) == TYPE_DICTIONARY:
		if raw_links.get("light_mooring", false) == true and clues.has("light_retreat") and clues.has("old_mooring"):
			evidence_links["light_mooring"] = true
		if raw_links.get("ledger_mooring", false) == true and clues.has("old_mooring") and clues.has("boatman_name"):
			evidence_links["ledger_mooring"] = true
	# Older save files did not have inventory; defaults allow a safe upgrade.
	kit = NightKit.new()
	if raw.has("kit"):
		if not kit.from_dict(raw.get("kit")):
			return false
	hypothesis = str(raw.get("hypothesis", ""))
	phase = restored_phase
	outcome = restored_result
	committed_events = {}
	bestiary = {}
	var restored_bestiary: Variant = raw.get("bestiary", {})
	if outcome != "" and typeof(restored_bestiary) == TYPE_DICTIONARY and typeof(restored_bestiary.get("santelmo", null)) == TYPE_DICTIONARY:
		bestiary["santelmo"] = restored_bestiary["santelmo"].duplicate(true)
	elif outcome != "":
		bestiary["santelmo"] = {"result": outcome, "observed": ["light_retreat", "old_mooring", "river_reflection"], "interpretation": "A wandering light. The boatman connection remains an interpretation."}
	if outcome != "":
		committed_events["n1_santelmo_" + outcome] = true
	seen_people = input_people.duplicate(true)
	prologue_flags = {}
	var intro: Variant = raw.get("prologue_flags", null)
	if typeof(intro) == TYPE_DICTIONARY:
		for id in ["blue_notebook", "warm_cup", "river_photo"]:
			if intro.get(id, false) == true:
				prologue_flags[id] = true
	else:
		# Existing prototype saves predate the new intro; preserve their progress.
		prologue_flags = {"blue_notebook": true, "warm_cup": true}
	alarm = clampf(float(raw.get("alarm", 0)), 0.0, 1.0)
	courage = clampf(float(raw.get("courage", 100.0)), 0.0, 100.0)
	guide_progress = clampf(float(raw.get("guide_progress", 0.0)), 0.0, 1.0)
	encounter_failed = bool(raw.get("encounter_failed", false)) if outcome == "" else false
	revision_count = maxi(0, int(raw.get("revision_count", 0)))
	checkpoint = {}
	var saved_checkpoint: Variant = raw.get("checkpoint", {})
	if typeof(saved_checkpoint) == TYPE_DICTIONARY and outcome == "":
		var cp_phase := int(saved_checkpoint.get("phase", -1))
		if cp_phase >= 1 and cp_phase <= 3 and str(saved_checkpoint.get("outcome", "")) == "":
			checkpoint = saved_checkpoint.duplicate(true)
	return true
