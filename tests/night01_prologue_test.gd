extends SceneTree
const Hut = preload("res://scripts/world/lola_hut_interior.gd")
const State = preload("res://scripts/narrative/night01_state.gd")
var fails := 0
func _initialize() -> void:
	call_deferred("_run")
func test(ok: bool, label: String) -> void:
	if not ok:
		fails += 1
		printerr("Prologue check failed: " + label)
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var items: Dictionary = Hut.build(world)
	test(items.size() == 5, "all interactive prologue targets exist")
	test(items["HUT_EXIT"] != null, "interior door available")
	test(items["LOLA_HOME"] != null, "Lola present in her own home")
	var room := world.get_node_or_null(Hut.NODE_NAME) as Node3D
	test(room != null, "separate walkable interior created")
	var count := world.get_child_count()
	var items_again: Dictionary = Hut.build(world)
	test(world.get_child_count() == count, "interior never duplicated")
	test(items["BLUE_NOTEBOOK"] == items_again["BLUE_NOTEBOOK"], "interaction nodes reused")
	var desk := room.get_node("Writing desk top") as MeshInstance3D
	var book := room.get_node("Blue cloth notebook") as MeshInstance3D
	var breakfast := room.get_node("Breakfast table") as MeshInstance3D
	var cup := room.get_node("Warm pottery cup") as MeshInstance3D
	test(desk != null and book != null and breakfast != null and cup != null, "notebook and cup have proper supporting furniture")
	if desk != null and book != null:
		var d_size: Vector3 = (desk.mesh as BoxMesh).size
		var b_size: Vector3 = (book.mesh as BoxMesh).size
		test(absf(book.position.x - desk.position.x) + b_size.x / 2 < d_size.x / 2, "notebook rests inside writing desk width")
		test(absf(book.position.z - desk.position.z) + b_size.z / 2 < d_size.z / 2, "notebook rests inside writing desk depth")
		test(book.position.y - b_size.y / 2 >= desk.position.y + d_size.y / 2 - 0.04, "notebook sits on desk, not on ground")
		test(items["BLUE_NOTEBOOK"].position.distance_to(book.position) < 0.1, "notebook interaction matches visible book position")
	if breakfast != null and cup != null:
		var table_size: Vector3 = (breakfast.mesh as BoxMesh).size
		test(absf(cup.position.x - breakfast.position.x) < table_size.x / 2, "cup stays on the breakfast table")
	var state = State.new()
	test(not state.prologue_ready(), "new game needs first morning ritual")
	test(not state.inspect_prologue("unknown"), "invalid prop cannot complete tutorial")
	test(state.inspect_prologue("blue_notebook"), "notebook observed")
	test(not state.prologue_ready(), "warm cup still required")
	test(state.inspect_prologue("warm_cup"), "warm cup observed")
	test(state.prologue_ready(), "tutorial ready after both")
	test(not state.inspect_prologue("warm_cup"), "repeat does not grant progress twice")
	test(state.inspect_prologue("river_photo"), "optional photo recorded")
	var restored = State.new()
	test(restored.from_dict(state.to_dict()), "new tutorial save loads")
	test(restored.prologue_ready() and restored.prologue_flags.has("river_photo"), "all flags persisted")
	var legacy: Dictionary = state.to_dict()
	legacy.erase("prologue_flags")
	var migrated = State.new()
	test(migrated.from_dict(legacy), "older saves load")
	test(migrated.prologue_ready(), "older saves not locked in tutorial")
	world.queue_free()
	print("Lola prologue regression: ", "PASS" if fails == 0 else str(fails) + " failures")
	quit(0 if fails == 0 else 1)
