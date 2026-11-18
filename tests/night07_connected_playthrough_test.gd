extends SceneTree
## Real river -> Balete -> river streaming, authentic Night 6 save gate.
const RiverScene = preload("res://scenes/night06.tscn")
const RiverState = preload("res://scripts/narrative/night06_state.gd")
const RiverSave = preload("res://scripts/core/night06_save.gd")
const BaleteSave = preload("res://scripts/core/night07_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("River-to-Balete road: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var backups: Dictionary = {}
	for path in [RiverSave.PATH,RiverSave.PATH+".bak",RiverSave.PATH+".tmp",
		BaleteSave.PATH,BaleteSave.PATH+".bak",BaleteSave.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			backups[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(not World.begin_travel("night06","night07","resolve"),
		"cannot enter Balete using a forged string without the actual saved river ending")
	var model := RiverState.new()
	for id in RiverState.CLUES: check(model.inspect(id),"inspect Night 6 "+id)
	check(model.reconstruct_cancellation("real_danger_unequal_choice"),"source-based cancellation")
	for id in RiverState.ROUTE: check(model.plot_route(id),"true rescue boat stop "+id)
	for id in RiverState.IDENTITY: check(model.inspect_identity(id),"independent rescuer identity "+id)
	check(model.reconstruct_sacrifice("sabel_husband"),"correct Sabel family rescue evidence")
	check(model.tell_sabel("private"),"survivor chooses private remembrance")
	check(model.confess_lola(),"Keeper scope and withheld records acknowledged")
	check(model.open_river(),"safety-first river opens")
	for id in RiverState.PREPARATIONS: check(model.prepare(id),"safe preparation "+id)
	check(model.begin_crossing(),"real three-stone river scenario begins")
	for id in RiverState.RIVER_ACTIONS:
		check(model.observe_tick(1.25,true,true),"safe route observed before action")
		check(model.respond(id),"safe response: "+id)
	check(model.commit("resolve"),"Night 6 genuinely completed; not just a QA preview flag")
	check(RiverSave.write(model),"independent River save committed")
	var ledger := World.read()
	var outcomes: Dictionary = ledger["outcomes"]
	for i in range(1,6):
		outcomes["night%02d" % i] = "drive_away" if i == 4 else "resolve"
	ledger["outcomes"] = outcomes
	check(World.write(ledger),"prior one-world ledger remains separate")
	check(World.note_outcome(6,model.outcome),"River outcome in canonical one-world ledger")
	check(not World.begin_travel("night06","night07","contain"),
		"incorrect prior result rejected despite real save")
	var river = RiverScene.instantiate()
	root.add_child(river)
	current_scene = river
	await process_frame
	if river.ending.visible:
		river.ending.hide()
		river._sync_ui()
	river.player_pos = World.TRAIL_RIVER_BALETE
	check(river._nearby() == "balete_gate",
		"tangible Night 6 hill road has new actual gate when story complete")
	river._interact()
	await process_frame
	await process_frame
	var balete = current_scene
	check(balete != null and balete.name == "TabiTabiNight7",
		"real on-foot crossing loads Balete gameplay, not a title concept")
	if balete != null and balete.name == "TabiTabiNight7":
		check(balete.player_pos.distance_to(World.ARRIVAL_BALETE) < 3.0,
			"same one-world path arrives at safe Balete entrance")
		check(balete.story.river_outcome == "resolve" and balete.story.sabel_consent == "private",
			"river outcome and private family choice carried forward")
		if balete.dialogue.visible: balete._choice("close")
		balete.player_pos = World.TRAIL_BALETE_RIVER
		check(balete._nearby() == "return_river","Balete trail return is physically interactable")
		balete._interact()
		await process_frame
		await process_frame
		var returned = current_scene
		check(returned != null and returned.name == "TabiTabiNight6",
			"return route reconnects to original river region without menu or false level")
		if returned != null and returned.name == "TabiTabiNight6":
			check(returned.player_pos.distance_to(World.ARRIVAL_RIVER_BALETE) < 3,
				"return places player at existing river hill road, never cut-off void")
			check(returned.story.outcome == "resolve",
				"river outcome and evidence survive two scene streams")
			returned.queue_free()
	else:
		if balete != null: balete.queue_free()
	await process_frame
	for path in [RiverSave.PATH,RiverSave.PATH+".bak",RiverSave.PATH+".tmp",
		BaleteSave.PATH,BaleteSave.PATH+".bak",BaleteSave.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in backups:
		var saved := FileAccess.open(path,FileAccess.WRITE)
		if saved != null:
			saved.store_buffer(backups[path])
			saved.close()
	print("Authentic Night 6 -> Balete -> Night 6 connected gameplay: ",
		"PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
