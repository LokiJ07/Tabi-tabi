extends SceneTree
const Details = preload("res://scripts/world/barrio_details.gd")
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failed += 1
		printerr("Barrio art details: " + message)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var details: Node3D = Details.decorate(world)
	check(details != null, "decorations created")
	check(details.name == Details.ROOT_NAME, "named root for safe reuse")
	check(details.get_node_or_null("Lola woven home") != null, "Lola home identifiable")
	check(details.get_node_or_null("Sabel riverside store") != null, "store different art")
	check(details.get_node_or_null("Mara schoolhouse") != null, "school distinct")
	check(details.get_node_or_null("Riverside lantern") != null, "warm mooring light prop")
	check(details.get_node_or_null("Fishing basket") != null, "fisher lived-in prop")
	check(details.get_node_or_null("Store market tray") != null, "market lived-in prop")
	check(details.get_child_count() >= 30, "not just three simple roof boxes")
	var first_size := details.get_child_count()
	check(Details.decorate(world) == details, "duplicate calls reuse authored visuals")
	check(details.get_child_count() == first_size, "repeated setup never duplicates environmental assets")
	world.queue_free()
	print("Barrio environment art: ", "PASS" if failed == 0 else str(failed) + " failures")
	quit(0 if failed == 0 else 1)
