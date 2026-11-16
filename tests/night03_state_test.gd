extends SceneTree
## Exercises every Night 3 state gate, false-route penalty, save and outcome.
const Story = preload("res://scripts/narrative/night03_state.gd")
const Save = preload("res://scripts/core/night03_save.gd")
var failures := 0

func check(ok: bool,label: String) -> void:
	if not ok:
		failures += 1
		printerr("Night 3 story: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var paths := [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]
	var original: Dictionary = {}
	for path in paths:
		if FileAccess.file_exists(path):
			original[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var story = Story.new()
	check(story.phase == 0 and story.outcome == "", "actual fresh chapter begins with investigation")
	check(not story.mark_route("river_stones"), "cannot mark safety routes before examining evidence")
	check(not story.decide_route("river_stones"), "cannot bypass investigation via lucky guess")
	for id in Story.CLUES:
		check(story.inspect(id), "investigate evidence: "+id)
		check(not story.inspect(id), "cannot award same evidence twice: "+id)
	check(story.phase == 1 and story.clues.size() == 4, "all four clues unlock actual safety task")
	check(not story.mark_route("bamboo_diversion"), "out-of-order safety marker correctly rejected")
	check(story.false_turns == 1 and story.tension > 0.0, "wrong-way marker increases real tension")
	for id in Story.MARKERS:
		check(story.mark_route(id), "place safety marker in map order: "+id)
	check(story.phase == 2 and story.route_safe(), "three real safety markers unlock nighttime observation")
	check(not story.observe(6.0,false,true), "observation outside shelter never counts")
	check(story.observation < .001, "unsafe location cannot bypass shelter")
	check(story.observe(3.3,true,true), "continuous lookout observation unlocks route puzzle")
	check(story.phase == 3, "night observation advances actual state")
	check(not story.decide_route("blue_lanterns"), "false lantern trap rejected")
	check(not story.decide_route("hoofprints"), "misleading hoofprints rejected")
	check(story.false_turns == 3, "all wrong turns are visible consequences")
	check(story.decide_route("river_stones"), "physical flood-map evidence verifies true route")
	check(story.phase == 4 and story.route_verified, "truthful route opens Tikbalang encounter")
	var partial_source: Dictionary = story.to_dict()
	check(not story.commit("resolve"), "cannot resolve without witnessing the truth")
	check(not story.record_truth(), "cannot record guardian testimony without respectful greeting")
	check(story.greet(), "tabi-tabi permission is a meaningful action")
	check(story.record_truth(), "guardian's version is recorded as testimony, not universal fact")
	check(story.commit("resolve"), "true evidence + respectful negotiation resolves Night 3")
	check(not story.commit("partial"), "ending and bestiary cannot be awarded twice")
	check(story.committed_events.size() == 1 and story.bestiary.has("tikbalang"), "exactly one committed folklore bestiary entry")
	check(Save.write(story), "atomic separate Night 3 save succeeds")
	var read_back = Story.new()
	check(Save.read(read_back), "Night 3 save reloads from disk")
	check(read_back.outcome == "resolve" and read_back.truth_recorded and read_back.route_verified,
		"resolved ending and critical truth flags survive offline reload")
	check(read_back.night02_outcome == "", "night 3 saving never mutates prior chapter flags")
	var partial = Story.new()
	check(partial.from_dict(partial_source), "valid route-verified branch can be reloaded")
	check(partial.commit("partial"), "route-only partial conclusion remains playable")
	var retreat = Story.new()
	check(retreat.commit("retreat"), "safe exit is always possible")
	var retry = Story.new()
	for id in Story.CLUES:
		retry.inspect(id)
	for id in Story.MARKERS:
		retry.mark_route(id)
	retry.danger_tick(100.0,true,false)
	check(retry.encounter_failed, "unsafe terrain triggers actual danger without fatal player loss")
	check(retry.retry_checkpoint(), "safe retry restores checkpoint")
	check(not retry.encounter_failed and retry.courage >= 56.0 and retry.phase == 2,
		"retry is not a softlock and preserves completed safety markers")
	var malformed: Dictionary = partial_source.duplicate(true)
	malformed["route_verified"] = false
	check(not Story.new().from_dict(malformed), "corrupt false route proof cannot be loaded at phase 4")
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in original:
		var out := FileAccess.open(path,FileAccess.WRITE)
		if out != null:
			out.store_buffer(original[path])
			out.close()
	print("Night 3 Tikbalang investigation, puzzle, endings and offline save: ",
		"PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
