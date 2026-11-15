extends RefCounted
## Night 1 canonical outcome / evidence model.
## No scene nodes, UI or mutable global autoload dependencies.

const REQUIRED := ["light_retreat", "old_mooring", "boatman_name"]
const RESULTS := ["resolve", "drive_away", "partial"]
var clues: Dictionary = {}
var evidence_links: Dictionary = {}
var hypothesis := ""
var phase := 0
var outcome := ""
var committed_events: Dictionary = {}
var seen_people: Dictionary = {}
var alarm := 0.0
var checkpoint: Dictionary = {}
var revision_count := 0


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
	return outcome == "" and phase == 0 and has_complete_evidence() and has_linked_evidence()


func begin() -> bool:
	if not can_begin():
		return false
	phase = 1
	checkpoint = to_dict()
	return true


func advance_observation() -> bool:
	if phase != 1:
		return false
	# Releasing sustained direct light leaves the spirit calm enough to observe.
	if alarm > 0.45:
		return false
	phase = 2
	checkpoint = to_dict()
	return true


func choose_reflection(id: String) -> bool:
	if phase != 2:
		return false
	if id != "current_aligned":
		alarm = minf(1.0, alarm + 0.22)
		return false
	phase = 3
	checkpoint = to_dict()
	return true


func commit_result(result: String) -> bool:
	if phase != 3 or outcome != "" or not RESULTS.has(result):
		return false
	outcome = result
	committed_events["n1_santelmo_" + result] = true
	phase = 4
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
		"evidence_links": evidence_links.duplicate(true),
		"hypothesis": hypothesis,
		"phase": phase,
		"outcome": outcome,
		"committed_events": committed_events.duplicate(true),
		"seen_people": seen_people.duplicate(true),
		"alarm": alarm,
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
	var input_clues: Dictionary = raw.get("clues", {})
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
	hypothesis = str(raw.get("hypothesis", ""))
	phase = restored_phase
	outcome = restored_result
	committed_events = {}
	if outcome != "":
		committed_events["n1_santelmo_" + outcome] = true
	seen_people = raw.get("seen_people", {}).duplicate(true)
	alarm = clampf(float(raw.get("alarm", 0)), 0.0, 1.0)
	revision_count = maxi(0, int(raw.get("revision_count", 0)))
	checkpoint = {}
	var saved_checkpoint: Variant = raw.get("checkpoint", {})
	if typeof(saved_checkpoint) == TYPE_DICTIONARY and outcome == "":
		var cp_phase := int(saved_checkpoint.get("phase", -1))
		if cp_phase >= 1 and cp_phase <= 3 and str(saved_checkpoint.get("outcome", "")) == "":
			checkpoint = saved_checkpoint.duplicate(true)
	return true
