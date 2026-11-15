extends SceneTree

const NightModel = preload("res://scripts/narrative/night01_state.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run_tests")


func check(value: bool, name: String) -> void:
	if not value:
		failures += 1
		printerr("FAILED: " + name)


func run_tests() -> void:
	var m = NightModel.new()
	check(not m.can_begin(), "cannot start without clues")
	check(m.observe_clue("light_retreat"), "first clue")
	check(not m.observe_clue("light_retreat"), "duplicate clue ignored")
	check(m.observe_clue("old_mooring"), "second clue")
	check(m.observe_clue("boatman_name"), "third clue")
	check(m.has_complete_evidence(), "three kinds of evidence")
	m.choose_hypothesis("attack")
	m.choose_hypothesis("guide")
	check(m.revision_count == 1, "revising hypothesis allowed")
	check(m.begin(), "begin encounter")
	check(not m.begin(), "cannot start twice")
	m.alarm = 0.8
	check(not m.advance_observation(), "high alarm blocks approach")
	m.alarm = 0.2
	check(m.advance_observation(), "calm observation advances")
	check(not m.choose_reflection("false_mirror"), "false reflection deterministic")
	check(m.choose_reflection("current_aligned"), "correct reflection")
	check(m.commit_result("resolve"), "resolve commit")
	check(not m.commit_result("drive_away"), "outcome cannot be overwritten")
	check(m.committed_events.size() == 1, "single canonical outcome")
	check(not m.retry_from_checkpoint(), "cannot retry committed outcome")
	var restored = NightModel.new()
	check(restored.from_dict(m.to_dict()), "restore save")
	check(restored.outcome == "resolve", "saved outcome persists")
	check(restored.committed_events.size() == 1, "no duplicate events")
	check(not restored.commit_result("partial"), "cannot duplicate outcome after load")
	var second = NightModel.new()
	for clue in NightModel.REQUIRED:
		second.observe_clue(clue)
	second.begin()
	check(second.accept_partial(), "partial is safe exit")
	check(second.outcome == "partial", "partial committed")
	var third = NightModel.new()
	for clue in NightModel.REQUIRED:
		third.observe_clue(clue)
	third.begin()
	third.advance_observation()
	third.choose_reflection("current_aligned")
	check(third.commit_result("drive_away"), "drive away available")
	check(not third.from_dict({"schema": 42}), "reject incompatible schema")
	print("Night 1 model tests: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
