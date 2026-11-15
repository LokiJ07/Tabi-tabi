extends SceneTree
const RiverBanca = preload("res://scripts/world/river_banca.gd")
const GameScene = preload("res://scenes/main.tscn")
var errors := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		errors += 1
		printerr("Banca visual test: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var boat: Node3D = RiverBanca.build(scene, Vector3(-8.6, 0.15, 4.4))
	check(boat.name == RiverBanca.ROOT_NAME, "tapered boat root created")
	var hull := boat.get_node_or_null("Tapered hull") as MeshInstance3D
	check(hull != null and hull.mesh is ArrayMesh, "real triangle hull mesh, not simple cube")
	check((hull.mesh as ArrayMesh).get_surface_count() > 0, "hull has triangle surface")
	check(boat.get_child_count() >= 15, "outriggers, deck, seats and paddle parts")
	check(RiverBanca.build(scene, Vector3.ZERO) == boat, "setup is idempotent")
	RiverBanca.animate(boat, 1.0, false)
	check(absf(boat.rotation.z) > 0.001, "gentle water bob")
	RiverBanca.animate(boat, 1.0, true)
	check(boat.rotation == Vector3.ZERO, "reduced motion disables water bob")
	scene.queue_free()

	var game = GameScene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.river_boat != null and game.river_boat.name == RiverBanca.ROOT_NAME, "game uses visible original banca")
	check(game.get_node_or_null("Boat hull") == null, "obsolete prototype boat cube removed")
	game.queue_free()
	print("Night 1 riverside boat detail: ", "PASS" if errors == 0 else str(errors) + " failures")
	quit(0 if errors == 0 else 1)
