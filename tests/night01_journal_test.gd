extends SceneTree
const Journal = preload("res://scripts/narrative/night01_journal.gd")
const State = preload("res://scripts/narrative/night01_state.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func verify(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Night 1 Journal: " + label)
func _run() -> void:
	var state = State.new()
	var empty := "\n".join(Journal.lines(state))
	verify(empty.find("No clues yet") >= 0, "helpful clue-free instructions")
	verify(empty.find("CREATURES / BESTIARY") < 0, "no false bestiary before resolution")
	state.seen_people["dado"] = true
	for clue in State.REQUIRED:
		state.observe_clue(clue)
	state.link_evidence("light_mooring")
	state.link_evidence("ledger_mooring")
	var notes := "\n".join(Journal.lines(state))
	verify(notes.find("SUSPECTED") >= 0 and notes.find("CORROBORATED") >= 0, "confidence labels distinguish eyewitness and ledger")
	verify(notes.find("NOT proven") >= 0 or notes.find("no proven") >= 0, "name hypothesis never presented as established fact")
	verify(not state.bestiary.has("santelmo"), "no premature creature entry")
	verify(state.begin(), "begin staged encounter")
	verify(state.advance_observation(), "advance to reflection")
	verify(state.choose_reflection("current_aligned"), "correct deterministic light")
	verify(state.guide_to_landing(3.3, true, true, true), "gentle landing completes")
	verify(state.commit_result("resolve"), "one valid night outcome")
	verify(not state.commit_result("drive_away"), "no contradictory second result")
	verify(state.bestiary.size() == 1, "exactly one creature entry")
	var record: String = "\n".join(Journal.lines(state))
	verify(record.find("CREATURES / BESTIARY") >= 0, "bestiary visible after outcome")
	verify(record.find("NOT confirmed") >= 0, "bestiary avoids invented boatman identity")
	var restore = State.new()
	verify(restore.from_dict(state.to_dict()), "reload with journal")
	verify(restore.bestiary.size() == 1, "no duplicated entry on reload")
	print("Night 1 source-aware journal: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
