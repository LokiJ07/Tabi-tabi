extends SceneTree
## Real reported Night 3 bridge collision, Android two-finger joystick and
## identity/animation regressions across the playable connected game.
const Walk = preload("res://scripts/world/shared_walkability_2d.gd")
const Prefs = preload("res://scripts/core/preferences.gd")
const HUD = preload("res://scripts/ui/shared_hud.gd")
const Depth = preload("res://scripts/visuals/layered_25d.gd")
const Cues = preload("res://scripts/ui/world_interaction_cues.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("Bridges, touch and living actor regression: " + message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(Walk.NIGHT3_BRIDGES.size() == 4,
		"all four painted ridge paths share walkable physics geometry")
	for n in range(Walk.NIGHT3_BRIDGES.size()):
		var path: PackedVector2Array = Walk.NIGHT3_BRIDGES[n]
		check(path.size() >= 4,"crossing %d has complete visible endpoints" % n)
		for i in range(path.size()-1):
			var a: Vector2 = path[i]
			var b: Vector2 = path[i+1]
			var tangent := (b-a).normalized()
			var sideways := Vector2(-tangent.y,tangent.x)
			for step in range(13):
				var foot := a.lerp(b,float(step)/12.0)
				check(not Walk.river_blocked(3,foot),
					"bridge %d segment %d center blocked at %s" % [n,i,str(foot)])
				for side in [-1.0,1.0]:
					var steering: Vector2 = foot+sideways*(14.0*float(side))
					if Geometry2D.is_point_in_polygon(steering,Walk.NIGHT3_RAVINE):
						check(not Walk.river_blocked(3,steering),
							"bridge %d must allow thumb-steering room" % n)
	check(Walk.river_blocked(3,Vector2(0,430))
		and Walk.river_blocked(3,Vector2(-60,580)),
		"deep floodwater remains impassable away from real bridges")
	var map_src := FileAccess.get_file_as_string("res://scripts/night03_main.gd")
	check(map_src.contains("_paint_ravine_bridge(Walkability.NIGHT3_BRIDGES[0]")
		and map_src.contains("_path(Walkability.NIGHT3_BRIDGES[0]"),
		"timber rail and path rendering use exact same collision centerline")
	check(map_src.contains("_paint_ravine_bridge(Walkability.NIGHT3_BRIDGES[3]"),
		"lower stone causeway cannot silently lack visible crossing geometry")

	var prefs := Prefs.new()
	var panel := Control.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var received := {"axis":Vector2.ZERO}
	var joystick := HUD.create_movement_joystick(panel,prefs,
		func(axis: Vector2): received["axis"] = axis)
	await process_frame
	var origin: Vector2 = joystick.get_global_transform_with_canvas() * \
		(joystick.CENTER+Vector2(45,0))
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.position = origin
	press.pressed = true
	joystick._input(press)
	check((received["axis"] as Vector2).x > .55,
		"first Android finger immediately drives the joystick")
	var other := InputEventScreenTouch.new()
	other.index = 8
	other.pressed = true
	other.position = origin+Vector2(250,0)
	joystick._input(other)
	check(joystick.active_touch == 7,
		"second finger remains available to press INTERACT or FOCUS")
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = origin+Vector2(350,0)
	joystick._input(drag)
	check((received["axis"] as Vector2).x > .95,
		"joystick continues movement when thumb drags outside its rect")
	var release := InputEventScreenTouch.new()
	release.index = 7
	release.pressed = false
	release.position = drag.position
	joystick._input(release)
	check(received["axis"] == Vector2.ZERO and joystick.active_touch == -1,
		"finger release anywhere resets movement and active pointer")
	var button := HUD.make_gameplay_button(panel,"INTERACT",Vector2(1050,520),
		Vector2(180,60),func(): pass,func(): pass)
	check(button.action_mode == BaseButton.ACTION_MODE_BUTTON_PRESS
		and button.keep_pressed_outside,
		"shared Android action buttons register immediately and keep a held pointer")
	panel.queue_free()

	check(Depth.STYLE_ID == "shared-2.5d-layered-v1"
		and Cues.STYLE_ID == "seven-night-identity-cues-v1",
		"all chapters still share the exact art and indicator grammars")
	var depth_src := FileAccess.get_file_as_string("res://scripts/visuals/layered_25d.gd")
	check(depth_src.contains("two independent lower-body slices")
		or depth_src.contains("Two independent lower-body slices"),
		"walking is articulated rather than one rigid up-down cutout")
	for night in range(2,8):
		var content := FileAccess.get_file_as_string(
			"res://scripts/night%02d_main.gd" % night)
		check(content.contains("const Cues = preload")
			and content.contains("_paint_world_identities()")
			and content.contains("Cues.paint_nearby("),
			"Night %d marks active objects and NPC identities in world coordinates" % night)
	print("Night 3 bridges, seven-night touch/cues and actor locomotion: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
