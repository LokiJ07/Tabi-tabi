extends SceneTree
const Dialogue = preload("res://scripts/narrative/night01_dialogue.gd")
const State = preload("res://scripts/narrative/night01_state.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _check(v: bool, name: String) -> void:
	if not v:
		failures += 1
		printerr("Dialogue check: " + name)
func _run() -> void:
	var state = State.new()
	_check(Dialogue.response("MARA", state, false).find("mooring") >= 0, "Mara directs to location before clue")
	_check(Dialogue.response("DADO", state, false).find("mosibog") >= 0, "initial observation")
	state.seen_people["dado"] = true
	_check(Dialogue.response("DADO", state, false).find("Wala ko kahibalo") >= 0, "revisit is uncertainty not new proof")
	_check(Dialogue.response("SABEL", state, false).find("ipakaylap") >= 0, "witness privacy")
	state.seen_people["privacy_agreed"] = true
	_check(Dialogue.response("SABEL", state, false).find("Salamat") >= 0, "privacy consent remembered")
	state.observe_clue("old_mooring")
	_check(Dialogue.response("MARA", state, false).find("ledger") >= 0, "record becomes available after mooring")
	state.observe_clue("boatman_name")
	state.observe_clue("light_retreat")
	_check(Dialogue.response("LOLA", state, true).find("tulo") >= 0, "Lola responds to completed evidence")
	_check(Dialogue.response("MOORING", state, true).find("At night") >= 0, "mooring nighttime dialogue")
	print("Night 1 dialogue tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
