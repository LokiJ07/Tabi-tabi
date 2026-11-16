extends SceneTree
## Tests *actual player interaction* and scene streaming, not just graph data.
const Barrio = preload("res://scenes/main.tscn")
const Night1 = preload("res://scripts/narrative/night01_state.gd")
const Night1Save = preload("res://scripts/core/save_service.gd")
const Night2Save = preload("res://scripts/core/night02_save.gd")
const World = preload("res://scripts/core/connected_world.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Connected travel gameplay: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# Isolate all three independent saves and restore developer data afterward.
	var paths := [
		Night1Save.PATH,Night1Save.PATH+".bak",Night1Save.PATH+".tmp",
		Night2Save.PATH,Night2Save.PATH+".bak",Night2Save.PATH+".tmp",
		World.PATH,World.PATH+".bak",World.PATH+".tmp"
	]
	var old: Dictionary = {}
	for path in paths:
		if FileAccess.file_exists(path):
			old[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var completed = Night1.new()
	var prepared := completed.to_dict()
	prepared["phase"] = 4
	prepared["outcome"] = "partial"
	prepared["prologue_flags"] = {"blue_notebook":true,"warm_cup":true}
	check(completed.from_dict(prepared), "valid canonical Santelmo outcome fixture")
	check(Night1Save.write(completed,false), "save Night 1 before leaving")
	var game = Barrio.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.interaction_nodes.has("MANGO_TRAIL"), "real village north-trail interaction exists")
	check(game.get_node_or_null("North Trail sign lettering") != null, "trail sign exists in native world")
	game.player.global_position = World.TRAIL_BARRIO + Vector3(0,.55,0)
	check(game._nearby_target() == "MANGO_TRAIL", "on-foot world interaction detects north trail")
	game._interact()  # real interaction -> separate loaded Kapre region
	await process_frame
	await process_frame
	var night2 = current_scene
	check(night2 != null and night2.name == "TabiTabiNight2", "walking north loads Kapre grove, not title menu")
	if night2 != null and night2.name == "TabiTabiNight2":
		check(night2.player_pos.distance_to(World.ARRIVAL_MANGO) < 2.0, "same-world north trail arrives at safe grove entrance")
		check(night2.story.night1_outcome == "partial", "Night 1 ending follows the player")
		if night2.dialogue.visible:
			night2._choose("close")
		night2.player_pos = World.TRAIL_MANGO
		check(night2._nearby() == "return_barrio", "old mango trail is physically reachable on foot")
		night2._interact()  # real interaction -> return into Barrio Lawom
		await process_frame
		await process_frame
		var back = current_scene
		check(back != null and back.name == "TabiTabi", "return crossing loads same original Barrio gameplay")
		if back != null and back.name == "TabiTabi":
			check(back.player.global_position.distance_to(World.ARRIVAL_BARRIO) < 2.0, "returns at correct path entrance, not random spawn")
			check(back.story.outcome == "partial", "Night 1 case and consequences intact")
			back.queue_free()
	else:
		if night2 != null:
			night2.queue_free()
	await process_frame
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in old:
		var saved := FileAccess.open(path,FileAccess.WRITE)
		if saved != null:
			saved.store_buffer(old[path])
			saved.close()
	print("Real on-foot Barrio → Kapre → Barrio travel, save and story: ","PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
