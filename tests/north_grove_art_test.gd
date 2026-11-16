extends SceneTree
## Visual parity is a build gate, not just a screenshot review note.
const Main = preload("res://scenes/main.tscn")
const NorthGrove = preload("res://scripts/world/north_grove_layout.gd")
const Illustrated = preload("res://scripts/world/illustrated_barrio.gd")
var problems := 0

func check(ok: bool, reason: String) -> void:
	if not ok:
		problems += 1
		printerr("North grove art parity: " + reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	await process_frame
	check(NorthGrove.FLOOR_PATCHES.size() >= 5, "multi-patch north understory layout")
	var art: Node3D = game.get_node_or_null("NorthernGroveUnderstory")
	check(art != null, "real native village paints the forest floor")
	if art != null:
		for i in range(NorthGrove.FLOOR_PATCHES.size()):
			var patch := art.get_node_or_null("North grove floor painting %02d" % i) as MeshInstance3D
			check(patch != null, "authored forest texture patch %d exists" % i)
			if patch != null:
				check(patch.mesh is PlaneMesh, "ground detail is oriented planar terrain")
				var mat := patch.material_override as StandardMaterial3D
				check(mat != null and mat.albedo_texture != null, "ground carries an imported texture")
				check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "understory edges blend with terrain")
				check(patch.get_child_count() == 0, "floor has no invisible movement obstacle")
	var grove := game.get_node_or_null(Illustrated.ROOT_NAME) as Node3D
	check(grove != null, "northern forest shares village environment root")
	if grove != null:
		var trees := 0
		for child in grove.get_children():
			if child is Sprite3D and child.name.begins_with("Northern wild broadleaf"):
				trees += 1
		check(trees >= 12, "dense natural northern tree silhouettes authored in playable world")
	game.queue_free()
	await process_frame
	print("Northern forest visual parity + safety: ", "PASS" if problems == 0 else str(problems)+" failures")
	quit(0 if problems == 0 else 1)
