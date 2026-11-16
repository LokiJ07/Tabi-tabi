extends SceneTree
## Coherence gate catches the visual-placement bugs earlier CI missed:
## opaque prototype cubes behind nipa facades, boat on dry land, disconnected
## dock, missing actual shoreline, and an obstructed Lola cutaway.
const GameScene = preload("res://scenes/main.tscn")
const Art = preload("res://scripts/world/illustrated_barrio.gd")
const Hut = preload("res://scripts/world/lola_hut_interior.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Night 1 world cohesion: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	game._close_dialogue()
	for house in ["Lola's hut", "Sabel's store", "School"]:
		var shell := game.get_node_or_null(house) as MeshInstance3D
		var roof := game.get_node_or_null(house + " roof") as MeshInstance3D
		var collider := game.get_node_or_null(house + " collision") as StaticBody3D
		check(shell != null and not shell.visible, house + ": obsolete cube is hidden")
		check(roof != null and not roof.visible, house + ": flat cube roof is hidden")
		check(collider != null, house + ": real collision preserved")
	var village := game.get_node_or_null("BarrioEnvironmentDetails") as Node3D
	check(village != null, "all three authored nipa structures still exist")
	for name in ["Lola woven home", "Sabel riverside store", "Mara schoolhouse"]:
		var structure := village.get_node_or_null(name) as Node3D
		check(structure != null, name + " still renders")
		if structure != null:
			# All three houses must be CLOSED volumes, not pasted flat facades.
			# The old bare cubes are hidden, so these panels are essential.
			for wall_name in ["Front woven wall surface", "Rear woven wall surface", "Left woven wall surface", "Right woven wall surface"]:
				var panel := structure.get_node_or_null(wall_name) as MeshInstance3D
				check(panel != null, name + ": complete " + wall_name)
				if panel != null:
					var wall_mat := panel.material_override as StandardMaterial3D
					check(wall_mat != null and wall_mat.albedo_texture != null, name + ": wall uses imported woven bamboo")
			for side in [-1, 1]:
				var roof := structure.get_node_or_null("Layered roof %d" % side) as MeshInstance3D
				check(roof != null, name + ": proper pitched nipa roof geometry")
				if roof != null:
					var mat := roof.material_override as StandardMaterial3D
					check(mat != null and mat.albedo_texture != null, name + ": roof actually uses authored thatch texture")
	var boat := game.river_boat as Node3D
	check(boat != null, "native banca exists")
	if boat != null:
		check(boat.global_position.x < -12.25, "banca and outriggers fully within river")
		check(absf(boat.global_position.z - 9.0) < 0.01, "banca floats adjacent to the connected dock")
	check(game.get_node_or_null("Dock side rail north") != null, "landing has a continuous timber rail")
	check(game.get_node_or_null("Dock stilt") != null, "landing actually stands on river supports")
	var shore := game.get_node_or_null(Art.ROOT_NAME) as Node3D
	check(shore != null, "authored shore exists")
	if shore != null:
		for name in ["Estuary wet mud margin", "Irregular tidal shelf", "Sandy riverbank lip"]:
			var mesh := shore.get_node_or_null(name) as MeshInstance3D
			check(mesh != null and mesh.mesh != null, name + " is triangulated real in-world terrain")
		check(Art.decorate(game) == shore, "shores do not duplicate during scene setup")
	var room := game.get_node_or_null(Hut.NODE_NAME) as Node3D
	check(room != null, "Lola's real 3D cutaway is available")
	if room != null:
		for key in ["Front woven wall left", "Front woven wall right", "Right woven wall"]:
			var wall := room.get_node_or_null(key) as MeshInstance3D
			check(wall != null and not wall.visible, "camera-facing " + key + " is cut away")
			check(room.get_node_or_null(key + " collision") != null, "camera-side " + key + " retains physical collision")
		for key in ["BLUE_NOTEBOOK", "WARM_CUP", "HUT_EXIT"]:
			check(room.get_node_or_null(key) != null, "clue/exit remains at authored position: " + key)
	game.queue_free()
	await process_frame
	print("Night 1 actual-world architectural cohesion: ", "PASS" if failures == 0 else str(failures) + " failure(s)")
	quit(0 if failures == 0 else 1)
