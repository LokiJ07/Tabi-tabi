extends SceneTree

const Guide = preload("res://scripts/ai/bantay_route.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("Bantay route regression: " + label)

func _run() -> void:
	var guide = Guide.new()
	_expect(guide.is_safe(Vector3(0, 0, 0)), "main path walkable")
	_expect(not guide.is_safe(Vector3(6, 0, 5)), "Lola's hut blocked")
	_expect(not guide.is_safe(Vector3(7, 0, -8)), "store blocked")
	_expect(not guide.is_safe(Vector3(-2, 0, -12)), "school blocked")
	_expect(not guide.is_safe(Vector3(-12, 0, 3)), "river excluded")
	_expect(not guide.is_safe(Vector3(13, 0, 14)), "tree trunk excluded")
	var path: PackedVector3Array = guide.route(Vector3(1, 0, 5), Vector3(10, 0, 5))
	_expect(path.size() > 2, "route around Lola's hut")
	for point in path:
		_expect(guide.is_safe(point), "no waypoints within solid geometry")
	var riverside: PackedVector3Array = guide.route(Vector3(1, 0, 2), Vector3(-7, 0, 13))
	_expect(riverside.size() > 2, "safe route to mooring")
	for point in riverside:
		_expect(guide.is_safe(point), "mooring route is safe")
	_expect(guide.route(Vector3(0, 0, 0), Vector3(40, 0, 0)).is_empty(), "out-of-bounds target never teleported")
	print("Bantay navigation regression: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
