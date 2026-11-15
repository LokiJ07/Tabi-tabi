extends SceneTree
const Awareness = preload("res://scripts/ai/bantay_awareness.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _expect(value: bool, description: String) -> void:
	if not value:
		failures += 1
		printerr("Bantay awareness failure: " + description)
func _run() -> void:
	var a = Awareness.new()
	var safe := Vector3.ZERO
	var river := Vector3(-6, 0, 1)
	_expect(a.tick(0.1, safe, false, false, Vector3.ZERO, 0.0) == "", "safe village no false alert")
	_expect(a.tick(0.1, river, false, false, Vector3.ZERO, 0.0) != "", "riverside warning")
	_expect(a.tick(0.1, river, false, false, Vector3.ZERO, 0.0) == "", "warning not spammed")
	_expect(a.tick(10.1, safe, false, false, Vector3.ZERO, 0.0) == "", "clears warning away from river")
	var alarm := a.tick(0.1, safe, true, true, Vector3(1, 1, 2), 0.9)
	_expect(alarm.find("unsettled") >= 0, "nighttime Santelmo alarm")
	_expect(a.tick(0.1, safe, true, true, Vector3(1, 1, 2), 0.9) == "", "alarm cooldown")
	a.reset()
	_expect(a.warning_cooldown == 0.0, "reset")
	print("Bantay awareness regression: ", "PASS" if failures == 0 else str(failures) + " failures")
	quit(0 if failures == 0 else 1)
