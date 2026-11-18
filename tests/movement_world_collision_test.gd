extends SceneTree
const Prefs = preload("res://scripts/core/preferences.gd")
const HUD = preload("res://scripts/ui/shared_hud.gd")
const Walk = preload("res://scripts/world/shared_walkability_2d.gd")
const Lola = preload("res://scripts/world/lola_hut_interior.gd")
var failures := 0

func check(ok: bool, name: String) -> void:
	if not ok:
		failures += 1
		printerr("Movement/world integrity: "+name)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var prefs := Prefs.new()
	var layer := Control.new()
	root.add_child(layer)
	var captured := {"axis":Vector2(9,9)}
	var stick := HUD.create_movement_joystick(layer,prefs,func(axis: Vector2): captured["axis"] = axis)
	await process_frame
	check(stick.name == "MovementJoystick" and stick.position.x > 60.0,
		"left movement input is inset, not stuck at edge")
	stick._set_axis_from_local(stick.CENTER+Vector2(50,0))
	check((captured["axis"] as Vector2).x > .70 and absf((captured["axis"] as Vector2).y) < .01,
		"analog thumb direction drives movement")
	stick._release()
	check(captured["axis"] == Vector2.ZERO,"joystick release resets movement")
	prefs.from_dict({"schema":1,"joystick_x":99.0,"joystick_y":-99.0})
	check(prefs.joystick_x <= .45 and prefs.joystick_y >= .50,
		"moved controls remain within safe zone")
	check(Walk.is_blocked(2,Vector2(245,-120)),
		"Kapre tree trunk is solid")
	check(Walk.is_blocked(4,Vector2(75,-260)),
		"wake-house is solid")
	check(Walk.is_blocked(5,Vector2(165,-200)),
		"abandoned barn is solid")
	check(Walk.is_blocked(7,Vector2(530,-260)),
		"ancient balete trunk is solid")
	check(not Walk.is_blocked(5,Vector2(135,295))
		and not Walk.is_blocked(7,Vector2(210,220)),
		"necessary observation and trial destinations remain accessible")
	var prevented := Walk.slide(2,Vector2(100,-120),Vector2(350,-120))
	check(prevented.x < 180,"swept movement blocks crossing the mango")
	var native := Node3D.new()
	root.add_child(native)
	Lola.build(native)
	check(native.get_node_or_null("LolaHutInterior/Hut exit safety gate collision") is StaticBody3D,
		"door requires interaction rather than a walk-through gap")
	check(native.get_node_or_null("LolaHutInterior/Right woven wall collision") is StaticBody3D,
		"cutaway room has physical perimeter")
	native.queue_free()
	layer.queue_free()
	print("Movable joystick, solid world and Lola interior: ",
		"PASS" if failures == 0 else "%d failures" % failures)
	quit(0 if failures == 0 else 1)
