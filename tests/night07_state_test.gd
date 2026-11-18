extends SceneTree
## Real final-chapter state: evidence, guardian trial, privacy, ending and save.
const Story = preload("res://scripts/narrative/night07_state.gd")
const Save = preload("res://scripts/core/night07_save.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Night 7 canonical state: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var original: Dictionary = {}
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			original[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var state := Story.new()
	check(not state.deduce("records_and_witnesses"),"no skip past evidence")
	check(not state.finish_epilogue(),"cannot unlock free roam from new save")
	check(not state.prepare("safe_footpath"),"no preparation before evidence")
	for id in Story.CLUES:
		check(state.inspect(id),"real source can be inspected: "+id)
	check(state.phase == 1,"all four independent clues unlock documentary deduction")
	check(not state.deduce("the_keeper_caused_flood"),"false blame cannot complete chapter")
	check(state.deduce("records_and_witnesses"),"human decisions established independently of spirit")
	check(state.phase == 2,"safe community preparation starts after deduction")
	check(not state.choose_remembrance("consented"),"Sabel's private grief cannot become public by button")
	for id in Story.PREPARATIONS:
		check(state.prepare(id),"community action prepared: "+id)
	check(state.prepare("safe_footpath") == false,"no duplicate rewards or preparation")
	check(state.choose_remembrance("private"),"family privacy respected")
	check(state.begin_trial(),"three roots begin after genuine physical preparation")
	check(not state.respond("remember_losses"),"trial choice requires actual hold OBSERVE")
	check(not state.observe_tick(0.10,false,false),"lack of observation does not fake readiness")
	check(state.observe_tick(1.4,true,true),"safe HOLD OBSERVE requires meaningful time")
	check(not state.respond("protect_living"),"wrong first response cannot skip first memory")
	check(state.respond("remember_losses"),"acknowledge flood losses on first root")
	check(state.trial_index == 1 and state.phase == 3,"first trial saved")
	check(state.observe_tick(1.5,true,true),"second safe root observation")
	check(state.respond("protect_living"),"respect living survivor privacy")
	check(state.observe_tick(1.5,true,true),"third safe root observation")
	check(state.respond("share_responsibility"),"community accepts work, not magical reset")
	check(state.phase == 4 and state.trial_index == 3,"three root challenges lead to meaningful verdict")
	check(not state.available_results().has("renewal"),"cannot fully restore without verified river evidence")
	state.river_outcome = "resolve"
	state.lola_truth_known = true
	check(state.available_results().has("renewal"),"verified river outcome may open best shared ending")
	check(state.commit_result("renewal"),"full restored ending valid after trial")
	check(not state.commit_result("repair"),"final result can never be farmed twice")
	check(state.outcome == "renewal" and state.phase == 5,"real narrative conclusion before epilogue")
	check(not state.epilogue_complete,"time does not automatically unlock on trial completion")
	check(Save.write(state),"write independent offline finale save")
	var restored := Story.new()
	check(Save.read(restored),"reload Night 7 offline state")
	check(restored.phase == 5 and restored.outcome == "renewal","save retains real ending")
	check(not restored.epilogue_complete,"reloaded story still needs playable epilogue")
	check(restored.finish_epilogue(),"explicit epilogue completion")
	check(restored.epilogue_complete and restored.phase == 6,"saved finale unlocks free roam only after epilogue")
	check(Save.write(restored),"save permanent epilogue")
	var replay := Story.new()
	check(Save.read(replay) and replay.epilogue_complete,"reload preserves finished story")
	check(not replay.finish_epilogue(),"epilogue cannot be re-completed for rewards")
	var bad := replay.to_dict()
	bad["trial_index"] = 12
	check(not Story.new().from_dict(bad),"invalid saved trial index rejected")
	bad = replay.to_dict()
	bad["sabel_consent"] = "private"
	bad["choice_of_remembrance"] = "consented"
	check(not Story.new().from_dict(bad),"cannot forge survivor consent by modifying save")
	for path in [Save.PATH,Save.PATH+".bak",Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in original:
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file != null:
			file.store_buffer(original[path])
			file.close()
	print("Night 7 source, trial, outcome and save regression: ",
		"PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
