extends SceneTree
const State = preload("res://scripts/narrative/night01_state.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("Courage regression: " + what)
func ready_state() -> RefCounted:
	var s = State.new()
	for clue in State.REQUIRED:
		s.observe_clue(clue)
	s.link_evidence("light_mooring")
	s.link_evidence("ledger_mooring")
	s.begin()
	return s
func _run() -> void:
	var tired = ready_state()
	tired.alarm = 1.0
	check(not tired.tick_courage(5.0), "pressure warns before failing")
	check(tired.courage < 100.0, "alarm drains courage")
	check(tired.tick_courage(7.0), "pressure eventually triggers one recoverable failure")
	check(tired.encounter_failed, "failure stored")
	check(not tired.tick_courage(5.0), "no duplicate failure events")
	check(not tired.advance_observation(), "failed encounter cannot progress")
	var reloaded = State.new()
	check(reloaded.from_dict(tired.to_dict()), "failure save loads")
	check(reloaded.encounter_failed, "failure persists")
	check(reloaded.retry_from_checkpoint(), "checkpoint allows retry")
	check(not reloaded.encounter_failed and reloaded.courage >= 99.9, "retry clears fear without duplicating resources")
	var assisted = ready_state()
	assisted.alarm = 1.0
	check(not assisted.tick_courage(60.0, true), "story assist prevents forced failure")
	check(assisted.courage >= 25.0, "assist keeps a visible safety floor")
	var water = ready_state()
	water.courage = 30.0
	water.alarm = 0.80
	check(water.drink_water(), "single-use water recovers courage")
	check(water.courage >= 65.0, "water recovery applied")
	check(water.alarm < 0.80, "safe pause lowers pressure")
	check(not water.drink_water(), "no water duplication")
	var migrated = State.new()
	var old: Dictionary = water.to_dict()
	old.erase("courage")
	old.erase("encounter_failed")
	check(migrated.from_dict(old), "older save migrates")
	check(is_equal_approx(migrated.courage, 100.0), "legacy courage defaults to full")
	print("Night 1 courage tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
