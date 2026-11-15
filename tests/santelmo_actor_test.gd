extends SceneTree
const Santelmo = preload("res://scripts/encounters/santelmo_actor.gd")
var errors := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		printerr("Santelmo regression: " + message)

func _run() -> void:
	var creature = Santelmo.new()
	root.add_child(creature)
	_expect(creature.true_reflection != null, "actual river-aligned marker exists")
	_expect(not creature.true_reflection.visible, "reflections hidden before puzzle")
	creature.set_encounter_phase(2)
	_expect(creature.true_reflection.visible, "true marker shown in phase two")
	_expect(creature.false_reflection.visible, "false marker shown in phase two")
	_expect(creature.reflection_near(Vector3(-8, 0, 15.5)) == "CURRENT_ALIGNED", "true marker selected by world proximity")
	_expect(creature.reflection_near(Vector3(-5, 0, 15.5)) == "FALSE_MIRROR", "false marker selected by world proximity")
	_expect(creature.reflection_near(Vector3(10, 0, 0)) == "", "distant selection prohibited")
	var facing := Vector3(-8.0, 0.0, 13.0).normalized()
	var before: float = creature.alarm
	creature.update_behavior(0.4, Vector3(0, 0, 0), facing, true)
	_expect(creature.alarm > before, "direct focus increases alarm")
	var agitated: float = creature.alarm
	creature.update_behavior(0.4, Vector3(0, 0, 0), Vector3.FORWARD, false)
	_expect(creature.alarm < agitated, "releasing focus calms")
	creature.set_encounter_phase(3)
	_expect(not creature.true_reflection.visible, "reflections disappear after solution")
	creature.queue_free()
	print("Santelmo visual model tests: ", "PASS" if errors == 0 else str(errors) + " failures")
	quit(0 if errors == 0 else 1)
