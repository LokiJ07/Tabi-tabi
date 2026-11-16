extends SceneTree
const Mangrove = preload("res://scripts/world/mangrove.gd")
const GameScene = preload("res://scenes/main.tscn")
var failed := 0

func check(ok: bool, title: String) -> void:
	if not ok:
		failed += 1
		printerr("Night 1 mangrove art: " + title)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)
	var tree := Mangrove.build(root_node, Vector3(-13, -0.04, 2), 42)
	check(tree.name == "Mangrove_42", "each tree has named and stable identity")
	check(tree.get_meta("shore_tree", "") == "mangrove", "shoreline species explicit")
	check(tree.get_node_or_null("GnarledTrunk") != null, "mangrove has gnarled woody stem")
	check(tree.get_node_or_null("PropRoot_00_A") != null and tree.get_node_or_null("PropRoot_05_B") != null, "distinct branching stilt roots reach shallows")
	check(tree.get_node_or_null("MainMangroveCrown") != null, "mangrove has layered leafy crown")
	check(tree.get_node_or_null("MangroveLeafCluster_4") != null, "multiple irregular foliage layers")
	check(tree.get_child_count() >= 25, "tree is not one trunk and one round canopy")
	root_node.queue_free()
	var game = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	var root_count := 0
	for node in game.get_children():
		if node is Node3D and str(node.name).begins_with("Mangrove_"):
			root_count += 1
	check(root_count >= 8, "river uses eight mangroves rather than ordinary trees")
	check(game.get_node_or_null("BarrioEnvironmentDetails/Lola woven home/Nipa facade bamboo strip 0") != null, "Lola house has woven bamboo facade")
	check(game.get_node_or_null("BarrioEnvironmentDetails/Mara schoolhouse/Open window shutter") != null, "school window gets architectural detail")
	check(game.get_node_or_null("BarrioEnvironmentDetails/Sabel riverside store/Porch floorboards 0") != null, "store has textured porch")
	game.queue_free()
	print("Night 1 mangrove and nipa artwork: ", "PASS" if failed == 0 else str(failed) + " failures")
	quit(0 if failed == 0 else 1)
