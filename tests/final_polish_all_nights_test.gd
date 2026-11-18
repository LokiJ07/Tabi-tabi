extends SceneTree
## Strict presentation regression for the canonical Night 1 HUD grammar,
## all-night grounded gait, distinct postgame NPCs and the Balete camera.
const HUD = preload("res://scripts/ui/shared_hud.gd")
const Aim = preload("res://scripts/ui/aim_pad.gd")
const Actors = preload("res://scripts/world/postgame_residents.gd")
const World = preload("res://scripts/core/connected_world.gd")
const Night07 = preload("res://scenes/night07.tscn")
const Night07Save = preload("res://scripts/core/night07_save.gd")

var failures := 0

func check(yes: bool, name: String) -> void:
	if not yes:
		failures += 1
		printerr("Seven-night art + HUD polish: " + name)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var saved: Dictionary = {}
	for path in [World.PATH,World.PATH+".bak",World.PATH+".tmp",
		Night07Save.PATH,Night07Save.PATH+".bak",Night07Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			saved[path] = FileAccess.get_file_as_bytes(path)
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var hud_parent := Control.new()
	hud_parent.name = "HUDPolishProbe"
	hud_parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(hud_parent)
	var released := false
	var observed := false
	var focus := HUD.make_gameplay_button(hud_parent,"HOLD OBSERVE",Vector2(1050,490),
		Vector2(180,60),func(): observed=true,func(): released=true)
	check(focus.get_meta("hud_component","") == "night1-shared",
		"same authorized seven-night HUD component")
	check(focus.anchor_left == 1.0 and focus.offset_left == -230.0
		and focus.offset_top == -230.0 and focus.size.x == 180.0,
		"press state must not move or shrink original right-hand touch target")
	check(focus.text == "HOLD OBSERVE" and not focus.get_meta("hold_visual_active",true),
		"hold action defaults to visible inactive state")
	focus.button_down.emit()
	check(observed and focus.text == HUD.HOLD_LABEL
		and focus.get_meta("hold_visual_active",false),
		"actual press visibly displays OBSERVING")
	focus.button_up.emit()
	check(released and focus.text == "HOLD OBSERVE"
		and not focus.get_meta("hold_visual_active",true),
		"releasing a hold returns original text and state")
	focus.button_down.emit()
	hud_parent.hide()
	await process_frame
	check(not focus.get_meta("hold_visual_active",true)
		and focus.text == "HOLD OBSERVE",
		"opening a modal cannot leave stale held UI painted behind it")
	hud_parent.show()
	var aim := Aim.new()
	hud_parent.add_child(aim)
	aim.size = Vector2(175,165)
	var last_direction := Vector2(5,5)
	aim.aim_changed.connect(func(v: Vector2): last_direction=v)
	aim._send_aim(Vector2(160,80))
	check(last_direction.x > .3 and aim.thumb.length() > .2,
		"LOOK pad thumb follows actual input position")
	aim._send_aim(Vector2(87.5,82.5))
	check(last_direction == Vector2.ZERO and aim.thumb == Vector2.ZERO,
		"LOOK pad deadzone sends neutral aim, preventing stale flashlight direction")
	var portraits := [
		Actors._sprite_for("school","school_helper"),
		Actors._sprite_for("community","archive_helper"),
		Actors._sprite_for("farm","farm_helper"),
		Actors._sprite_for("repair","river_repairer")
	]
	var distinct: Dictionary = {}
	for portrait in portraits:
		check(portrait != null and portrait.get_width() >= 320,
			"new postgame resident SVG imports into Godot at source resolution")
		if portrait != null:
			distinct[portrait.resource_path] = true
	check(distinct.size() == 4,
		"school, archive, farm and repair use independent illustrated identities")
	for scene_path in [
		"res://scripts/night02_main.gd","res://scripts/night03_main.gd",
		"res://scripts/night04_main.gd","res://scripts/night05_main.gd",
		"res://scripts/night06_main.gd","res://scripts/night07_main.gd"
	]:
		check(FileAccess.get_file_as_string(scene_path).contains("paint_animated_actor("),
			"all 2.5D regions use one true shared grounded movement painter: "+scene_path)
	hud_parent.queue_free()
	var chapter := Night07.instantiate()
	root.add_child(chapter)
	await process_frame
	if chapter.dialogue.visible:
		chapter._choice("close")
	chapter.player_pos = chapter.VERDICT
	chapter.camera.position = chapter.player_pos
	chapter._process(0.35)
	check(chapter.camera.zoom.x < .99 and chapter.camera.position.y < chapter.player_pos.y - 10.0,
		"Night 7 world camera frames Balete canopy while still keeping character in view")
	check(chapter.controls.get_node_or_null("QuestStatusCard") is PanelContainer,
		"Balete camera changes do not replace original Night 1 HUD status card")
	chapter.queue_free()
	await process_frame
	for path in [World.PATH,World.PATH+".bak",World.PATH+".tmp",
		Night07Save.PATH,Night07Save.PATH+".bak",Night07Save.PATH+".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for path in saved:
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file != null:
			file.store_buffer(saved[path])
			file.close()
	print("Seven-night art + animation + HUD polish: ",
		"PASS" if failures == 0 else str(failures)+" failures")
	quit(0 if failures == 0 else 1)
