extends SceneTree
const After = preload("res://scripts/world/night01_aftermath.gd")
var fails := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		printerr("Morning aftermath: " + msg)
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	check(After.ensure(world, "") == null, "uncommitted has no aftermath")
	var a: Node3D = After.ensure(world, "resolve")
	check(a != null, "resolve creates visible outcome marker")
	check(a.get_node_or_null("Quiet remembered glow") != null, "resolved river has warm memory glow")
	check(After.ensure(world, "resolve") == a, "repeated creation reuses same node")
	check(world.get_child_count() == 1, "one outcome prop across reload calls")
	check(a.get_meta("night1_outcome") == "resolve", "outcome tag deterministic")
	check(After.morning_label("partial").find("RETURNED") >= 0, "partial morning distinct")
	check(After.morning_label("drive_away").find("UNEASY") >= 0, "drive away morning distinct")
	var other := Node3D.new()
	root.add_child(other)
	var cold: Node3D = After.ensure(other, "drive_away")
	check(cold != null and cold.get_node_or_null("Quiet remembered glow") == null, "drive away is not resolved art")
	world.queue_free()
	other.queue_free()
	print("Morning aftermath tests: ", "PASS" if fails == 0 else str(fails) + " failures")
	quit(0 if fails == 0 else 1)
