extends SceneTree
const Nearby = preload("res://scripts/ui/nearby_interaction.gd")
var errors := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, description: String) -> void:
	if not ok:
		errors += 1
		printerr("Interaction prompt: " + description)

func _run() -> void:
	var targets := {
		"LOLA": Vector3(4, 0, 7),
		"DADO": Vector3(-5, 0, 7),
		"MOORING": Vector3(-7, 0, 13),
		"SABEL": Vector3(3, 0, -5),
		"MARA": Vector3(-2, 0, -8)
	}
	_expect(Nearby.closest(Vector3.ZERO, targets) == "", "no false prompt from distance")
	_expect(Nearby.closest(Vector3(4, 5, 7), targets) == "LOLA", "vertical visual offsets do not prevent touch interaction")
	_expect(Nearby.closest(Vector3(-6, 0, 11), targets) == "MOORING", "mooring prompt accessible")
	_expect(Nearby.closest(Vector3(-3, 0, 7), targets) == "DADO", "nearest NPC")
	_expect(Nearby.caption("MARA").find("TEACHER MARA") >= 0, "descriptive name")
	_expect(Nearby.caption("") == "", "prompt cleared for no target")
	print("Nearby interaction regression: ", "PASS" if errors == 0 else str(errors) + " failures")
	quit(0 if errors == 0 else 1)
