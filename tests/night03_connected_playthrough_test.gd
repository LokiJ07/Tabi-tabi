extends SceneTree
## Real NIGHT 2 -> NIGHT 3 -> NIGHT 2 on-foot connected scene changes;
## all independent saves and the shared world ledger survive both crossings.
const Mango = preload("res://scenes/night02.tscn")
const Night2 = preload("res://scripts/narrative/night02_state.gd")
const Night2Save = preload("res://scripts/core/night02_save.gd")
const Night3Save = preload("res://scripts/core/night03_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
var failures := 0

func check(value: bool,label: String) -> void:
	if not value:
		failures += 1
		printerr("Connected ridge crossing: "+label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var paths := [
		Night2Save.PATH,Night2Save.PATH+".bak",Night2Save.PATH+".tmp",
		Night3Save.PATH,Night3Save.PATH+".bak",Night3Save.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"
	]
	var original: Dictionary = {}
	for file in paths:
		if FileAccess.file_exists(file):
			original[file] = FileAccess.get_file_as_bytes(file)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	var previous = Night2.new()
	previous.night1_outcome = "partial"
	for id in Night2.REQUIRED_CLUES:
		previous.observe(id)
	check(previous.begin_safety(),"Kapre safety phase entered with actual evidence")
	for id in Night2.BARRIER_POSITIONS:
		previous.close_route(id)
	check(previous.commit("partial"),"legitimate finished Kapre case created")
	check(Night2Save.write(previous),"Night 2 canonical outcome saved separately")
	check(World.note_outcome(2,"partial"),"shared seven-night record shows Kapre outcome")
	var night2 = Mango.instantiate()
	root.add_child(night2)
	current_scene = night2
	await process_frame
	check(night2.ending_panel.visible,"real Night 2 ending restored after restart")
	night2.ending_panel.hide()
	night2._sync_gameplay_hud()
	night2.player_pos = World.TRAIL_MANGO_RIDGE
	check(night2._nearby() == "ridge_gate","real northern path accepts on-foot crossing")
	night2._interact()
	await process_frame
	await process_frame
	var ridge = current_scene
	check(ridge != null and ridge.name == "TabiTabiNight3","walking ridge opens actual authored Night 3 scene")
	if ridge != null and ridge.name == "TabiTabiNight3":
		check(ridge.player_pos.distance_to(World.ARRIVAL_RIDGE)<2.0,
			"ridge spawn safely beyond return gate; not a random detached chapter")
		check(ridge.story.night02_outcome == "partial",
			"Kapre's existing ending is carried to the Tikbalang rescue mystery")
		if ridge.dialogue.visible:
			ridge._choose("close")
		ridge.player_pos = World.TRAIL_RIDGE
		check(ridge._nearby() == "return_mango","same ridge trail physically connects back to mango")
		ridge._return_to_mango()
		await process_frame
		await process_frame
		var back = current_scene
		check(back != null and back.name == "TabiTabiNight2","ridge return loads original mango gameplay")
		if back != null and back.name == "TabiTabiNight2":
			check(back.player_pos.distance_to(World.ARRIVAL_MANGO_RIDGE)<2.0,
				"return arrives beside real mango-to-ridge signpost")
			check(back.story.outcome == "partial","existing Kapre ending untouched by Tikbalang visit")
			# Release SceneTree ownership BEFORE queue_free: keeping a stale
			# current_scene pointer after two scene swaps can hang teardown.
			current_scene = null
			back.queue_free()
	else:
		if ridge != null:
			ridge.queue_free()
	await process_frame
	for file in paths:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	for file in original:
		var output := FileAccess.open(file,FileAccess.WRITE)
		if output != null:
			output.store_buffer(original[file])
			output.close()
	print("Real Old Mango → Tikbalang Ridge → Old Mango connected travel: ",
		"PASS" if failures == 0 else str(failures)+" failures")
	current_scene = null
	print("NIGHT3_CROSSING_TEARDOWN_READY")
	quit(0 if failures == 0 else 1)
